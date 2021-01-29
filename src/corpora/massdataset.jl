module MASSDATASET

import ..SIL
import ..UNK
import ..isspeechunit

using Dates
using StringEncodings

const URL = "https://github.com/getalp/mass-dataset"
const LOCALDIR = "local"

const LANG = Dict(
    "basque" => "eu",
    "finnish" => "fi",
    "english" => "en",
    "spanish" => "es",
    "french" => "fr",
    "hungarian" => "hu",
    "romanian" => "ro",
    "russian" => "ru"
)

uttid(fname) = splitext(basename(fname))[1]

function printali(f_ali, textgrid)
    open(textgrid, "r") do f
        print(f_ali, uttid(textgrid), " ")

        isprocessing = false
        for line in eachline(f)
            if line == "\"MAU\""
                isprocessing = true
                readline(f); readline(f); readline(f) # skip 3 lines
                continue
            end
            isprocessing || continue

            s = Int(floor(100*parse(Float64, line)))
            e = Int(floor(100*parse(Float64, readline(f))))
            label = readline(f)[2:end-1]
            label = label == "" ? "<sil>" : label
            count = e - s
            print(f_ali, join([label for i in 1:count], " "), " ")
        end
    end
end

function getlabels(textgrid, class)
    labels = open(textgrid, "r") do f
        labels = []
        isprocessing = false
        for line in eachline(f)
            if line == class
                isprocessing = true
                readline(f); readline(f); readline(f);
                continue
            end

            isprocessing || continue

            if line == "\"IntervalTier\"" break end

            # skip timing
            readline(f)
            label = readline(f)
            label = replace(label, "\"" =>  "")
            if label != "" push!(labels, label) end
        end
        labels
    end
end

function prepare(datadir, audiodir, lang)
    if lang ∉ keys(LANG)
        @error "$lang is not available"
        return
    end

    mkpath(joinpath(datadir, LOCALDIR))

    ###################################################################
    # Download the github directory
    repopath = joinpath(datadir, LOCALDIR, "mass-dataset-github")
    if ! ispath(repopath)
        @info "Downloading the data, this may take a while..."
        run(`git clone $URL $repopath`)
    else
        @info "Data aleady downloaded."
    end

    ###################################################################
    # Convert MP3 files to 16kHz WAV files
    wavdir = mkpath(joinpath(datadir, LOCALDIR, lang, "wavs"))
    if ! ispath(joinpath(wavdir, ".done"))
        @info "creating 16kHz WAV files."
        for fname_ext in readdir(audiodir)
            fname, _ = splitext(fname_ext)
            inpath = joinpath(audiodir, fname_ext)
            outpath = joinpath(wavdir, "$(fname)_one_channel.wav")
            run(pipeline(`lame --decode $inpath -`, `sox --ignore-length - -r 16k $outpath channels 1`))
        end

        open(joinpath(wavdir, ".done"), "w") do f
            print(f, now())
        end
    else
        @info "WAV files already created."
    end

    ###################################################################
    # split the data in verse
    versedir = mkpath(joinpath(datadir, LOCALDIR, lang, "verses"))
    if ! ispath(joinpath(versedir, ".done"))
        @info "Splitting chapters into verses."
        script = joinpath(repopath, "scripts", "alignment", "coupe_verset.py")
        raw_text = joinpath(repopath, "dataset", lang, "raw_txt")
        textgrid = joinpath(repopath, "dataset", lang, "maus_textgrid")
        code = LANG[lang]
        run(`python3 $script --lab $raw_text --textgrid $textgrid --wav $wavdir --language $(LANG[lang]) --output $versedir --force`)

        open(joinpath(versedir, ".done"), "w") do f
            print(f, now())
        end
    else
        @info "Chapters already splitted into verses."
    end

    ###################################################################
    # Generating time alignments file

    outdir = mkpath(joinpath(datadir, lang, "full"))
    langdir = mkpath(joinpath(datadir, lang, "lang"))

    @info "Generating time alignments file."
    open(joinpath(outdir, "ali"), "w") do f
        for fname in readdir(versedir)
            if endswith(fname, ".TextGrid")
                printali(f, joinpath(versedir, fname))
                println(f)
            end
        end
    end

    ###################################################################
    # Generate word transcription

    @info "Generating word transcription."

    open(joinpath(outdir, "trans.wrd"), "w") do f
        for fname in readdir(versedir)
            if endswith(fname, ".TextGrid")
                id = uttid(fname)
                u_words = getlabels(joinpath(abspath(versedir), fname), "\"ORT\"")
                println(f, id, " ", join(u_words, " "))
            end
        end
    end

    ###################################################################
    # Generating wav.scp

    @info "Generating wav.scp file."
    open(joinpath(outdir, "wav.scp"), "w") do f
        for fname in readdir(versedir)
            if endswith(fname, ".TextGrid")
                id = uttid(fname)
                wav = joinpath(abspath(versedir), "$(id)_one_channel.wav")
                println(f, id, " ", wav)
            end
        end
    end

    ###################################################################
    # Generating uttids/speakers

    @info "Generating uttids file."
    open(joinpath(outdir, "uttids"), "w") do f
        for fname in readdir(versedir)
            if endswith(fname, ".TextGrid")
                id = uttid(fname)
                println(f, id)
            end
        end
    end

    @info "Generating speakers file."
    open(joinpath(outdir, "speakers"), "w") do f
        for fname in readdir(versedir)
            if endswith(fname, ".TextGrid")
                id = uttid(fname)
                println(f, id)
            end
        end
    end

    ###################################################################
    # Generating speaker id map
    # Since we don't have speaker labels we assume each utterance
    # to have a unique speaker.

    @info "Generating uttids_speakers file."
    open(joinpath(outdir, "uttids_speakers"), "w") do f
        for fname in readdir(versedir)
            if endswith(fname, ".TextGrid")
                id = uttid(fname)
                println(f, id, " ", id)
            end
        end
    end

    ###################################################################
    # Generate the lexicon

    @info "Creating the lexicon."
    words = Dict()

    for fname in readdir(versedir)
        if endswith(fname, ".TextGrid")
            u_words = getlabels(joinpath(abspath(versedir), fname), "\"ORT\"")
            u_pronuns = getlabels(joinpath(abspath(versedir), fname), "\"KAN\"")

            for (w, p) in zip(u_words, u_pronuns)
                w_pronuns = get(words, w, Set())
                push!(w_pronuns, split(p))
                words[w] = w_pronuns
            end
        end
    end

    words[SIL] = [[SIL]]
    words[UNK] = [[UNK]]

    phones = Set([SIL, UNK])
    open(joinpath(langdir, "lexicon"), "w") do f
        for word in sort(collect(keys(words)))
            for pronun in words[word]
                push!(phones, pronun...)
                println(f, word, " ", join(pronun, " "))
            end
        end
    end

    ###################################################################
    # Generate the dictionary
    @info "Generating the dictionary."

    open(joinpath(langdir, "words"), "w") do f
        for word in sort(collect(keys(words)))
            println(f, word)
        end
    end

    ###################################################################
    # Generate the phone set
    @info "Generating the phone set."

    open(joinpath(langdir, "phones"), "w") do f
        for p in sort(collect(phones))
            println(f, p, " ", isspeechunit(p) ? "speech-unit" : "non-speech-unit")
        end
    end

end

end # module


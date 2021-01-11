module MBOSHI

using Dates
using StringEncodings

const URL = "https://github.com/besacier/mboshi-french-parallel-corpus.git"
const LOCALDIR = "local"
const SIL = "<sil>"
const UNK = "<unk>"

function filter_word(w)
    if w == "</s>"
        return SIL
    elseif w == "<UNK>"
        return UNK
    elseif w == "[silence]"
        return SIL
    else
        return w
    end
end

function filter_pronun(p)
    if p == "."
        return [SIL]
    elseif p == "!!"
        return [UNK]
    else
        return ["$c" for c in p]
    end
end

function filter_phone(p)
    if p == '!' return UNK end
    if p == '.' return SIL end
    p
end

isspeechunit(u) = u != SIL && u != UNK

function prepare(datadir; force = false)
    mkpath(joinpath(datadir, LOCALDIR))

    ###################################################################
    # Download the github directory
    repopath = joinpath(datadir, LOCALDIR, "mboshi-github")
    if ! ispath(repopath)
        @info "Downloading the data, this may take a while..."
        run(`git clone $URL $repopath`)
    else
        @info "Data aleady downloaded"
    end

    ###################################################################
    # Get the list of WAV files
    allwavdir = joinpath(repopath, "full_corpus_newsplit", "all")
    allwavs = filter(x -> endswith(x, "wav"), readdir(allwavdir))

    ###################################################################
    # Some WAV files have incorrect time stamp. In this step we create
    # a new "fixed" set of WAV files. This step needs `sox` installed.
    fixedwavdir = mkpath(joinpath(datadir, LOCALDIR, "fixed_wavs"))
    if ! ispath(joinpath(fixedwavdir, ".done"))
        @info "Fixing the time stamp of the WAV files"
        for fname in allwavs
            inpath = joinpath(allwavdir, fname)
            outpath = joinpath(fixedwavdir, fname)
            run(`sox --ignore-length $inpath $outpath`)
        end

        open(joinpath(fixedwavdir, ".done"), "w") do f println(f, today()) end
    else
        @info "WAV files time stamp already fixed"
    end

    ###################################################################
    # Extract the forced alignments of the data + lexicon
    lexicon = Set()
    phones = Set()
    alifile = joinpath(repopath, "forced_alignments_supervised_spkr",
                       "limsi-align", "trn0.seg")
    full_ali_file = joinpath(datadir, LOCALDIR, "full_ali")
    open(full_ali_file, "w") do f_ali
        open(alifile, enc"latin1", "r") do f
            uttid = ""
            phn_stack = []
            for line in eachline(f)
                if startswith(line, "#@ sid")
                    if uttid ≠ "" println(f_ali) end
                    uttid = split(split(line, "=")[2], ".")[1]
                    print(f_ali, uttid)
                elseif startswith(line, "#@ word")
                    tokens = split(line)
                    phn_stack = [c for c in tokens[4]]
                    word = filter_word(split(tokens[2], "=")[2])
                    pronun = filter_pronun(tokens[4])
                    push!(phones, pronun...)
                    push!(lexicon, (word, pronun))
                elseif ! startswith(line, "#")
                    label = filter_phone(popfirst!(phn_stack))
                    tokens = split(line)
                    s1, s2, s3 = tokens[5:7]
                    duration = parse(Int, s1) + parse(Int, s2) + parse(Int, s3)
                    for i in 1:duration
                        print(f_ali, " ", label)
                    end
                end
            end
        end
    end

    full_ali = Dict()
    open(full_ali_file, "r") do f
        for line in eachline(f)
            tokens = split(line)
            uttid = tokens[1]
            ali = join(tokens[2:end], " ")
            full_ali[uttid] = ali
        end
    end

    ###################################################################
    # Prepare each set

    for set in ["dev", "train"]
        @info "Preparing $set set..."

        setdir = mkpath(joinpath(datadir, set))

        wavdir = joinpath(repopath, "full_corpus_newsplit", set)
        wavs = filter(x -> endswith(x, "wav"), readdir(wavdir))

        # Extract uttids and speakers labels
        uttids = []
        speakers = Set{String}()
        utt2spk = Dict()
        utt2wav = Dict()
        for fname in wavs
            tokens = split(replace(fname, ".wav" => ""), "_")
            speaker = tokens[1]
            uttid = join(tokens[2:end], "_")
            push!(uttids, uttid)
            push!(speakers, speaker)
            utt2spk[uttid] = speaker
            utt2wav[uttid] = abspath(fname)
        end

        uttids = sort(uttids)
        speakers = sort([s for s in speakers])

        # uttids
        open(joinpath(setdir, "uttids"), "w") do f
            for uttid in uttids println(f, uttid) end
        end

        # wav.scp
        open(joinpath(setdir, "wav.scp"), "w") do f
            for uttid in uttids println(f, uttid, " ", utt2wav[uttid]) end
        end

        # uttids_speakers
        open(joinpath(setdir, "uttids_speakers"), "w") do f
            for uttid in uttids println(f, uttid, " ", utt2spk[uttid]) end
        end

        # speakers
        open(joinpath(setdir, "speakers"), "w") do f
            for s in speakers println(f, s) end
        end

        # ali
        open(joinpath(setdir, "ali"), "w") do f
            for uttid in uttids println(f, uttid, " ", full_ali[uttid]) end
        end

        # trans.wrd
        open(joinpath(setdir, "trans.wrd"), "w") do f
            for uttid in uttids
                speaker = utt2spk[uttid]
                fname = "$(join([speaker, uttid], "_")).mb.cleaned"
                open(joinpath(wavdir, fname), "r") do f2
                    println(f, uttid, " ", readline(f2))
                end
            end
        end

    end

    ###################################################################
    # Prepare the dictionary and the lexicon
    langdir = mkpath(joinpath(datadir, "lang"))

    words = Set()
    for (w, p) in lexicon push!(words, w) end
    open(joinpath(langdir, "words"), "w") do f
        for w in sort([w for w in words])
            println(f, w)
        end
    end

    open(joinpath(langdir, "phones"), "w") do f
        for p in sort([p for p in phones])
            type = isspeechunit(p) ? "speech-unit" : "non-speech-unit"
            println(f, p, " ", type)
        end
    end

    lex_entries = []
    for (w,p) in lexicon
        push!(lex_entries, "$w $(join(p, " "))")
    end

    open(joinpath(langdir, "lexicon"), "w") do f
        for p in sort([p for p in lex_entries])
            println(f, p)
        end
    end
end

end # module


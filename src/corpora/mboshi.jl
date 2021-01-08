module MBOSHI

using Dates
using StringEncodings

const URL = "https://github.com/besacier/mboshi-french-parallel-corpus.git"
const LOCALDIR = "local"

function filter_word(w)
    if w == "</s>"
        return "<sil>"
    elseif w == "<UNK>"
        return "<unk>"
    elseif w == "[silence]"
        return "<sil>"
    else
        return w
    end
end

function filter_pronun(p)
    if p == "."
        return ["<sil>"]
    elseif p == "!!"
        return ["<unk>"]
    else
        return ["$c" for c in p]
    end
end

function filter_phone(p)
    if p == '!' return "<sil>"  end
    if p == '.' return "<sil>" end
    p
end

isspeechunit(u) = u != "<sil>" && u != "<unk>"

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
    # Prepare each set

    utt2spk = Dict()
    lexicon = Set()
    phones = Set()
    for set in ["dev", "train"]
        @info "Preparing $set set..."

        setdir = mkpath(joinpath(datadir, set))

        wavdir = joinpath(repopath, "full_corpus_newsplit", set)
        wavs = filter(x -> endswith(x, "wav"), readdir(wavdir))
        uttids = map(x -> replace(x, ".wav" => ""), wavs)

        # uttids
        open(joinpath(setdir, "uttids"), "w") do f
            for uttid in uttids println(f, uttid) end
        end

        # wav.scp
        open(joinpath(setdir, "wav.scp"), "w") do f
            for (uttid, wav) in zip(uttids, wavs)
                println(f, "$uttid $(abspath(wav))")
            end
        end

        # uttids_speakers
        speakers = Set{String}()
        open(joinpath(setdir, "uttids_speakers"), "w") do f
            for uttid in uttids
                tokens = split(uttid, "_")
                push!(speakers, tokens[1])
                utt2spk[join(split(uttid, "_")[2:end], "_")] = tokens[1]
                println(f, uttid, " ", tokens[1])
            end
        end
        open(joinpath(setdir, "speakers"), "w") do f
            for s in speakers
                println(f, s)
            end
        end

        # trans.wrd
        open(joinpath(setdir, "trans.wrd"), "w") do f
            for uttid in uttids
                open(joinpath(wavdir, "$(uttid).mb.cleaned"), "r") do f2
                    println(f, uttid, " ", readline(f2))
                end
            end
        end

        ###############################################################
        # Extract words / phones for the lexicon
        name = set == "train" ? "trn0.seg" : "dev0.seg"
        alifile = joinpath(repopath, "forced_alignments_supervised_spkr",
                           "limsi-align", name)
        open(alifile, "r") do f
            for line in eachline(f)
                if startswith(line, "#@ word")
                    tokens = split(line)
                    word = filter_word(split(tokens[2], "=")[2])
                    pronun = filter_pronun(tokens[4])
                    push!(phones, pronun...)
                    push!(lexicon, (word, pronun))
                end
            end
        end

        open(alifile, "r") do f
            for line in eachline(f)
                if startswith(line, "#@ word")
                    tokens = split(line)
                    word = filter_word(split(tokens[2], "=")[2])
                    pronun = filter_pronun(tokens[4])
                    push!(phones, pronun...)
                    push!(lexicon, (word, pronun))
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


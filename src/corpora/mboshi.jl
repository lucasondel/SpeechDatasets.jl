module MBOSHI

import ..LOCATIONS
import ..LABELS
import ..NON_SPEECH_UNITS

using StringEncodings

const URL = "https://github.com/besacier/mboshi-french-parallel-corpus.git"

function filter_word(w)
    if w == "</s>"
        return LABELS[:sil]
    elseif w == "<UNK>"
        return LABELS[:unk]
    elseif w == "[silence]"
        return LABELS[:sil]
    else
        return w
    end
end

function filter_pronun(p)
    if p == "."
        return [LABELS[:sil]]
    elseif p == "!!"
        return [LABELS[:unk]]
    else
        return ["$c" for c in p]
    end
end

function filter_phone(p)
    if p == '!' return LABELS[:unk] end
    if p == '.' return LABELS[:sil] end
    p
end

function prepare(datadir)
    mkpath(joinpath(datadir, LOCATIONS[:local]))

    # Download the github directory
    repopath = joinpath(datadir, LOCATIONS[:local], "mboshi-github")
    if ! ispath(repopath)
        @info "Downloading the data, this may take a while..."
        run(`git clone $URL $repopath`)
    else
        @info "Data aleady downloaded"
    end

    # Get the list of WAV files
    allwavdir = joinpath(repopath, "full_corpus_newsplit", "all")
    allwavs = filter(x -> endswith(x, "wav"), readdir(allwavdir))

    # Some WAV files have incorrect time stamp. In this step we create
    # a new "fixed" set of WAV files. This step needs `sox` installed.
    fixedwavdir = mkpath(joinpath(datadir, LOCATIONS[:local], "fixed_wavs"))
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

    # Extract the forced alignments of the data + lexicon
    lexicon = Set()
    phones = Set()
    alifile = joinpath(repopath, "forced_alignments_supervised_spkr",
                       "limsi-align", "trn0.seg")
    full_ali_file = joinpath(datadir, LOCATIONS[:local], "full_ali")
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
            utt2wav[uttid] = abspath(joinpath(fixedwavdir, fname))
        end

        uttids = sort(uttids)
        speakers = sort([s for s in speakers])

        # uttids
        open(joinpath(setdir, LOCATIONS[:uttids]), "w") do f
            for uttid in uttids println(f, uttid) end
        end

        # wav.scp
        open(joinpath(setdir, LOCATIONS[:wavs]), "w") do f
            for uttid in uttids println(f, uttid, "\t", utt2wav[uttid]) end
        end

        # uttids_speakers
        open(joinpath(setdir, LOCATIONS[:utt2spk]), "w") do f
            for uttid in uttids println(f, uttid, "\t", utt2spk[uttid]) end
        end

        # speakers
        open(joinpath(setdir, LOCATIONS[:speakers]), "w") do f
            for s in speakers println(f, s) end
        end

        # ali
        open(joinpath(setdir, LOCATIONS[:ali]), "w") do f
            for uttid in uttids println(f, uttid, "\t", full_ali[uttid]) end
        end

        # trans.wrd
        open(joinpath(setdir, LOCATIONS[:trans] * ".wrd"), "w") do f
            for uttid in uttids
                speaker = utt2spk[uttid]
                fname = "$(join([speaker, uttid], "_")).mb.cleaned"
                open(joinpath(wavdir, fname), "r") do f2
                    println(f, uttid, "\t", readline(f2))
                end
            end
        end

        # trans.wrd
        open(joinpath(setdir, LOCATIONS[:trans] * ".wrd.fr"), "w") do f
            for uttid in uttids
                speaker = utt2spk[uttid]
                fname = "$(join([speaker, uttid], "_")).fr.cleaned.noPunct"
                open(joinpath(wavdir, fname), "r") do f2
                    println(f, uttid, "\t", readline(f2))
                end
            end
        end
    end

    ###################################################################
    # Create the full split
    #
    fulldir = mkpath(joinpath(datadir, "full"))

    tgts = [LOCATIONS[:ali], LOCATIONS[:speakers], LOCATIONS[:trans]*".wrd",
            LOCATIONS[:trans]*".wrd.fr", LOCATIONS[:uttids],
            LOCATIONS[:uttids], LOCATIONS[:utt2spk], LOCATIONS[:wavs]]
    for fname in tgts
        traindir = mkpath(joinpath(datadir, "train"))
        devdir = mkpath(joinpath(datadir, "dev"))
        open(joinpath(fulldir, fname), "w") do f
            run(pipeline(pipeline(`cat $(traindir)/$(fname) $(devdir)/$(fname)`, `sort`, `uniq`), stdout=f))
        end
    end


    ###################################################################
    # Prepare the dictionary and the lexicon
    langdir = mkpath(joinpath(datadir, LOCATIONS[:lang]))

    words = Set()
    for (w, p) in lexicon push!(words, w) end
    open(joinpath(langdir, LOCATIONS[:words]), "w") do f
        for w in sort([w for w in words])
            println(f, w)
        end
    end

    isspeechunit(u) = u ∉ NON_SPEECH_UNITS
    open(joinpath(langdir, LOCATIONS[:units]), "w") do f
        for p in sort([p for p in phones])
            type = isspeechunit(p) ? LABELS[:speechunit] : LABELS[:nonspeeechunit]
            println(f, p, "\t", type)
        end
    end

    lex_entries = []
    for (w,p) in lexicon
        push!(lex_entries, "$w\t$(join(p, " "))")
    end

    open(joinpath(langdir, LOCATIONS[:lexicon]), "w") do f
        for p in sort([p for p in lex_entries])
            println(f, p)
        end
    end
end

end # module

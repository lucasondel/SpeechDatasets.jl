module BABEL

import ..LABELS
import ..LOCATIONS

using Glob

function parse_transcription(trans)
    uttidprefix = splitext(basename(trans))[1]
    segments = []
    state = :start_time
    start_t = 0
    end_t = 0
    label = ""
    open(trans, "r") do f
        for line in eachline(f)
            if state == :start_time
                start_t = parse(Float64, line[2:end-1])
                state = :label
            elseif state == :label
                label = replace(line, "(())" => LABELS[:unk])
                label = replace(label, "~" => "")
                label = replace(label, "<no-speech>" => LABELS[:sil])
                state = :end_time
            else
                end_t = parse(Float64, line[2:end-1])
                uttid = uttidprefix*"__$(start_t)_$(end_t)"
                push!(segments, (uttid, start_t, end_t, label))
                start_t = end_t
                state = :label
            end
        end
    end
    segments
end

function prepare(datadir, rootdir, subdirs = ["training", "dev"])

    nonspeechunits = Set()
    for dirname in subdirs
        dir = mkpath(joinpath(datadir, dirname == "training" ? "train" : dirname))
        @info "preparing $dir"

        segments = []
        for trans in glob("*txt", joinpath(rootdir, dirname, "transcription"))
            push!(segments, parse_transcription(trans)...)
        end

        # wav.scp
        uttids = Set()
        audiodir = joinpath(rootdir, dirname, "audio")
        scp = joinpath(dir, LOCATIONS[:wavs])
        open(scp, "w") do f
            for segment in segments
                uttid, start_t, end_t, _ = segment
                push!(uttids, uttid)
                trunc_uttid = split(uttid, "__")[1]
                println(f, "$uttid\tsph2pipe -t $(start_t):$(end_t) -f wav $(joinpath(audiodir, "$(trunc_uttid).sph")) |")
            end
        end

        # uttids
        open(joinpath(dir, LOCATIONS[:uttids]), "w") do f
            for uttid in sort(collect(uttids))
                println(f, uttid)
            end
        end

        # uttids_speakers
        uttids_spk = joinpath(dir, LOCATIONS[:utt2spk])
        spks = Set()
        open(uttids_spk, "w") do f
            for uttid in sort(collect(uttids))
                spk = split(uttid, "__")[1]
                push!(spks, spk)
                println(f, "$uttid\t$uttid $spk")
            end
        end

        # speakers
        spkfile = joinpath(dir, LOCATIONS[:speakers])
        open(spkfile, "w") do f
            for trans in glob("*txt", joinpath(rootdir, dirname, "transcription"))
                for spk in sort(collect(spks)) println(f, spk) end
            end
        end

        # trans.wrd
        open(joinpath(dir, LOCATIONS[:trans]*".wrd"), "w") do f
            for segment in segments
                uttid, _, _, text = segment
                ns_tokens = filter(t -> startswith(t, "<"), split(text))
                if ! isempty(ns_tokens) push!(nonspeechunits, ns_tokens...) end
                println(f, "$uttid\t$text")
            end
        end
    end

    langdir = mkpath(joinpath(datadir, "lang"))
    @info "preparing $langdir"

    phones = Set()
    open(joinpath(langdir, "lexicon"), "w") do fl
        open(joinpath(rootdir, "reference_materials", "lexicon.txt"), "r") do f
            for line in eachline(f)
                fields = split(line, "\t")
                word = fields[1]
                for field in fields[3:end]
                    print(fl, word, "\t")
                    for syllable in split(field, ".")
                        tokens = split(syllable)
                        suffix = startswith(tokens[end], "_") ? tokens[end] : ""
                        if suffix == ""
                            for token in tokens
                                push!(phones, token)
                                print(fl, token, " ")
                            end
                        else
                            for token in tokens[1:end-1]
                                newtoken = token*suffix
                                push!(phones, newtoken)
                                print(fl, newtoken, " ")
                            end
                        end
                    end
                    println(fl)
                end
            end
        end
    end

    open(joinpath(langdir, "units"), "w") do f
        for unit in nonspeechunits println(f, "$unit\tnon-speech-unit") end
        for phone in phones println(f, "$phone\tspeech-unit") end
    end

    return nothing
end

end

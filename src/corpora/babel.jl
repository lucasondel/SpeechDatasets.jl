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
        dir = mkpath(joinpath(datadir, dirname))
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
                println(f, "$uttid\tsph2pipe -t $(start_t):$(end_t) -f wav $(joinpath(audiodir, "$(uttid).sph")) |")
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

        # trans.char
        open(joinpath(dir, LOCATIONS[:trans]*".char"), "w") do f
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

    for dataset in ["train", "test", "dev"]
        datasetdir = mkpath(joinpath(datadir, dataset))
        @info "preparing $dataset"

        # Load the speakers
        spks = Set()
        open(joinpath(localdir, "$(dataset)_spk.list"), "r") do f
            for line in eachline(f)
                push!(spks, line)
            end
        end

        # Extract the utterance ids
        uttids = Dict()
        for path in glob("*/dr*/*", rootdir)
            spk = basename(path)
            spk in spks || continue

            for wavpath in glob("*wav", path)
                utt = splitext(basename(wavpath))[1]
                ! startswith(utt, "sa") || continue
                uttids["$(spk)_$(utt)"] = path
            end
        end

        # wav.scp
        scp = joinpath(datasetdir, LOCATIONS[:wavs])
        open(scp, "w") do f
            for (uttid, path) in uttids
                uttname = split(uttid, "_")[2]
                println(f, "$uttid\tsph2pipe -f wav $(joinpath(path, "$(uttname).wav")) |")
            end
        end

        # uttids
        uttidsfile = joinpath(datasetdir, LOCATIONS[:uttids])
        open(uttidsfile, "w") do f
            for uttid in keys(uttids) println(f, uttid) end
        end

        # uttids_speakers
        uttids_spk = joinpath(datasetdir, LOCATIONS[:utt2spk])
        open(uttids_spk, "w") do f
            for uttid in keys(uttids)
                spk = split(uttid, "_")[1]
                println(f, "$uttid\t$spk")
            end
        end

        # speakers
        spkfile = joinpath(datasetdir, LOCATIONS[:speakers])
        open(spkfile, "w") do f
            for spk in sort(collect(spks)) println(f, spk) end
        end

        # trans.phn.60
        open(joinpath(datasetdir, LOCATIONS[:trans]*".phn.60"), "w") do f
            for (uttid, path) in uttids
                print(f, uttid, "\t")
                uttname = split(uttid, "_")[2]
                open(joinpath(path, "$(uttname).phn"), "r") do f2
                    for line in eachline(f2)
                        print(f, split(line)[3], " ")
                    end
                end
                println(f)
            end
        end

        # trans.phn.48
        open(joinpath(datasetdir, LOCATIONS[:trans]*".phn.48"), "w") do f
            for (uttid, path) in uttids
                print(f, uttid, "\t")
                uttname = split(uttid, "_")[2]
                open(joinpath(path, "$(uttname).phn"), "r") do f2
                    for line in eachline(f2)
                        token = split(line)[3]
                        if token != "q"
                            print(f, map_60_48[token], " ")
                        end
                    end
                end
                println(f)
            end
        end

        # trans.phn.39
        open(joinpath(datasetdir, LOCATIONS[:trans]*".phn.39"), "w") do f
            for (uttid, path) in uttids
                print(f, uttid, " \t")
                uttname = split(uttid, "_")[2]
                open(joinpath(path, "$(uttname).phn"), "r") do f2
                    for line in eachline(f2)
                        token = split(line)[3]
                        if token != "q"
                            print(f, map_60_39[token], " ")
                        end
                    end
                end
                println(f)
            end
        end

        # ali.phn
        open(joinpath(datasetdir, LOCATIONS[:ali]*".phn.60"), "w") do f
            for (uttid, path) in uttids
                print(f, uttid, "\t")
                uttname = split(uttid, "_")[2]
                open(joinpath(path, "$(uttname).phn"), "r") do f2
                    for line in eachline(f2)
                        s, e, token = split(line)
                        s = Int(floor(parse(Int, s)/160))
                        e = Int(floor(parse(Int, e)/160))
                        print(f, strip("$token "^(e-s)), " ")
                    end
                end
                println(f)
            end
        end
    end

    # lang dir
    fn = sort ∘ collect
    for (ext, phones) in [(".60", fn(keys(map_60_48))),
                          (".48", fn(Set([map_60_48[k] for k in filter(u -> u ≠ "q", keys(map_60_48))]))),
                          (".39", fn(Set([map_60_39[k] for k in filter(u -> u ≠ "q", keys(map_60_39))])))]
        langdir = mkpath(joinpath(datadir, "lang$ext"))
        @info "preparing $langdir"

        open(joinpath(langdir, LOCATIONS[:units]), "w") do f
            for phone in phones
                println(f, phone, "\t", isspeechunit(phone) ? LABELS[:speechunit] : LABELS[:nonspeechunit])
            end
        end

        open(joinpath(langdir, LOCATIONS[:words]), "w") do f
            for phone in phones
                println(f, phone)
            end
        end

        open(joinpath(langdir, LOCATIONS[:lexicon]), "w") do f
            for phone in phones
                println(f, phone, "\t", phone)
            end
        end
    end
end

end

module TIMIT

import ..SIL
import ..UNK

using Dates
using Glob
using StringEncodings

const LOCALDIR = "local"

const URL_PHONE_MAP = "https://raw.githubusercontent.com/kaldi-asr/kaldi/master/egs/timit/s5/conf/phones.60-48-39.map"
const URL_DEV_SPKS = "https://raw.githubusercontent.com/kaldi-asr/kaldi/master/egs/timit/s5/conf/dev_spk.list"
const URL_TEST_SPKS = "https://raw.githubusercontent.com/kaldi-asr/kaldi/master/egs/timit/s5/conf/test_spk.list"

isspeechunit(u) = u ≠ SIL && u ≠ UNK && u ≠ "h#" && u ≠ "epi" && u ≠ "pau"

function filter_phone(p)
    if p == "sil" return SIL end
    p
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

function prepare(rootdir, datadir)
    localdir = mkpath(joinpath(datadir, LOCALDIR))

    # phone mapping
    if ! ispath(joinpath(localdir, "phones.60-48-39.map"))
        @info "downloading phone mapping..."
        run(`wget -P $localdir $URL_PHONE_MAP`)
    end

    # Load the the phone mapping
    map_60_48 = Dict()
    map_60_39 = Dict()
    open(joinpath(localdir, "phones.60-48-39.map"), "r") do f
        for line in eachline(f)
            tokens = split(line)
            if length(tokens) == 3
                map_60_48[tokens[1]] = filter_phone(tokens[2])
                map_60_39[tokens[1]] = filter_phone(tokens[3])
            else
                map_60_48[tokens[1]] = nothing
                map_60_39[tokens[1]] = nothing
            end

        end
    end

    # speakers (dev)
    if ! ispath(joinpath(localdir, "dev_spk.list"))
        @info "downloading dev speaker list..."
        run(`wget -P $localdir $URL_DEV_SPKS`)
    end

    # speakers (test)
    if ! ispath(joinpath(localdir, "test_spk.list"))
        @info "downloading test speaker list..."
        run(`wget -P $localdir $URL_TEST_SPKS`)
    end

    # speakers (train)
    run(pipeline(`ls -d $(glob("dr*/*", "$rootdir/train"))`, `sed -e "s:^.*/::"`,
                 joinpath(localdir, "train_spk.list")))

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
        scp = joinpath(datasetdir, "wav.scp")
        open(scp, "w") do f
            for (uttid, path) in uttids
                uttname = split(uttid, "_")[2]
                println(f, "$uttid sph2pipe -f wav $(joinpath(path, "$(uttname).wav")) |")
            end
        end

        # uttids
        uttidsfile = joinpath(datasetdir, "uttids")
        open(uttidsfile, "w") do f
            for uttid in keys(uttids) println(f, uttid) end
        end

        # uttids_speakers
        uttids_spk = joinpath(datasetdir, "uttids_speakers")
        open(uttids_spk, "w") do f
            for uttid in keys(uttids)
                spk = split(uttid, "_")[1]
                println(f, "$uttid $spk")
            end
        end

        # speakers
        spkfile = joinpath(datasetdir, "speakers")
        open(spkfile, "w") do f
            for spk in sort(collect(spks)) println(f, spk) end
        end

        # trans.phn.60
        open(joinpath(datasetdir, "trans.phn.60"), "w") do f
            for (uttid, path) in uttids
                print(f, uttid, " ")
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
        open(joinpath(datasetdir, "trans.phn.48"), "w") do f
            for (uttid, path) in uttids
                print(f, uttid, " ")
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
        open(joinpath(datasetdir, "trans.phn.39"), "w") do f
            for (uttid, path) in uttids
                print(f, uttid, " ")
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
        open(joinpath(datasetdir, "ali.phn.60"), "w") do f
            for (uttid, path) in uttids
                print(f, uttid, " ")
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

        open(joinpath(langdir, "phones"), "w") do f
            for phone in phones
                println(f, phone, " ", isspeechunit(phone) ? "speech-unit" : "non-speech-unit")
            end
        end

        open(joinpath(langdir, "words"), "w") do f
            for phone in phones
                println(f, phone)
            end
        end

        open(joinpath(langdir, "lexicon"), "w") do f
            for phone in phones
                println(f, phone, " ", phone)
            end
        end
    end

end

using .TIMIT
export TIMIT

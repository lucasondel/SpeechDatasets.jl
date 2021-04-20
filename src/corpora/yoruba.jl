module YORUBA

import ..LOCATIONS
import ..LABELS
import ..NON_SPEECH_UNITS

using Dates
using NaturalSort

const URL_FEMALE_AUDIO = "https://www.openslr.org/resources/86/yo_ng_female.zip"
const URL_FEMALE_TRANS = "https://www.openslr.org/resources/86/line_index_female.tsv"
const URL_MALE_AUDIO = "https://www.openslr.org/resources/86/yo_ng_male.zip"
const URL_MALE_TRANS = "https://www.openslr.org/resources/86/line_index_male.tsv"
const URL_ALI = "https://raw.githubusercontent.com/beer-asr/beer/master/recipes/aud/local/google_lr/ali"

function prepare(datadir)

    ###################################################################
    # Download the data

    rawdata = mkpath(joinpath(datadir, LOCATIONS[:local], "data"))
    orig_wavs_f = mkpath(joinpath(rawdata, "orig_wavs_female"))
    orig_wavs_m = mkpath(joinpath(rawdata, "orig_wavs_male"))
    if ! ispath(joinpath(rawdata, ".done"))
        @info "Dowloading the data..."
        run(`wget -P $rawdata $URL_FEMALE_AUDIO`)
        run(`wget -P $rawdata $URL_FEMALE_TRANS`)
        run(`wget -P $rawdata $URL_MALE_AUDIO`)
        run(`wget -P $rawdata $URL_MALE_TRANS`)

        run(`unzip -d $orig_wavs_f $(joinpath(rawdata, "yo_ng_female.zip"))`)

        run(`unzip -d $orig_wavs_m $(joinpath(rawdata, "yo_ng_male.zip"))`)

        open(joinpath(rawdata, ".done"), "w") do f print(f, now()) end
    else
        @info "Data already dowloaded."
    end

    ###################################################################
    # Fix the timing and down-sample to 16kHz

    wavdir = mkpath(joinpath(datadir, LOCATIONS[:local], "wavs"))

    if ! ispath(wavdir, ".done_f")
        @info "Downsampling the data (female) to 16kHz"
        for fname in readdir(orig_wavs_f)
            if endswith(fname, "wav")
                out = joinpath(wavdir, fname)
                run(`sox -G $(joinpath(orig_wavs_f, fname)) -t wav $out rate 16k`)
            end
        end
        open(joinpath(wavdir, ".done_f"), "w") do f print(f, now()) end
    else
        @info "Data (female) already downsampled to 16kHz."
    end

    if ! ispath(wavdir, ".done_m")
        @info "Downsampling the data (male) to 16kHz"
        for fname in readdir(orig_wavs_m)
            if endswith(fname, "wav")
                out = joinpath(wavdir, fname)
                run(`sox -G $(joinpath(orig_wavs_m, fname)) -t wav $out rate 16k`)
            end
        end
        open(joinpath(wavdir, ".done_m"), "w") do f print(f, now()) end
    else
        @info "Data (male) already downsampled to 16kHz."
    end

    ###################################################################
    # Prepare the full set.

    allwavs = filter(x -> endswith(x, "wav"), readdir(wavdir))

    set = "full"
    setdir = mkpath(joinpath(datadir, set))
    if ! ispath(joinpath(setdir, ".done"))
        @info "Preparing $set set..."

        uttids = []
        speakers = Set{String}()
        utt2spk = Dict()
        utt2wav = Dict()
        for fname in allwavs
            uttid = replace(fname, ".wav" => "")
            tokens = split(uttid, "_")
            speaker = tokens[2]
            push!(uttids, uttid)
            push!(speakers, speaker)
            utt2spk[uttid] = speaker
            utt2wav[uttid] = abspath(fname)
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

        alifile = joinpath(setdir, LOCATIONS[:ali])
        newalifile = joinpath(setdir, "ali_new")
        run(`rm -f $alifile $newalifile`)
        run(`wget -P $(abspath(setdir)) $URL_ALI`)
        write(newalifile, read(pipeline(`cat $alifile`, `sed s/sil/\<sil\>/g`)))
        run(`mv $newalifile $alifile`)

        # trans.wrd
        write(joinpath(rawdata, "line_index.tsv"),
              read(`cat $rawdata/line_index_male.tsv $rawdata/line_index_female.tsv`))
        cmd = pipeline(`cat $rawdata/line_index.tsv`, `sed "s/$(Char('\t'))/ /g"`)
        write(joinpath(setdir, "trans.wrd"), read(cmd))

        open(joinpath(setdir, ".done"), "w") do f print(f, now()) end
    else
        @info "$set already prepared"
    end

    ###################################################################
    # Prepare the lang directory.

    langdir = mkpath(joinpath(datadir, LOCATIONS[:lang]))
    @info "preparing $langdir..."

    phones = Set()
    open(joinpath(datadir, set, LOCATIONS[:ali]), "r") do f
        for line in eachline(f)
            tokens = split(line)
            for phone in tokens[2:end]
                push!(phones, phone)
            end
        end
    end

    open(joinpath(langdir, LOCATIONS[:units]), "w") do f
        for p in sort(collect(phones), lt = natural)
            type = p ∈ NON_SPEECH_UNITS ? LABELS[:nonspeechunit] : LABELS[:speechunit]
            println(f, p, "\t", type)
        end
    end

end

end # module

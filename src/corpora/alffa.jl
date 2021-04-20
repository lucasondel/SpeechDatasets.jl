module ALFFA

import ..SIL
import ..UNK
import ..isspeechunit

using Glob
using NaturalSort

const URL_REPO = "https://github.com/getalp/ALFFA_PUBLIC"
const LOCALDIR = "local"
const LANGUAGES = Set([:amharic, :swahili, :wolof])
const WAVPATTERN = Dict(
    :amharic => "wav/*wav",
    :swahili => "wav/*/*wav",
)
const SUBDIR = Dict(
    :amharic => joinpath("ASR", "AMHARIC"),
    :swahili=> joinpath("ASR", "SWAHILI"),
)

function prepare(datadir, lang)
    lang ∈ LANGUAGES || error("$lang is unknown, see ALFFA.LANGUAGES for supported language")

    localdir = mkpath(joinpath(datadir, LOCALDIR))

    repopath = joinpath(localdir, "alffa-github")
    if ! ispath(repopath)
        @info "downloading the data, this may take a while..."
        run(`git clone $URL_REPO $repopath`)
    else
        @info "data aleady downloaded"
    end

    for dataset in ["train", "test"]
        datasetdir = mkpath(joinpath(datadir, "$lang", dataset))
        @info "preparing $datasetdir..."

        uttids = Set()

        dir = joinpath(repopath, SUBDIR[lang], "data", dataset)
        open(joinpath(datasetdir, "wav.scp"), "w") do f

            for path in glob(WAVPATTERN[lang], dir)
                uttid = splitext(basename(path))[1]
                push!(uttids, uttid)
                println(f, uttid, " ", path)
            end
        end

        open(joinpath(datasetdir, "uttids"), "w") do f
            for uttid in sort(collect(uttids), lt=natural)
                println(f, uttid)
            end
        end

        cp(joinpath(dir, "text"), joinpath(datasetdir, "trans.wrd"), force = true)
        cp(joinpath(dir, "utt2spk"), joinpath(datasetdir, "uttids_speakers"), force = true)
    end

    langdir = mkpath(joinpath(datadir, "$lang", "lang"))
    src = joinpath(repopath, SUBDIR[lang], "lang", "lexicon.txt")
    dest = joinpath(langdir, "lexicon")
    run(pipeline(`cat $src`, `grep -v SIL`, `grep -v unk`, `grep -v UNK`, dest))

    open(dest, "a") do f
        println(f, SIL, "\t", SIL)
    end

    words = joinpath(langdir, "words")
    run(pipeline(`cut -f1 $dest`, "$words"))

    open(joinpath(langdir, "phones"), "w") do f
        println(f, SIL, " ", "non-speech-unit")
        open(joinpath(repopath, SUBDIR[lang], "lang", "nonsilence_phones.txt"), "r") do f2
            for line in eachline(f2)
                println(f, line, "\t", "speech-unit")
            end
        end
    end


    return nothing
end

end # module

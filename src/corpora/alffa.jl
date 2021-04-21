module ALFFA

import ..LABELS
import ..LOCATIONS
import ..NON_SPEECH_UNITS

using Glob
using NaturalSort

const URL_REPO = "https://github.com/getalp/ALFFA_PUBLIC"
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

    localdir = mkpath(joinpath(datadir, LOCATIONS[:local]))

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
        open(joinpath(datasetdir, LOCATIONS[:wavs]), "w") do f

            for path in glob(WAVPATTERN[lang], dir)
                uttid = splitext(basename(path))[1]
                push!(uttids, uttid)
                println(f, uttid, "\t", path)
            end
        end

        open(joinpath(datasetdir, LOCATIONS[:uttids]), "w") do f
            for uttid in sort(collect(uttids), lt=natural)
                println(f, uttid)
            end
        end

        cp(joinpath(dir, "text"), joinpath(datasetdir, LOCATIONS[:trans]*".wrd"), force = true)
        cp(joinpath(dir, "utt2spk"), joinpath(datasetdir, LOCATIONS[:utt2spk]), force = true)
    end

    langdir = mkpath(joinpath(datadir, "$lang", LOCATIONS[:lang]))
    src = joinpath(repopath, SUBDIR[lang], "lang", "lexicon.txt")
    dest = joinpath(langdir, LOCATIONS[:lexicon])
    run(pipeline(`cat $src`, `grep -v SIL`, `grep -v unk`, `grep -v UNK`, dest))

    open(dest, "a") do f
        println(f, LABELS[:sil], "\t", LABELS[:nonspeechunit])
    end

    words = joinpath(langdir, LOCATIONS[:words])
    run(pipeline(`cut -f1 $dest`, "$words"))

    open(joinpath(langdir, LOCATIONS[:units]), "w") do f
        println(f, LABELS[:sil], "\t", LABELS[:nonspeechunit])
        open(joinpath(repopath, SUBDIR[lang], "lang", "nonsilence_phones.txt"), "r") do f2
            for line in eachline(f2)
                println(f, line, "\t", LABELS[:speechunit])
            end
        end
    end


    return nothing
end

end # module

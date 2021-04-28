using Documenter

push!(LOAD_PATH, "../")
using SpeechDatasets

makedocs(
    sitename = "SpeechDatasets",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = [
        "Home" => "index.md",
        "Corpora" => Any[
            "ALFFA" => "alffa.md",
            "Babel" => "babel.md",
            "MaSS" => "massdataset.md",
            "Mboshi" => "mboshi.md",
            "TIMIT" => "timit.md",
        ]
    ]
)

deploydocs(
    repo = "github.com/lucasondel/SpeechDatasets.jl.git",
    devbranch = "main",
)


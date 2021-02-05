using Documenter

push!(LOAD_PATH, "../")
using SpeechDatasets

makedocs(
    sitename = "SpeechDatasets",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = [
        "Home" => "index.md",
        "Corpora" => Any[
            "Mboshi" => "mboshi.md",
            "Mass dataset" => "massdataset.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/lucasondel/SpeechDatasets.git",
    devbranch = "main",
)

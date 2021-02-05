module SpeechDatasets

const SIL = "<sil>"
const UNK = "<unk>"
isspeechunit(u) = u != SIL && u != UNK

include("corpora/mboshi.jl")
using .MBOSHI
export MBOSHI

include("corpora/massdataset.jl")
using .MASSDATASET
export MASSDATASET

include("corpora/yoruba.jl")
using .YORUBA
export YORUBA

end # module

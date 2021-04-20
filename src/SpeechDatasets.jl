module SpeechDatasets

using NaturalSort

const SIL = "<sil>"
const UNK = "<unk>"
isspeechunit(u) = u != SIL && u != UNK

include("corpora/massdataset.jl")
include("corpora/mboshi.jl")
include("corpora/timit.jl")
include("corpora/yoruba.jl")

using .MASSDATASET
using .MBOSHI
using .TIMIT
using .YORUBA

export MASSDATASET
export MBOSHI
export TIMIT
export YORUBA

end # module

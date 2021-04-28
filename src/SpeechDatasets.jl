module SpeechDatasets

# Standard names/labels for the data preparation
include("consts.jl")

# Mapping xsampa -> ipa
include("xsampa_ipa.jl")

include("corpora/alffa.jl")
include("corpora/babel.jl")
include("corpora/massdataset.jl")
include("corpora/mboshi.jl")
include("corpora/timit.jl")
include("corpora/yoruba.jl")

using .ALFFA
using .BABEL
using .MASSDATASET
using .MBOSHI
using .TIMIT
using .YORUBA

export ALFFA
export BABEL
export MASSDATASET
export MBOSHI
export TIMIT
export YORUBA

end # module

module SpeechDatasets

#######################################################################
# Corpora

# Standard names/labels for the data preparation
include("consts.jl")

include("corpora/alffa.jl")
include("corpora/massdataset.jl")
include("corpora/mboshi.jl")
include("corpora/timit.jl")
include("corpora/yoruba.jl")

using .ALFFA
using .MASSDATASET
using .MBOSHI
using .TIMIT
using .YORUBA

export ALFFA
export MASSDATASET
export MBOSHI
export TIMIT
export YORUBA

end # module

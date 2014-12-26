######
# Data-Driven Sets for JuMPeR
######

module DDUS

using JuMPeR  #VG Talk to Iain about removing this

include("helpers.jl")
include("FBOracle.jl")
include("UIOracle.jl")
include("UCSOracle.jl")
include("LCXOracle.jl")
include("UMOracle.jl")
#include("UDYOracle.jl")  #Needs SDP support in JuMPeR ...  add later

end # module

module Embed

using IndexedArrays
using HDF5
using Flimsy
using Flimsy.Components
import Flimsy.Components: cost, predict
using ..Babi

include("nnet.jl")
include("train.jl")
include("dump.jl")
include("load.jl")


end # module Embed
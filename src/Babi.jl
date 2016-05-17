module Babi

using IndexedArrays

typealias Vocab IndexedArray{ASCIIString}

include("reader.jl")

include("Embed/Embed.jl")

end # module Babi
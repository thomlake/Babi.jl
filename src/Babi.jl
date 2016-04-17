module Babi

using IndexedArrays

typealias Vocab IndexedArray{ASCIIString}

include("reader.jl")

end # module Babi
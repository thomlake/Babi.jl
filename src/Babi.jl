module Babi

using IndexedArrays

typealias Vocab IndexedArray{ASCIIString}

const DATA_PATH = "/Users/thom/datasets/fb-babi/tasks_1-20_v1-2/en/"

include("reader.jl")

end # module Babi
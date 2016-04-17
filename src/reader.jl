
type Clause
    i::Int
    text::ASCIIString
    words::Vector{Int}
end
Base.show(io::IO, s::Clause) = print(io, "[$(s.i)] $(s.text)")

abstract Question

type QuestionSingle <: Question
    i::Int
    text::ASCIIString
    words::Vector{Int}
    answer::ASCIIString
    target::Int
    support::Vector{Int}
end
Base.show(io::IO, q::QuestionSingle) = print(io, "[$(q.i)] $(q.text) => $(q.answer) $(q.support)")

type QuestionMultiple <: Question
    i::Int
    text::ASCIIString
    words::Vector{Int}
    answer::Vector{ASCIIString}
    target::Vector{Int}
    support::Vector{Int}
end
Base.show(io::IO, q::QuestionMultiple) = print(io, "[$(q.i)] $(q.text) => $(join(q.answer, ", ")) $(q.support)")

typealias Item Union{Clause,Question}

const QUESTION_TYPE_LOOKUP = Dict{Int,DataType}(
     1 => QuestionSingle,
     2 => QuestionSingle,
     3 => QuestionSingle,
     4 => QuestionSingle,
     5 => QuestionSingle,
     6 => QuestionSingle,
     7 => QuestionSingle,
     8 => QuestionMultiple,
     9 => QuestionSingle,
    10 => QuestionSingle,
    11 => QuestionSingle,
    12 => QuestionSingle,
    13 => QuestionSingle,
    14 => QuestionSingle,
    15 => QuestionSingle,
    16 => QuestionSingle,
    17 => QuestionSingle,
    18 => QuestionSingle,
    19 => QuestionMultiple,
    20 => QuestionSingle,
)


# """Convert from text to bag of words."""
# function bow end

# bow(V::IndexedArray{ASCIIString}, text::ASCIIString) = Int[findfirst(V, w) for w in split(text, " ")]

# const AGENTS = Vector{ASCIIString}[
#     ["john", "mary", "sandra", "daniel"],
# ]

# const LOCATIONS = Vector{ASCIIString}[
#     ["bathroom", "bedroom", "office", "hallway", "kitchen", "garden"],
# ]

# function find_agents(story::Vector{TextItem}, task_id::Int)
#     agents = AGENTS[task_id]
#     seen = Set{ASCIIString}()
#     for item in story
#         for agent in agents
#             if contains(item.text, agent)
#                 push!(seen, agent)
#             end
#         end
#     end
#     return ASCIIString[agent for agent in seen]
# end

# function find_locations(story::Vector{TextItem}, task_id::Int)
#     agents = LOCATIONS[task_id]
#     seen = Set{ASCIIString}()
#     for item in story
#         for agent in agents
#             if contains(item.text, agent)
#                 push!(seen, agent)
#             end
#         end
#     end
#     return ASCIIString[agent for agent in seen]
# end


function Clause(V::Vocab, i::Int, text::ASCIIString)
    words = Int[]
    text = filter(c -> !ispunct(c), strip(text))
    for w in map(ASCIIString, split(text, " "))
        !in(w, V) && push!(V, w)
        push!(words, findfirst(V, w))
    end
    return Clause(i, text, words)
end

function QuestionSingle(V1::Vocab, V2::Vocab, i::Int, text::ASCIIString)
    question_text, answer_text, support_text = map(ASCIIString, split(text, "\t"))
    question_text = filter(c -> !ispunct(c), strip(question_text))
    answer_text = strip(answer_text)
    support = map(k -> parse(Int, k), split(support_text))
    words = Int[]
    for w in map(ASCIIString, split(question_text, " "))
        !in(w, V1) && push!(V1, w)
        push!(words, findfirst(V1, w))
    end
    !in(answer_text, V2) && push!(V2, answer_text)
    answer = findfirst(V2, answer_text)
    return QuestionSingle(i, question_text, words, answer_text, answer, support)
end

function read_text(task_id::Int, V1::Vocab, V2::Vocab, fname::AbstractString)
    Q = QUESTION_TYPE_LOOKUP[task_id]
    stories = Vector{Item}[]
    open(fname) do fp
        story = Item[]
        i = 0
        for (num, line) in enumerate(eachline(fp))
            line = lowercase(line)
            s1, s2 = map(ASCIIString, split(strip(line), " "; limit=2))
            j = parse(Int, s1)
            if j <= i
                length(story) > 0 || error("Found empty story when reading line $num of $fname")
                push!(stories, story)
                story = Item[]
            end
            i = j
            if contains(s2, "\t")
                push!(story, Q(V1, V2, i, s2))
            else
                push!(story, Clause(V1, i, s2))
            end
        end
        if length(story) > 0
            push!(stories, story)
        end
    end
    return stories
end

function task_file_names(task_id::Int; path::AbstractString=ENV["BABI_PATH"], collection::AbstractString="en")
    prefix = string("qa", task_id, "_")
    fullpath = joinpath(path, collection)
    file_names = filter(f -> startswith(f, prefix), readdir(fullpath))
    length(file_names) == 2 || error("Expected two files, found: ", file_names)
    ftrain, ftest = endswith(file_names[1], "train.txt") ? (file_names[1], file_names[2]) : (file_names[2], file_names[1])
    return joinpath(fullpath, ftrain), joinpath(fullpath, ftest)
end

"""
    Babi.read_data(task_id; path=ENV["BABI_PATH"], collection="en")

Read bAbI task data for the task specified by `task_id`. 

*Arguments*

* `task_id::Int`: task number (from 1 to 20).
* `path::AbstractString`: path to the directory containing the bAbI task data, i.e., `"/path/to/tasks_1-20_v1-2/"`.
* `collection::AbstractString`: collection to load. Should be one of `"en"`, `"hn"`, `"shuffled"`, `"en-10k"`, `"hn-10k"`, or `"shuffled-10k"`.

*Returns*

* `input_vocab::IndexedArray{ASCIIString}`: clause and question vocabulary.
* `output_vocab::IndexedArray{ASCIIString}`: answer vocabulary.
* `train_docs::Vector{Vector{Babi.Item}}`: training documents.
* `clause_vocab::IndexedArray{ASCIIString}`: testing document.
"""
function read_data(task_id::Int; path::AbstractString=ENV["BABI_PATH"], collection::AbstractString="en")
    ftrain, ftest = task_file_names(task_id; path=path, collection=collection)
    V1 = Vocab()
    V2 = Vocab()
    train = read_text(task_id, V1, V2, ftrain)
    test = read_text(task_id, V1, V2, ftest)
    return V1, V2, train, test
end
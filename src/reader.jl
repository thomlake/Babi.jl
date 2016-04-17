
type Statement
    i::Int
    text::ASCIIString
    words::Vector{Int}
end
Base.show(io::IO, s::Statement) = print(io, "[$(s.i)] $(s.text)")

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

typealias Item Union{Statement,Question}

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


function Statement(V::Vocab, i::Int, text::ASCIIString)
    words = Int[]
    text = filter(c -> !ispunct(c), strip(text))
    for w in map(ASCIIString, split(text, " "))
        !in(w, V) && push!(V, w)
        push!(words, findfirst(V, w))
    end
    return Statement(i, text, words)
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

function readtext(task_id::Int, V1::Vocab, V2::Vocab, fname::ASCIIString)
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
                # q_, a_, f_ = map(ASCIIString, split(s2, "\t"))
                # q = filter(c -> !ispunct(c), strip(q_))
                # a = strip(a_)
                # f = map(k -> parse(Int, k), split(f_))
                # push!(story, TextQuestion(i, q, a, f))
            else
                push!(story, Statement(V1, i, s2))
            end
        end
        if length(story) > 0
            push!(stories, story)
        end
    end
    return stories
end

function task_file_names(task_id::Int; root::ASCIIString=DATA_PATH)
    prefix = string("qa", task_id, "_")
    file_names = filter(f -> startswith(f, prefix), readdir(root))
    length(file_names) == 2 || error("Expected two files, found: ", file_names)
    ftrain, ftest = endswith(file_names[1], "train.txt") ? (file_names[1], file_names[2]) : (file_names[2], file_names[1])
    return joinpath(root, ftrain), joinpath(root, ftest)
end

function build_dataset(task_id::Int; root::ASCIIString=DATA_PATH)
    ftrain, ftest = task_file_names(task_id; root=root)
    V1 = Vocab()
    V2 = Vocab()
    train = readtext(task_id, V1, V2, ftrain)
    test = readtext(task_id, V1, V2, ftest)
    return V1, V2, train, test
    # words = Set{ASCIIString}()
    # for docs in (docs_train, docs_test)
    #     for doc in docs
    #         for item in doc
    #             union!(words, split(item.text, " "))
    #             isa(item, Question) && push!(words, item.answer)
    #         end
    #     end
    # end
    # vocab = IndexedArray(ASCIIString[word for word in words])

    # bows_train = Vector{Item}[bow(vocab, doc) for doc in docs_train]
    # bows_test = Vector{Item}[bow(vocab, doc) for doc in docs_test]
    # return bows_train, bows_test, vocab
end
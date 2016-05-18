
type Clause{T}
    task_id::Int
    i::Int
    text::ASCIIString
    tokens::T
end
Base.show(io::IO, s::Clause) = print(io, "[$(s.i)] $(s.text)")

type Question{T}
    task_id::Int
    i::Int
    text::ASCIIString
    tokens::T
    answer::ASCIIString
    target::Int
    support::Vector{Int}
end
Base.show(io::IO, q::Question) = print(io, "[$(q.i)] $(q.text) => $(q.answer) $(q.support)")

typealias Item{T} Union{Clause{T},Question{T}}
typealias TextItem Item{Vector{Int}}

function Clause(V::Vocab, task_id::Int, i::Int, text::ASCIIString, gram_size::Int=1)
    text = filter(c -> !ispunct(c), strip(text))
    words = map(ASCIIString, split(text, " "))
    if gram_size > 1
        words = [join(words[j:j + gram_size - 1], " ") for j = 1:length(words) - gram_size + 1]
    end
    tokens = Int[]
    for w in words
        !in(w, V) && push!(V, w)
        push!(tokens, findfirst(V, w))
    end
    return Clause(task_id, i, text, tokens)
end

function Question(V1::Vocab, V2::Vocab, task_id::Int, i::Int, text::ASCIIString, gram_size::Int=1)
    question_text, answer_text, support_text = map(ASCIIString, split(text, "\t"))
    question_text = filter(c -> !ispunct(c), strip(question_text))
    answer_text = strip(answer_text)
    support = map(k -> parse(Int, k), split(support_text))
    words = map(ASCIIString, split(question_text, " "))
    if gram_size > 1
        words = [join(words[j:j + gram_size - 1], " ") for j = 1:length(words) - gram_size + 1]
    end
    tokens = Int[]
    for w in words
        !in(w, V1) && push!(V1, w)
        push!(tokens, findfirst(V1, w))
    end
    !in(answer_text, V2) && push!(V2, answer_text)
    answer = findfirst(V2, answer_text)
    return Question(task_id, i, question_text, tokens, answer_text, answer, support)
end

function read_text(task_id::Int, V1::Vocab, V2::Vocab, fname::AbstractString, gram_size::Int=1)
    stories = Vector{TextItem}[]
    open(fname) do fp
        story = TextItem[]
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
                push!(story, Question(V1, V2, task_id, i, s2, gram_size))
            else
                push!(story, Clause(V1, task_id, i, s2, gram_size))
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
    Babi.dataset(task_id; path=ENV["BABI_PATH"], collection="en")

Read bAbI task data for the task(s) specified by `task_ids`. 

**Arguments**

* `task_ids::Union{Int,Vector{Int}}`: task numbers to load (from 1 to 20).
* `path::AbstractString`: path to the directory containing the bAbI task data, i.e., `"/path/to/tasks_1-20_v1-2/"`.
* `collection::AbstractString`: collection to load. Should be one of `"en"`, `"hn"`, `"shuffled"`, `"en-10k"`, `"hn-10k"`, or `"shuffled-10k"`.
* `gram_size::Int`: number of grams per token.

**Returns**

* `input_vocab::IndexedArray{ASCIIString}`: clause and question vocabulary.
* `output_vocab::IndexedArray{ASCIIString}`: answer vocabulary.
* `train_docs::Vector{Vector{Babi.Item}}`: training documents.
* `clause_vocab::IndexedArray{ASCIIString}`: testing document.
"""
function dataset(task_ids::Vector{Int}; path::AbstractString=ENV["BABI_PATH"], collection::AbstractString="en", gram_size::Int=1)
    V1 = Vocab()
    V2 = Vocab()
    train = Vector{TextItem}[]
    test = Vector{TextItem}[]
    for task_id in task_ids
        ftrain, ftest = task_file_names(task_id; path=path, collection=collection)
        tr = read_text(task_id, V1, V2, ftrain, gram_size)
        te = read_text(task_id, V1, V2, ftest, gram_size)
        append!(train, tr)
        append!(test, te)
    end
    return V1, V2, train, test
end

function dataset(task_id::Int; path::AbstractString=ENV["BABI_PATH"], collection::AbstractString="en", gram_size::Int=1)
    return dataset([task_id]; path=path, collection=collection, gram_size=gram_size)
end
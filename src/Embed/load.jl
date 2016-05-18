
typealias EmbedItem Babi.Item{Matrix{Float32}}

function dataset(task_ids::Vector{Int}, fname)
    vocab = Babi.Vocab()
    train = Vector{EmbedItem}[]
    test = Vector{EmbedItem}[]

    h5open(fname, "r") do f5
        for (name, data) in (("train", train), ("test", test))
            for task_id in task_ids
                g_task = f5[string(name, "/", task_id)]
                story_ids = sort(map(s -> parse(Int, s), names(g_task)))
                for i in story_ids
                    g_story = g_task[string(i)]
                    story = EmbedItem[]
                    item_ids = sort(map(s -> parse(Int, s), names(g_story)))
                    for j in item_ids
                        g = g_story[string(j)]
                        println(read(attrs(g), "index"))
                        if read(attrs(g), "index") != j
                           error("Index mismtach: ", j, " != ", read(attrs(g), "index"), " while reading story ", i, " in task ", task_id) 
                        end
                        x = read(g, "x")
                        text = read(attrs(g), "text")
                        item_type = read(attrs(g), "type")
                        if item_type == "C"
                            push!(story, Babi.Clause(task_id, j, text, x))
                        elseif item_type == "Q"
                            answer = read(attrs(g), "answer")
                            support = map(s -> parse(Int, s), split(read(attrs(g), "support"), ","))
                            !in(answer, vocab) && push!(vocab, answer)
                            target = findfirst(vocab, answer)
                            push!(story, Babi.Question(task_id, j, text, x, answer, target, support))
                        else
                            error("Unknown item type: ", item_type)
                        end
                    end
                    push!(data, story)
                end
            end
        end
    end

    return vocab, train, test
end

dataset(task_id::Int, fname) = load([task_id], fname)
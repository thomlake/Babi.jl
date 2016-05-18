
function Base.dump(param_fname, output_fname)
    vocab, _, data_train, data_test = Babi.read_data(collect(1:20))

    params = Runtime(Flimsy.restore(param_fname))
    story_index_dict = Dict{Int,Int}()
    
    f5 = h5open(output_fname, "w")
    for (name, data) in (("train", data_train), ("test", data_test))
        println("Saving $name data")
        g_data = g_create(f5, name)
        for story in data_train
            task_id = first(story).task_id
            story_id = story_index_dict[task_id] = get(story_index_dict, task_id, 0) + 1
            g_task = exists(g_data, string(task_id)) ? g_data[string(task_id)] : g_create(g_data, string(task_id))
            g_story = g_create(g_task, string(story_id))
            for item in story
                h = encode(params, item.tokens).data
                g = g_create(g_story, string(item.i))
                g["x"] = h
                if isa(item, Babi.Clause)
                    attrs(g)["type"] = "C"
                    attrs(g)["index"] = item.i
                    attrs(g)["text"] = item.text
                else
                    attrs(g)["type"] = "Q"
                    attrs(g)["index"] = item.i
                    attrs(g)["text"] = item.text
                    attrs(g)["answer"] = item.answer
                    attrs(g)["support"] = join(item.support, ",")
                end
            end
        end
    end
    close(f5)
end
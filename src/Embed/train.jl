
function compute_error(params, data)
    errors = 0
    total = 0
    for x in data
        y = predict(params, x)
        errors += sum(x .!= y)
        total += length(x)
    end
    return errors / total
end


function train(fname; 
    n_hid::Int=40,
    learning_rate::AbstractFloat=0.01,
    learning_rate_decay::AbstractFloat=0.97,
    decay::AbstractFloat=0.9,
    grad_noise::Bool=true,
    noise_rate::AbstractFloat=0.01,
    max_epochs::Int=1000,
    seed::Int=123,
    verbosity::Int=2,
    )
    srand(seed)
    vocab, _, data_train, data_test = Babi.read_data(collect(1:20))

    verbosity > 1 && println("Vocab size: ", length(vocab))
    seqs_train = Vector{Int}[]
    seqs_test = Vector{Int}[]
    for story in data_train
        for item in story
            push!(seqs_train, item.tokens)
        end
    end
    for story in data_test
        for item in story
            push!(seqs_test, item.tokens)
        end
    end

    verbosity > 1 && println("Number of training sequences: ", length(seqs_train))
    verbosity > 1 && println("Number of testing sequences: ", length(seqs_test))

    params = Runtime(BabiEncoder(length(vocab), n_hid))
    opt = optimizer(RmsProp, params, 
        learning_rate=learning_rate, 
        decay=decay, 
    )
    noise! = GradientNoise(params, noise_rate)

    stream = ShuffledIter(seqs_train)
    n_epochs = 0
    best_params = deepcopy(params)
    best_train_error = Inf
    best_test_error = Inf

    start_time = time()
    while best_train_error > 0 && best_test_error > 0 && n_epochs < max_epochs
        n_epochs += 1
        nll = 0.0
        for (i, x) in enumerate(stream)
            nll += cost(params, x; grad=true)
            grad_noise && noise!()
            update!(opt)
            i > 2000 && break
        end
        step(noise!)
        opt.learning_rate *= learning_rate_decay
        
        train_error = compute_error(params, seqs_train[rand(1:end, 500)])
        test_error = compute_error(params, seqs_test[rand(1:end, 500)])
        improved = train_error <= best_train_error && test_error <= best_test_error
        if verbosity > 0
            @printf "[%02d] nll => %7.02f, err => %0.02f | %0.02f %s\n" n_epochs nll train_error test_error (improved ? "(*)" : "")
        end

        if improved 
            best_params = deepcopy(params)
            best_train_error = train_error
            best_test_error = test_error
        end

        n_epochs >= max_epochs && break
    end
    stop_time = time()
    verbosity > 0 && println("wall time   => ", round(stop_time - start_time, 2), " seconds")
    verbosity > 0 && println("saving parameters to: ", fname)
    Flimsy.save(fname, best_params)
end

immutable BabiEncoder{V<:Variable} <: Component{V}
    encoder::Lstm{V}
    decoder::Lstm{V}
    clf::SoftmaxRegression{V}
end

BabiEncoder(vocab_size::Int, hidden_dim::Int) = BabiEncoder(
    encoder=Lstm(hidden_dim, vocab_size),
    decoder=Lstm(hidden_dim, hidden_dim),
    clf=SoftmaxRegression(vocab_size, hidden_dim),
)

@comp encode(θ::BabiEncoder, x::Vector{Int}) = unfold(θ.encoder, x)[end]

@comp function cost(θ::BabiEncoder, x::Vector{Int})
    nll = 0.0
    h = encode(θ, x)
    z = initial_state(θ.decoder)
    for w in x
        z = step(θ.decoder, h, z)
        nll += cost(θ.clf, z[1], w)
    end
    return nll
end

@comp function predict(θ::BabiEncoder, x::Vector{Int})
    h = encode(θ, x)
    z = initial_state(θ.decoder)
    y = Int[]
    for t = 1:length(x)
        z = step(θ.decoder, h, z)
        p = predict(θ.clf, z[1])
        push!(y, p[1])
    end
    return y
end
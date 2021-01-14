import Distributions

function random(a::Float64, b::Float64)::Float64
    return rand(Distributions.Uniform(a, b))
end
"""
Package implementing half space trees.

Half space trees are an online variant of isolation forests. They
work well when anomalies are spread out. However, they do not work
well if anomalies are packed together in windows.
"""
module HalfSpaceTrees

export HalfSpaceTree, learn!, score

import Base

include("./utils.jl")
include("./binarytree.jl")

const Feature = Dict{String,Float64};

struct Split
    on::String
    how::String
    at::Float64
end

mutable struct Data
    rmass::Int
    lmass::Int
    split::Split

    Data(rmass, lmass) = new(rmass, lmass)
    Data(rmass, lmass, split) = new(rmass, lmass, split)
end

struct WalkTreeFeature
    root::BinaryNode
    feature::Feature
end

Base.iterate(wtf::WalkTreeFeature) = (wtf.root, wtf.root)
function Base.iterate(wtf::WalkTreeFeature, state::BinaryNode)
    node = state
    if !isdefined(node.data, :split)
        return nothing
    end

    try
        node = next(node, wtf.feature)
    catch ex
        if isa(ex, KeyError)
            if node.right.data.lmass > node.left.data.lmass
                node = node.right
            else
                node = node.left
            end
        else
            rethrow(ex)
        end
    end
    return (node, node)
end

function next(node::BinaryNode, x::Feature)
    if node.data.split.how == "lt"
        if x[node.data.split.on] < node.data.split.at
            return node.left
        else
            return node.right
        end
    end
end

# HACK: Given recursion, stack overflow may happen here.
function maketree(
    limits::Dict{String,Tuple{Float64,Float64}},
    height::Int,
    padding::Float64,
    rmass::Int,
    lmass::Int)

    if height == 0
        return BinaryNode(Data(rmass, lmass))
    end

    on = rand(keys(limits))

    (a, b) = limits[on]
    at = random(a + padding * (b - a), b - padding * (b - a))

    tmp = limits[on]
    limits[on] = (tmp[1], at)
    left = maketree(limits, height - 1, padding, rmass, lmass)
    limits[on] = tmp

    tmp = limits[on]
    limits[on] = (at, tmp[2])
    right = maketree(limits, height - 1, padding, rmass, lmass)
    limits[on] = tmp

    res = BinaryNode(
        Data(rmass, lmass, Split(on, "lt", at)),
        left,
        right
    )

    return res
end

"""
    HalfSpaceTree(; <keyword arguments>)

Half space tree, an online variant of isolation forests.

# Arguments
- `ntrees::Int`: The number of trees, defaults to 10.
- `height::Int`: The height of each tree, defaults to 8.
- `windowsize::Int`: The window size, defaults to 250.
- `limits::Union{Dict{String,Tuple{Float64,Float64}},Nothing}`: Limits of each feature,
  defaults to nothing and hence to [0, 1] for each feature.

# Examples
```julia-repl
julia> hst = HalfSpaceTree(ntrees=10, height=3, windowsize=3);
```
"""
mutable struct HalfSpaceTree
    ntrees::Int
    height::Int
    windowsize::Int
    limits::Union{Dict{String,Tuple{Float64,Float64}},Nothing}
    trees::Any
    counter::Int
    firstwindow::Bool

    function HalfSpaceTree(;ntrees=10, height=8, windowsize=250, limits=nothing)
        if !(ntrees > 0)
            throw(ArgumentError("ntrees must be > 0"))
        end
        if !(height > 0)
            throw(ArgumentError("height must be > 0"))
        end
        if !(windowsize > 0)
            throw(ArgumentError("windowsize must be > 0"))
        end

        new(ntrees, height, windowsize, limits, nothing, 0, true)
    end
end

sizelimit(hst::HalfSpaceTree) = 0.1 * hst.windowsize
maxscore(hst::HalfSpaceTree) = hst.ntrees * hst.windowsize * (2^(hst.height + 1) - 1)

"""
    learn!(hst::HalfSpaceTree, x::Dict{String,Float64})

Learn feature `x`. Assumes all values of `x` to be between [0, 1]. If
not use `limits` while constucting the half space tree. Returns updated
`hst`.

# Examples
```julia-repl
julia> x = [Dict("x" => e, "y" => e, "z" => e) for e in [0.5, 0.45, 0.43, 0.44, 0.445, 0.45, 0.0]];

julia> for e in x[1:3]
           learn!(hst, e)
       end
```
"""
function learn!(hst::HalfSpaceTree, x::Feature)
    if hst.trees === nothing
        limit = (0.0, 1.0)
        limits = Dict(key => limit for key in keys(x))
        if hst.limits !== nothing
            limits = merge(limits, hst.limits)
        end

        hst.trees = [
            maketree(limits, hst.height, 0.15, 0, 0)
            for _ in 1:hst.ntrees
        ]
    end

    for tree in hst.trees
        for node in WalkTreeFeature(tree, x)
            node.data.lmass += 1
        end
    end

    hst.counter += 1
    if hst.counter == hst.windowsize
        for tree in hst.trees
            for node in inordertraversal(tree)
                node.data.rmass = node.data.lmass
                node.data.lmass = 0
            end
        end
        hst.firstwindow = false
        hst.counter = 0
    end

    return hst
end

"""
    score(hst::HalfSpaceTree, x::Dict{String,Float64})

Score feature `x`. Assumes all values of `x` to be between [0, 1]. If
not use `limits` while constucting the half space tree. Returns a score
between [0, 1] for `x`, with higher values more likely to be an anomaly.

# Examples
```julia-repl
# learn at least windowsize features
julia> score(hst, x[end - 1])
"""
function score(hst::HalfSpaceTree, x::Feature)
    if hst.firstwindow
        return 0.0
    end

    score = 0.0
    for tree in hst.trees
        for (depth, node) in enumerate(WalkTreeFeature(tree, x))
            score += node.data.rmass * 2^(depth - 1)
            if node.data.rmass < sizelimit(hst)
                break
            end
        end
    end
    score /= maxscore(hst)

    return 1 - score
end

end
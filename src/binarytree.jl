mutable struct BinaryNode{T}
    data::T
    left::BinaryNode{T}
    right::BinaryNode{T}

    BinaryNode{T}(data) where T = new{T}(data)
    BinaryNode{T}(data, left, right) where T = new{T}(data, left, right)
end

BinaryNode(data::T) where T = BinaryNode{typeof(data)}(data)

BinaryNode(data::T, left::BinaryNode{T}, right::BinaryNode{T}) where T =
BinaryNode{T}(data, left, right)

function inordertraversal(root::BinaryNode)
    acc = Array{BinaryNode,1}()
    function f(acc, root)
        push!(acc, root)
        if isdefined(root, :left)
            f(acc, root.left)
        end

        if isdefined(root, :right)
            f(acc, root.right)
        end
        return nothing
    end
    f(acc, root)
    return acc
end
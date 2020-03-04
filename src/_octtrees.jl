# specific stuff for Oct trees


mutable struct OctTreeNode{T<:AbstractPoint3D} <: SpatialTreeNode
    id::Int64
    r::Float64
    midx::Float64
    midy::Float64
    midz::Float64
    is_empty::Bool
    is_divided::Bool
    point::T
    lxlylz::OctTreeNode{T}
    lxhylz::OctTreeNode{T}
    hxlylz::OctTreeNode{T}
    hxhylz::OctTreeNode{T}
    lxlyhz::OctTreeNode{T}
    lxhyhz::OctTreeNode{T}
    hxlyhz::OctTreeNode{T}
    hxhyhz::OctTreeNode{T}
    function OctTreeNode{T}(r::Number, midx::Number, midy::Number, midz::Number) where T <:AbstractPoint3D
        n = new(0, r, midx, midy, midz, true, false, T())
        n.lxlylz = n
        n.lxhylz = n
        n.hxlylz = n
        n.hxhylz = n
        n.lxlyhz = n
        n.lxhyhz = n
        n.hxlyhz = n
        n.hxhyhz = n
        n
    end
end

OctTreeNode{T}(r::Number, midx::Number, midy::Number, midz::Number, ::Type{T}) where T <:AbstractPoint3D = OctTreeNode{T}(r, midx, midy, midz)
OctTreeNode{T}(::Type{T}) where T <:AbstractPoint3D = OctTreeNode(0.5, 0.5, 0.5, 0.5, T)
OctTreeNode() = OctTreeNode(Point3D)

mutable struct OctTree{T<:AbstractPoint3D} <: SpatialTree
    head::OctTreeNode{T}
    number_of_nodes_used::Int64
    nodes::Array{OctTreeNode, 1}
    faststack::Array{OctTreeNode{T}, 1}
    function OctTree{T}(r::Number, midx::Number, midy::Number, midz::Number, n::Int64=100000) where T <:AbstractPoint3D
        nodes = OctTreeNode[OctTreeNode(r, midx, midy, midz, T) for i in 1:n]
        new(nodes[1], 1, nodes, [OctTreeNode(T) for i in 1:10000])
    end
end

OctTree{T}(r::Number, midx::Number, midy::Number, midz::Number, ::Type{T};n=1000) where T <:AbstractPoint3D = OctTree{T}(r, midx, midy, midz, n)
OctTree{T}(::Type{T};n=10000) where T <:AbstractPoint3D = OctTree(0.5, 0.5, 0.5, 0.5, T; n=n)
OctTree(n::Int64) = OctTree(Point3D; n=n)
OctTree() = OctTree(Point3D)
Base.eltype(::OctTree{T}) where T <:AbstractPoint3D = T

function initnode!(q::OctTreeNode{T}, r::Number, midx::Number, midy::Number, midz::Number) where T <:AbstractPoint3D
    q.r = r
    q.midx = midx
    q.midy = midy
    q.midz = midz
    q.is_empty = true
    q.is_divided = false
    q.id = 0
end

function divide!(h::OctTree{T}, q::OctTreeNode{T}) where T<:AbstractPoint3D
    # make sure we have enough nodes
    if length(h.nodes) - h.number_of_nodes_used < 8
        new_size = length(h.nodes)+(length(h.nodes) >>> 1)
        sizehint!(h.nodes, new_size)
        for i in 1:(new_size-length(h.nodes))
            push!(h.nodes, OctTreeNode(T))
        end
    end

    # populate new nodes
    q.lxlylz = h.nodes[h.number_of_nodes_used+1]
    q.lxhylz = h.nodes[h.number_of_nodes_used+2]
    q.hxlylz = h.nodes[h.number_of_nodes_used+3]
    q.hxhylz = h.nodes[h.number_of_nodes_used+4]
    q.lxlyhz = h.nodes[h.number_of_nodes_used+5]
    q.lxhyhz = h.nodes[h.number_of_nodes_used+6]
    q.hxlyhz = h.nodes[h.number_of_nodes_used+7]
    q.hxhyhz = h.nodes[h.number_of_nodes_used+8]

    # set new nodes properties (dimensions etc.)
    r2 = q.r/2.0
    initnode!(q.lxlylz, r2, q.midx-r2, q.midy-r2, q.midz-r2)
    initnode!(q.lxhylz, r2, q.midx-r2, q.midy+r2, q.midz-r2)
    initnode!(q.hxlylz, r2, q.midx+r2, q.midy-r2, q.midz-r2)
    initnode!(q.hxhylz, r2, q.midx+r2, q.midy+r2, q.midz-r2)
    initnode!(q.lxlyhz, r2, q.midx-r2, q.midy-r2, q.midz+r2)
    initnode!(q.lxhyhz, r2, q.midx-r2, q.midy+r2, q.midz+r2)
    initnode!(q.hxlyhz, r2, q.midx+r2, q.midy-r2, q.midz+r2)
    initnode!(q.hxhyhz, r2, q.midx+r2, q.midy+r2, q.midz+r2)

    # update tree and parent node
    h.number_of_nodes_used += 8
    q.is_divided = true
    if !q.is_empty
        # move point in parent node to child node
        sq = _getsubnode(q, q.point)
        sq.is_empty = false
        q.is_empty = true
        sq.point = q.point
        q.point = T()
    end
    q
end

function _getsubnode(q::OctTreeNode{T}, point::T) where T <:AbstractPoint3D
    x=getx(point)
    y=gety(point)
    z=getz(point)
    if x<q.midx
        # lx
        if y<q.midy
            # ly
            z<q.midz && return q.lxlylz
            return q.lxlyhz
        else
            # hy
            z<q.midz && return q.lxhylz
            return q.lxhyhz
        end
    else
        # hx
        if y<q.midy
            # ly
            z<q.midz && return q.hxlylz
            return q.hxlyhz
        else
            # hy
            z<q.midz && return q.hxhylz
            return q.hxhyhz
        end
    end
end

function map(t::OctTree{T}, cond_data) where T <: AbstractPoint3D
    curr_stack_ix = 1
    t.faststack[1] = t.head
    @inbounds while curr_stack_ix > 0
        q = t.faststack[curr_stack_ix]
        curr_stack_ix -= 1
        if !stop_cond(q, cond_data) && q.is_divided
            curr_stack_ix += 1
            t.faststack[curr_stack_ix] = q.lxlylz
            curr_stack_ix += 1
            t.faststack[curr_stack_ix] = q.lxlyhz
            curr_stack_ix += 1
            t.faststack[curr_stack_ix] = q.lxhylz
            curr_stack_ix += 1
            t.faststack[curr_stack_ix] = q.lxhyhz
            curr_stack_ix += 1
            t.faststack[curr_stack_ix] = q.hxlylz
            curr_stack_ix += 1
            t.faststack[curr_stack_ix] = q.hxlyhz
            curr_stack_ix += 1
            t.faststack[curr_stack_ix] = q.hxhylz
            curr_stack_ix += 1
            t.faststack[curr_stack_ix] = q.hxhyhz
        end
    end
end

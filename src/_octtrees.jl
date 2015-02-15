# specific stuff for Oct trees


type OctTreeNode{T<:AbstractPoint3D} <: SpatialTreeNode
    minx::Float64
    maxx::Float64
    miny::Float64
    maxy::Float64
    minz::Float64
    maxz::Float64
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
    function OctTreeNode(minx::Number, maxx::Number, miny::Number, maxy::Number, minz::Number, maxz::Number)
        n = new(minx, maxx, miny, maxy, minz, maxz, (minx+maxx)/2, (miny+maxy)/2, (minz+maxz)/2, true, false, T())
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

OctTreeNode{T<:AbstractPoint3D}(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64, minz::Float64, maxz::Float64, ::Type{T}) =
    OctTreeNode{T}(minx, maxx, miny, maxy, minz, maxz)
OctTreeNode{T<:AbstractPoint3D}(::Type{T}) =
    OctTreeNode(0., 1., 0., 1., 0., 1., T)
OctTreeNode() = OctTreeNode(Point3D)

type OctTree{T<:AbstractPoint3D} <: SpatialTree
    head::OctTreeNode{T}
    number_of_nodes_used::Int64
    nodes::Array{OctTreeNode, 1}
    faststack::Array{OctTreeNode{T}, 1}
    function OctTree(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64, minz::Float64, maxz::Float64, n::Int64=100000)
        nodes = OctTreeNode[OctTreeNode(minx, maxx, miny, maxy, minz, maxz, T) for i in 1:n]
        new(nodes[1], 1, nodes, [OctTreeNode(T) for i in 1:10000])
    end
end

OctTree{T<:AbstractPoint3D}(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64, minz::Float64, maxz::Float64, ::Type{T};n=1000) = OctTree{T}(minx, maxx, miny, maxy, minz, maxz, n)
OctTree{T<:AbstractPoint3D}(::Type{T};n=10000) = OctTree(0., 1., 0., 1., 0., 1.0, T; n=n)
OctTree(n::Int64) = OctTree(Point3D;n=n)
OctTree() = OctTree(Point3D)
eltype{T<:AbstractPoint3D}(::OctTree{T}) = T

 @inline function initnode!{T<:AbstractPoint3D}(q::OctTreeNode{T}, minx::Number, maxx::Number, miny::Number, maxy::Number, minz::Number, maxz::Number)
    q.minx = minx
    q.maxx = maxx
    q.miny = miny
    q.maxy = maxy
    q.minz = minz
    q.maxz = maxz
    q.is_empty = true
    q.is_divided = false
    q.midx = (minx+maxx)/2
    q.midy = (miny+maxy)/2
    q.midz = (minz+maxz)/2
end

function divide!{T<:AbstractPoint3D}(h::OctTree{T}, q::OctTreeNode{T})
    # make sure we have enough nodes
    if length(h.nodes) - h.number_of_nodes_used < 8
        new_size = length(h.nodes)+(length(h.nodes) >>> 1)
        sizehint!(h.nodes, new_size)
        for i in 1:(new_size-length(h.nodes))
            push!(h.nodes, OctTreeNode(T))
        end
    end

    # populate new nodes
    @inbounds q.lxlylz = h.nodes[h.number_of_nodes_used+1]
    @inbounds q.lxhylz = h.nodes[h.number_of_nodes_used+2]
    @inbounds q.hxlylz = h.nodes[h.number_of_nodes_used+3]
    @inbounds q.hxhylz = h.nodes[h.number_of_nodes_used+4]
    @inbounds q.lxlyhz = h.nodes[h.number_of_nodes_used+5]
    @inbounds q.lxhyhz = h.nodes[h.number_of_nodes_used+6]
    @inbounds q.hxlyhz = h.nodes[h.number_of_nodes_used+7]
    @inbounds q.hxhyhz = h.nodes[h.number_of_nodes_used+8]

    # set new nodes properties (dimensions etc.)
    initnode!(q.lxlylz, q.minx, q.midx, q.miny, q.midy, q.minz, q.midz)
    initnode!(q.lxhylz, q.minx, q.midx, q.midy, q.maxy, q.minz, q.midz)
    initnode!(q.hxlylz, q.midx, q.maxx, q.miny, q.midy, q.minz, q.midz)
    initnode!(q.hxhylz, q.midx, q.maxx, q.midy, q.maxy, q.minz, q.midz)
    initnode!(q.lxlyhz, q.minx, q.midx, q.miny, q.midy, q.midz, q.maxz)
    initnode!(q.lxhyhz, q.minx, q.midx, q.midy, q.maxy, q.midz, q.maxz)
    initnode!(q.hxlyhz, q.midx, q.maxx, q.miny, q.midy, q.midz, q.maxz)
    initnode!(q.hxhyhz, q.midx, q.maxx, q.midy, q.maxy, q.midz, q.maxz)

    # update tree and parent node
    h.number_of_nodes_used += 8
    q.is_divided = true
    if !q.is_empty
        # move point in parent node to child node
        const sq = _getsubnode(q, q.point)
        sq.is_empty = false
        q.is_empty = true
        sq.point = q.point
        q.point = T()
    end
    q
end

@inline function _getsubnode{T<:AbstractPoint3D}(q::OctTreeNode{T}, point::T)
    const x=getx(point)
    const y=gety(point)
    const z=getz(point)
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

@inline function map{T<:AbstractPoint3D}(t::OctTree{T}, cond_data)
    curr_stack_ix = 1
    t.faststack[1] = t.head
    while curr_stack_ix > 0
        @inbounds q = t.faststack[curr_stack_ix]
        curr_stack_ix -= 1
        stop_cond(q, cond_data) && continue
        if q.is_divided
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.lxlylz
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.lxlyhz
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.lxhylz
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.lxhyhz
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.hxlylz
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.hxlyhz
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.hxhylz
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.hxhyhz
        end
    end
end


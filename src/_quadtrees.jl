# specific stuff for quad trees


type QuadTreeNode{T<:AbstractPoint2D} <: SpatialTreeNode
    id::Int64
    r::Float64
    midx::Float64
    midy::Float64
    is_empty::Bool
    is_divided::Bool
    point::T
    lxly::QuadTreeNode{T}
    lxhy::QuadTreeNode{T}
    hxly::QuadTreeNode{T}
    hxhy::QuadTreeNode{T}
    function QuadTreeNode(r::Number, midx::Number, midy::Number)
        n = new(0, r, midx, midy, true, false, T())
        n.lxly = n
        n.lxhy = n
        n.hxly = n
        n.hxhy = n
        n
    end
end

QuadTreeNode{T<:AbstractPoint2D}(r::Number, midx::Number, midy::Number, ::Type{T}) =
    QuadTreeNode{T}(r, midx, midy)
QuadTreeNode{T<:AbstractPoint2D}(::Type{T}) = QuadTreeNode(0.5, 0.5, 0.5, T)
QuadTreeNode() = QuadTreeNode(Point2D);

type QuadTree{T<:AbstractPoint2D} <: SpatialTree
	head::QuadTreeNode{T}
	number_of_nodes_used::Int64
	nodes::Array{QuadTreeNode, 1}
    faststack::Array{QuadTreeNode{T}, 1}
    function QuadTree(r::Number, midx::Number, midy::Number, n::Int64=100000)
    	nodes = QuadTreeNode[QuadTreeNode(r, midx, midy, T) for i in 1:n]
        new(nodes[1], 1, nodes, [QuadTreeNode(T) for i in 1:10000])
    end
end

QuadTree{T<:AbstractPoint2D}(r::Number, midx::Number, midy::Number, ::Type{T};n=1000) =
    QuadTree{T}(r, midx, midy, n)
QuadTree{T<:AbstractPoint2D}(::Type{T};n=10000) = QuadTree(0.5, 0.5, 0.5, T; n=n)
QuadTree(n::Int64) = QuadTree(Point2D;n=n)
QuadTree() = QuadTree(Point2D)
eltype{T<:AbstractPoint2D}(::QuadTree{T}) = T

function initnode!{T<:AbstractPoint2D}(q::QuadTreeNode{T}, r::Number, midx::Number, midy::Number)
    q.r = r
    q.midx = midx
    q.midy = midy
    q.is_empty = true
    q.is_divided = false
end

function divide!{T<:AbstractPoint2D}(h::QuadTree{T}, q::QuadTreeNode{T})
    # make sure we have enough nodes
    if length(h.nodes) - h.number_of_nodes_used < 4
    	new_size = length(h.nodes)+(length(h.nodes) >>> 1)
    	sizehint!(h.nodes, new_size)
    	for i in 1:(new_size-length(h.nodes))
    		push!(h.nodes, QuadTreeNode(T))
    	end
    end

    # populate new nodes
    @inbounds q.lxly = h.nodes[h.number_of_nodes_used+1]
    @inbounds q.lxhy = h.nodes[h.number_of_nodes_used+2]
    @inbounds q.hxly = h.nodes[h.number_of_nodes_used+3]
    @inbounds q.hxhy = h.nodes[h.number_of_nodes_used+4]

    # set new nodes properties (dimensions etc.)
    const r2 = q.r/2
    initnode!(q.lxly, r2, q.midx-r2, q.midy-r2)
    initnode!(q.lxhy, r2, q.midx-r2, q.midy+r2)
    initnode!(q.hxly, r2, q.midx+r2, q.midy-r2)
    initnode!(q.hxhy, r2, q.midx+r2, q.midy+r2)

    # update tree and parent node
    h.number_of_nodes_used += 4
    q.is_divided = true
    if !q.is_empty
        # move point in parent node to child node
        const sq = _getsubnode(q, q.point)
        sq.is_empty = false
        q.is_empty = true
        sq.point, q.point = q.point, sq.point
    end
    q
end

@inline function _getsubnode{T<:AbstractPoint2D}(q::QuadTreeNode{T}, point::T)
    const x=getx(point)
    const y=gety(point)
    if x<q.midx
        y<q.midy && return q.lxly
        return q.lxhy
    end
    y<q.midy && return q.hxly
    return q.hxhy
end

@inline function map{T<:AbstractPoint2D}(t::QuadTree{T}, cond_data)
    curr_stack_ix = 1
    @inbounds t.faststack[1] = t.head
    while curr_stack_ix > 0
        @inbounds q = t.faststack[curr_stack_ix]
        curr_stack_ix -= 1
        if !stop_cond(q, cond_data) && q.is_divided
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.lxly
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.lxly
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.lxhy
            curr_stack_ix += 1
            @inbounds t.faststack[curr_stack_ix] = q.lxhy
        end
    end
end

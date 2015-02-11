# specific stuff for quad trees


type QuadTreeNode{T<:AbstractPoint2D} <: SpatialTreeNode
    minx::Float64
    maxx::Float64
    miny::Float64
    maxy::Float64
    midx::Float64
    midy::Float64
    is_empty::Bool
    is_divided::Bool
    point::T
    lxly::QuadTreeNode{T}
    lxhy::QuadTreeNode{T}
    hxly::QuadTreeNode{T}
    hxhy::QuadTreeNode{T}
    QuadTreeNode(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64) = 
        new(minx, maxx, miny, maxy, (minx+maxx)/2, (miny+maxy)/2, true, false, T())
end

QuadTreeNode{T<:AbstractPoint2D}(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64, ::Type{T}) =
    QuadTreeNode{T}(minx, maxx, miny, maxy)
QuadTreeNode{T<:AbstractPoint2D}(::Type{T}) = QuadTreeNode(Float64(0.), Float64(1.), Float64(0.), Float64(1.), T)
QuadTreeNode() = QuadTreeNode(Point2D);

type QuadTree{T<:AbstractPoint2D} <: SpatialTree
	head::QuadTreeNode{T}
	number_of_nodes_used::Int64
	nodes::Array{QuadTreeNode, 1}
    function QuadTree(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64, n::Int64=100000)
    	nodes = QuadTreeNode[QuadTreeNode(minx, maxx, miny, maxy, T) for i in 1:n]
        new(nodes[1], 1, nodes)
    end
end

QuadTree{T<:AbstractPoint2D}(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64, ::Type{T};n=1000) = QuadTree{T}(minx, maxx, miny, maxy, n)
QuadTree{T<:AbstractPoint2D}(::Type{T};n=10000) = QuadTree(Float64(0.), Float64(1.), Float64(0.), Float64(1.), T; n=n)
QuadTree(n::Int64) = QuadTree(Point2D;n=n)
QuadTree() = QuadTree(Point2D)
eltype{T<:AbstractPoint2D}(::QuadTree{T}) = T

function initnode!{T<:AbstractPoint2D}(q::QuadTreeNode{T}, minx::Float64, maxx::Float64, miny::Float64, maxy::Float64)
    q.minx = minx
    q.maxx = maxx
    q.miny = miny
    q.maxy = maxy
    q.is_empty = true
    q.is_divided = false
    q.midx = (minx+maxx)/2
    q.midy = (miny+maxy)/2
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
    initnode!(q.lxly, q.minx, q.midx, q.miny, q.midy)
    initnode!(q.lxhy, q.minx, q.midx, q.midy, q.maxy)
    initnode!(q.hxly, q.midx, q.maxx, q.miny, q.midy)
    initnode!(q.hxhy, q.midx, q.maxx, q.midy, q.maxy)

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

function _getsubnode{T<:AbstractPoint2D}(q::QuadTreeNode{T}, point::T)
    const x=getx(point)
    const y=gety(point)
    if x<q.midx
        y<q.midy && return q.lxly
        return q.lxhy
    end
    y<q.midy && return q.hxly
    return q.hxhy
end

function _map{T<:AbstractPoint2D}(q::QuadTreeNode{T}, cond_data)
    stop_cond(q, cond_data) && return
    if q.is_divided
        _map(q.lxly, cond_data)
        _map(q.lxhy, cond_data)
        _map(q.hxly, cond_data)
        _map(q.hxhy, cond_data)
    end
end

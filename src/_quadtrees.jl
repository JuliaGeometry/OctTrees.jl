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

QuadTreeNode{T<:AbstractPoint2D}(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64, ::Type{T}) = QuadTreeNode{T}(minx, maxx, miny, maxy)
QuadTreeNode{T<:AbstractPoint2D}(::Type{T}) = QuadTreeNode(0., 1., 0., 1., T)
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
QuadTree{T<:AbstractPoint2D}(::Type{T};n=10000) = QuadTree(0., 1., 0., 1., T; n=n)
QuadTree(n::Int64) = QuadTree(Point2D;n=n)
QuadTree() = QuadTree(Point2D)

function _divide!{T<:AbstractPoint2D}(h::QuadTree{T}, q::QuadTreeNode{T})
    if length(h.nodes) - h.number_of_nodes_used < 4
    	new_size = length(h.nodes)+length(h.nodes) >>> 1
    	sizehint!(h.nodes, new_size)
    	for i in 1:(new_size-length(h.nodes))
    		push!(h.nodes, QuadTreeNode(T))
    	end
    end
    h.number_of_nodes_used += 1
    q.lxly = h.nodes[h.number_of_nodes_used]
    q.lxly.minx = q.minx
    q.lxly.maxx = q.midx
    q.lxly.miny = q.miny
    q.lxly.maxy = q.midy
    q.lxly.is_empty = true
    q.lxly.is_divided = false
    q.lxly.midx = (q.lxly.minx+q.lxly.maxx)/2
    q.lxly.midy = (q.lxly.miny+q.lxly.maxy)/2

    h.number_of_nodes_used += 1
    q.lxhy = h.nodes[h.number_of_nodes_used]
    q.lxhy.minx = q.minx
    q.lxhy.maxx = q.midx
    q.lxhy.miny = q.midy
    q.lxhy.maxy = q.maxy
    q.lxhy.is_empty = true
    q.lxhy.is_divided = false
    q.lxhy.midx = (q.lxhy.minx+q.lxhy.maxx)/2
    q.lxhy.midy = (q.lxhy.miny+q.lxhy.maxy)/2

    h.number_of_nodes_used += 1
    q.hxly = h.nodes[h.number_of_nodes_used]
    q.hxly.minx = q.midx
    q.hxly.maxx = q.maxx
    q.hxly.miny = q.miny
    q.hxly.maxy = q.midy
    q.hxly.is_empty = true
    q.hxly.is_divided = false
    q.hxly.midx = (q.hxly.minx+q.hxly.maxx)/2
    q.hxly.midy = (q.hxly.miny+q.hxly.maxy)/2

    h.number_of_nodes_used += 1
    q.hxhy = h.nodes[h.number_of_nodes_used]
    q.hxhy.minx = q.midx
    q.hxhy.maxx = q.maxx
    q.hxhy.miny = q.midy
    q.hxhy.maxy = q.maxy
    q.hxhy.is_empty = true
    q.hxhy.is_divided = false
    q.hxhy.midx = (q.hxhy.minx+q.hxhy.maxx)/2
    q.hxhy.midy = (q.hxhy.miny+q.hxhy.maxy)/2


    if !q.is_empty
        const sq = _getsubquad(q, q.point)
        sq.is_empty = false
        sq.point, q.point = q.point, sq.point
        q.is_empty = true
    end
    q.is_divided = true
    q
end

function _getsubquad{T<:AbstractPoint2D}(q::QuadTreeNode{T}, point::T)
    const x=getx(point)
    const y=gety(point)
    if x<q.midx
        y<q.midy && return q.lxly
        return q.lxhy
    end
    y<q.midy && return q.hxly
    return q.hxhy
end

function insert!{T<:AbstractPoint2D}(h::QuadTree{T}, point::T)
	q = h.head
    while q.is_divided
        q = _getsubquad(q, point)
    end
    if !q.is_empty
        _divide!(h, q)
        q = _getsubquad(q, point)
    end
    q.point = point
    q.is_empty = false
    q
end


function insert!{T<:AbstractPoint2D}(h::QuadTree{T}, point::T, additional_data)
    q = h.head
    while q.is_divided
        modify(q, point, additional_data)
        q = _getsubquad(q, point)
    end
    if !q.is_empty
        friend = q.point
        _divide!(h, q)
        modify(q, friend, additional_data)
        modify(q, point, additional_data)
        q = _getsubquad(q, point)
    end
    q.point = point
    q.is_empty = false
    q
end

function _map{T<:AbstractPoint2D}(q::QuadTreeNode{T}, cond_data, apply_data)
    if cond(q, cond_data, apply_data)
        apply(q, cond_data, apply_data)
    elseif q.is_divided
        _map(q.lxly, cond_data, apply_data)
        _map(q.lxhy, cond_data, apply_data)
        _map(q.hxly, cond_data, apply_data)
        _map(q.hxhy, cond_data, apply_data)
    end
end



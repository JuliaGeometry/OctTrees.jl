module OctTrees

export
	QuadTree,
	insert!

using GeometricalPredicates

type QuadTree{T<:AbstractPoint2D}
    minx::Float64
    maxx::Float64
    miny::Float64
    maxy::Float64
    midx::Float64
    midy::Float64
    is_empty::Bool
    is_divided::Bool
    lxly::QuadTree{T}
    lxhy::QuadTree{T}
    hxly::QuadTree{T}
    hxhy::QuadTree{T}
    point::T
    function QuadTree(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64)
        new(minx, maxx, miny, maxy, (minx+maxx)/2, (miny+maxy)/2, true, false)
    end
end

QuadTree{T<:AbstractPoint2D}(minx::Float64, maxx::Float64, miny::Float64, maxy::Float64, ::Type{T}) = QuadTree{T}(minx, maxx, miny, maxy)
QuadTree{T<:AbstractPoint2D}(::Type{T}) = QuadTree(0., 1., 0., 1., T)
QuadTree() = QuadTree(Point2D);

function _divide!{T<:AbstractPoint2D}(q::QuadTree{T})
    q.lxly = QuadTree(q.minx, q.miny, q.midx, q.midy, T)
    q.lxhy = QuadTree(q.minx, q.midy, q.midx, q.maxy, T)
    q.hxly = QuadTree(q.midx, q.miny, q.maxx, q.midy, T)
    q.hxhy = QuadTree(q.midx, q.midy, q.maxx, q.maxy, T)
    if !q.is_empty
        const sq = _getsubquad(q, q.point)
        sq.is_empty = false
        sq.point = q.point
    end
    q.is_divided = true
    q.is_empty = true
    q
end

function _getsubquad{T<:AbstractPoint2D}(q::QuadTree{T}, point::T)
    const x=getx(point)
    const y=gety(point)
    if x<q.midx
        if y<q.midy
            return q.lxly
        else
            return q.lxhy
        end
    else
        if y<q.midy
            return q.hxly
        else
            return q.hxhy
        end
    end
end

function insert!{T<:AbstractPoint2D}(q::QuadTree{T}, point::T)
    while q.is_divided
        q = _getsubquad(q, point)
    end
    while !q.is_empty
        _divide!(q)
        q = _getsubquad(q, point)
    end
    q.point = point
    q.is_empty = false
    q
end

end # module

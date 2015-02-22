module OctTrees

using GeometricalPredicates

export
    OctTree,
    CompiledOctTree,
    QuadTree,
    insert!,
    clear!,
    eltype,
    Point,
    Point2D,
    Point3D,
    Modify,
    modify,
    QuadTreeNode,
    OctTreeNode,
    CompiledOctTreeNode,
    map,
    No_Cond_Data,
    No_Apply_Data,
    AbstractPoint,
    AbstractPoint2D,
    AbstractPoint3D,
    isleaf,
    isemptyleaf,
    isfullleaf,
    divide!,
    initnode!,
    compile!

# for compatibility reasons
if VERSION < v"0.4-"
    sizehint! = sizehint
end

# General stuff good for both Quad and Oct trees

abstract SpatialTree
abstract SpatialTreeNode

immutable Modify end
immutable No_Cond_Data end

isleaf(q::SpatialTreeNode) = !q.is_divided
isemptyleaf(q::SpatialTreeNode) = !q.is_divided && q.is_empty
isfullleaf(q::SpatialTreeNode) = !q.is_empty

stop_cond(q::SpatialTreeNode, ::Type{No_Cond_Data}) =
    stop_cond(q)

function clear!(h::SpatialTree)
    h.head.id = 0
    h.head.is_empty = true
    h.head.is_divided = false
    h.number_of_nodes_used = 1
    nothing
end

function insert!(h::SpatialTree, point::AbstractPoint)
    q = h.head
    while q.is_divided
        q = _getsubnode(q, point)
    end
    while !q.is_empty
        divide!(h, q)
        q = _getsubnode(q, point)
    end
    q.point = point
    q.is_empty = false
    q
end

# This function is needed for speed. Using another modify and the function below doesn't help!
# TODO: is this a bug?!
# modify(q::SpatialTreeNode, p::AbstractPoint, ::Type{Modify}) =
#     modify(q,p)
modify() = error("not implemented!")
function insert!(h::SpatialTree, point::AbstractPoint, ::Type{Modify})
    q = h.head
    while q.is_divided
        modify(q, point)
        q = _getsubnode(q, point)
    end
    while !q.is_empty
        const friend = q.point
        divide!(h, q)
        modify(q, friend)
        modify(q, point)
        q = _getsubnode(q, point)
    end
    q.point = point
    q.is_empty = false
    q
end

function insert!(h::SpatialTree, point::AbstractPoint, additional_data)
    q = h.head
    while q.is_divided
        modify(q, point, additional_data)
        q = _getsubnode(q, point)
    end
    while !q.is_empty
        const friend = q.point
        divide!(h, q)
        modify(q, friend, additional_data)
        modify(q, point, additional_data)
        q = _getsubnode(q, point)
    end
    q.point = point
    q.is_empty = false
    q
end

function insert!{T<:AbstractPoint}(h::SpatialTree, points::Array{T,1}, ::Type{Modify})
    hilbertsort!(points)
    for p in points
        insert!(h, p, Modify)
    end
end

# specific stuff for Quad or Oct trees

include("_octtrees.jl")
include("_compiled_octtrees.jl")
include("_quadtrees.jl")

map{T<:AbstractPoint2D}(h::QuadTree{T}) =
    map(h, No_Cond_Data)
map{T<:AbstractPoint3D}(h::OctTree{T}) =
    map(h, No_Cond_Data)

end # module

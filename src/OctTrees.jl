module OctTrees

using GeometricalPredicates

export
    QuadTree,
    insert!,
    clear!,
    eltype,
    Point,
    Point2D,
    Modify,
    modify,
    QuadTreeNode,
    map,
    No_Cond_Data,
    No_Apply_Data,
    AbstractPoint,
    AbstractPoint2D,
    AbstractPoint3D

# for compatibility reasons
if VERSION < v"0.4-"
    sizehint! = sizehint
end

# General stuff good for both Quad and Oct trees

abstract SpatialTree
abstract SpatialTreeNode

immutable Modify end
immutable No_Cond_Data end

modify(q::SpatialTreeNode, p::AbstractPoint, ::Type{Modify}) =
    modify(q,p)

stop_cond(q::SpatialTreeNode, ::Type{No_Cond_Data}) =
    stop_cond(q)

map(h::SpatialTree, cond_data=No_Cond_Data) =
    _map(h.head, cond_data)

function clear!(h::SpatialTree; init=true)
    h.head.is_divided = false
    h.head.is_empty = true
    h.number_of_nodes_used = 1
    if init
        h.head.point = eltype(h)()
        @inbounds for i in 1:length(h.nodes)
            h.nodes[i].point = eltype(h)()
            h.nodes[i].is_empty = true
            h.nodes[i].is_divided = false
        end
    end
    nothing
end

# specific stuff for Quad or Oct trees

include("_quadtrees.jl")
include("_octtrees.jl")

end # module

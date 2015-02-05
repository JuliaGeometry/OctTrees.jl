module OctTrees

export
	QuadTree,
	insert!,
	Point,
    Point2D,
    Modify,
    modify,
    QuadTreeNode,
    map,
    No_Cond_Data,
    No_Apply_Data

using GeometricalPredicates

# for compatibility reasons
if VERSION < v"0.4-"
	sizehint! = sizehint
end

# General stuff good for both Quad and Oct trees

abstract SpatialTree
abstract SpatialTreeNode

immutable Modify end
immutable No_Cond_Data end
immutable No_Apply_Data end

modify(q::SpatialTreeNode, p::AbstractPoint, ::Type{Modify}) = modify(q,p)

cond(q::SpatialTreeNode, ::No_Cond_Data, ::No_Apply_Data) = cond(q)
cond(q::SpatialTreeNode, cond_Data, ::No_Apply_Data) = cond(q, cond_data)
cond(q::SpatialTreeNode, ::No_Cond_Data, apply_data) = cond(q, apply_data)

apply(q::SpatialTreeNode, ::No_Cond_Data, ::No_Apply_Data) = apply(q)
apply(q::SpatialTreeNode, cond_Data, ::No_Apply_Data) = apply(q, cond_data)
apply(q::SpatialTreeNode, ::No_Cond_Data, apply_data) = apply(q, apply_data)

map(h::SpatialTree, cond_data=No_Cond_Data, apply_data=No_Apply_Data) =
    _map(h.head, cond_data, apply_data)

# specific stuff for Quad or Oct trees

include("_quadtrees.jl")
include("_octtrees.jl")

end # module

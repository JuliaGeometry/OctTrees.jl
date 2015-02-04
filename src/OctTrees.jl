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

include("_quadtrees.jl")
include("_octtrees.jl")

end # module

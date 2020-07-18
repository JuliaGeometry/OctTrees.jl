# OctTrees

[![Build Status](https://travis-ci.org/JuliaGeometry/OctTrees.jl.svg?branch=master)](https://travis-ci.org/JuliaGeometry/OctTrees.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaGeometry/OctTrees.jl/badge.svg?branch=master)](https://coveralls.io/r/JuliaGeometry/OctTrees.jl?branch=master)

A Julia library for [Quadtree](https://en.wikipedia.org/wiki/Quadtree) and [Octree](https://en.wikipedia.org/wiki/Octree) functionality.

**Original author**: [skariel](https://github.com/skariel)

Updated to at least v0.7

## Examples

```julia
#from `runtests.jl`

q = QuadTree(100)

OctTrees.insert!(q, Point(0.1, 0.1))
OctTrees.insert!(q, Point(0.9, 0.9))

q = OctTree(100)

OctTrees.insert!(q, Point(0.1, 0.1, 0.1))
OctTrees.insert!(q, Point(0.9, 0.9, 0.9))


```

## Similar packages

[RegionTrees.jl](https://github.com/rdeits/RegionTrees.jl)

[Octrees.jl](https://github.com/alainchau/Octrees.jl)
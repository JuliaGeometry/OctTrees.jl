using OctTrees
import OctTrees:modify, cond, apply
using GeometricalPredicates
import GeometricalPredicates:getx, gety
using Base.Test

q=QuadTree(100)

insert!(q, Point(0.1, 0.1))
insert!(q, Point(0.9, 0.9))

@test !q.head.lxhy.is_divided
@test q.head.lxhy.is_empty
@test !q.head.hxly.is_divided
@test q.head.hxly.is_empty
@test !q.head.lxly.is_divided
@test !q.head.lxly.is_empty
@test !q.head.hxhy.is_divided
@test !q.head.hxhy.is_empty
@test q.head.is_divided
@test q.head.is_empty

insert!(q, Point(0.55, 0.9))

@test !q.head.hxhy.hxhy.is_divided
@test !q.head.hxhy.hxhy.is_empty
@test !q.head.hxhy.lxhy.is_divided
@test !q.head.hxhy.lxhy.is_empty
@test !q.head.hxhy.lxly.is_divided
@test q.head.hxhy.lxly.is_empty
@test !q.head.hxhy.hxly.is_divided
@test q.head.hxhy.hxly.is_empty

insert!(q, Point(0.9, 0.55))

@test !q.head.hxhy.hxhy.is_divided
@test !q.head.hxhy.hxhy.is_empty
@test !q.head.hxhy.lxhy.is_divided
@test !q.head.hxhy.lxhy.is_empty
@test !q.head.hxhy.lxly.is_divided
@test q.head.hxhy.lxly.is_empty
@test !q.head.hxhy.hxly.is_divided
@test !q.head.hxhy.hxly.is_empty

pa = [Point(rand(), rand()) for i in 1:1000000]
function insert_unsorted_array(pa::Array{Point2D,1}, q::QuadTree)
	for p in pa
		insert!(q, p)
	end
end
q=QuadTree(100)
@time insert_unsorted_array(pa,q)

# a massive particle
type Particle <: AbstractPoint2D
	_x::Float64
	_y::Float64
	_m::Float64
	Particle(x,y,m) = new(x,y,m)
end
Particle(x::Float64, y::Float64) = Particle(x, y, 1.)
Particle() = Particle(0., 0., 0.)
getx(p::Particle) = p._x
gety(p::Particle) = p._y

q=QuadTree(Particle; n=100)

function modify(q::QuadTreeNode{Particle}, p::Particle)
	total_mass = q.point._m + p._m
	q.point._x = (q.point._x*q.point._m + p._x)/total_mass
	q.point._y = (q.point._y*q.point._m + p._y)/total_mass
	q.point._m = total_mass
end

@test q.head.is_empty == true

insert!(q, Particle(0.1, 0.1), Modify)

@test q.head.is_empty == false
@test q.head.point._m == 1.0
@test q.head.point._x == 0.1
@test q.head.point._y == 0.1

insert!(q, Particle(0.9, 0.9), Modify)

@test q.head.is_empty == true
@test q.head.point._m == 2.0
@test q.head.point._x == (0.1+0.9)/2
@test q.head.point._y == (0.1+0.9)/2
@test q.head.lxly.point._m == 1.0
@test q.head.lxly.point._x == 0.1
@test q.head.lxly.point._y == 0.1
@test q.head.hxhy.point._m == 1.0
@test q.head.hxhy.point._x == 0.9
@test q.head.hxhy.point._y == 0.9

function cond(q::QuadTreeNode{Particle}, cond_data::Int64, apply_data::Int64)
	q.point._m > 1.0
end

apply_called = false
function apply(q::QuadTreeNode{Particle}, cond_data::Int64, apply_data::Int64)
	global apply_called
	@test q.point._m == 2.0
	@test cond_data==1
	@test apply_data==2
	apply_called = true
end

map(q, 1, 2)

@test apply_called == true

q=QuadTree(Particle; n=100)

function modify(q::QuadTreeNode{Particle}, p::Particle, i::Int64)
	@test i==1
	q.point._m=7.0
end

insert!(q, Particle(0.1, 0.1), 1)
insert!(q, Particle(0.9, 0.9), 1)
@test q.head.point._m == 7.0




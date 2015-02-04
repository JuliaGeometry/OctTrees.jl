using OctTrees
using Base.Test

q=QuadTree()

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

@time insert_unsorted_array(pa,q)

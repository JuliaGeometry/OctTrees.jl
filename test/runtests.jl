using OctTrees
using Base.Test

q=QuadTree()

insert!(q, Point(0.1, 0.1))
insert!(q, Point(0.9, 0.9))

@test !q.lxhy.is_divided
@test q.lxhy.is_empty
@test !q.hxly.is_divided
@test q.hxly.is_empty
@test !q.lxly.is_divided
@test !q.lxly.is_empty
@test !q.hxhy.is_divided
@test !q.hxhy.is_empty
@test q.is_divided
@test q.is_empty

insert!(q, Point(0.55, 0.9))

@test !q.hxhy.hxhy.is_divided
@test !q.hxhy.hxhy.is_empty
@test !q.hxhy.lxhy.is_divided
@test !q.hxhy.lxhy.is_empty
@test !q.hxhy.lxly.is_divided
@test q.hxhy.lxly.is_empty
@test !q.hxhy.hxly.is_divided
@test q.hxhy.hxly.is_empty

insert!(q, Point(0.9, 0.55))

@test !q.hxhy.hxhy.is_divided
@test !q.hxhy.hxhy.is_empty
@test !q.hxhy.lxhy.is_divided
@test !q.hxhy.lxhy.is_empty
@test !q.hxhy.lxly.is_divided
@test q.hxhy.lxly.is_empty
@test !q.hxhy.hxly.is_divided
@test !q.hxhy.hxly.is_empty


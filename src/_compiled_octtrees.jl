immutable CompiledOctTreeNode{T<:AbstractPoint3D} <: SpatialTreeNode
    point::T
    l::Float64
    next::Int64
end

CompiledOctTreeNode{T<:AbstractPoint3D}(point::T, l::Float64, next::Int64) =
    CompiledOctTreeNode(point, l, next)

@inline CompiledOctTreeNode{T<:AbstractPoint3D}(n::OctTreeNode{T}, ct::CompiledOctTree{T}) =
        CompiledOctTreeNode(n.point, isleaf(n) ? -1.0 : 2.0*n.r, -1)

@inline withnext{T<:AbstractPoint3D}(cn::CompiledOctTreeNode{T}, next::Int64) =
    CompiledTreeNode(cn.point, cn.l, next)

type CompiledOctTree{T<:AbstractPoint3D} <: SpatialTree
    nodes::SharedArray{CompiledOctTreeNode{T}, 1}
    number_of_nodes_used::Int64
    faststack::Array{Int64, 1}
    CompiledOctTree(n::Int) = new(SharedArray(CompiledOctTreeNode{T}, 2*n), 0, Array(Int64, 10000))
end

@inline function stop_cond{T<:AbstractPoint3D}(q::OctTreeNode{T}, ct::CompiledOctTree{T})
    isemptyleaf(q) && return true # empty node, nothing to do
    ct.number_of_nodes_used += 1
    @inbounds ct.nodes[ct.number_of_nodes_used] = CompiledOctTreeNode(q, ct)
    q.id = ct.number_of_nodes_used
    return false
end

function compile{T<:AbstractPoint3D}(ct::CompiledOctTree{T}, t::OctTree{T})
    ct.number_of_nodes_used = 0
    map(t, ct)

    # fix neighbours
    for i in 1:t.number_of_nodes_used
        @inbounds const q=t.nodes[i]
        !q.is_divided && continue
        childs = (q.lxlylz, q.lxlyhz, q.lxhylz, q.lxhyhz, q.hxlylz, q.hxlyhz, q.hxhylz, q.hxhyhz)
        for a in 1:7
            @inbounds const qa = childs[a]
            qa.id <= 0 && continue
            # searching qa neighbor...
            qb = qa
            for b in (a+1):8
                @inbounds if childs[b].id > 0
                    qb = childs[b]
                    break
                end
            end
            is(qb,qa) && continue # no neighbor found lets leave next=-1
            # qa and qb are neighbors -- fix that in the compiled tree
            @inbounds ct.nodes[qb.id] = withnext(ct.nodes[qb.id], qa.id)
        end
    end
    ct
end

@inline function map{T<:AbstractPoint3D}(t::CompiledOctTree{T}, cond_data)
    curr_stack_ix = 1
    @inbounds t.faststack[1] = 1
    while curr_stack_ix > 0
        @inbounds node_ix = t.faststack[curr_stack_ix]
        curr_stack_ix -= 1
        @inbounds if node_ix>0 && node_ix<=t.number_of_nodes_used && !stop_cond(t.nodes[node_ix], cond_data)
            curr_stack_ix += 1
            next_ix = node_ix+1
            @inbounds t.faststack[curr_stack_ix] = next_ix
            while next_ix > 0
                curr_stack_ix += 1
                @inbounds next_ix = t.tree[next_ix].next
                @inbounds t.faststack[curr_stack_ix] = next_ix
            end
        end
    end
end

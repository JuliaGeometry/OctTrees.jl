struct CompiledOctTreeNode{T<:AbstractPoint3D} <: SpatialTreeNode
    point::T
    l::Float64
    next::Int64
end

CompiledOctTreeNode(point::T, l::Float64, next::Int64) where T <: AbstractPoint3D = CompiledOctTreeNode{T}(point, l, next)

CompiledOctTreeNode(n::OctTreeNode{T}) where T <: AbstractPoint3D =
        CompiledOctTreeNode{T}(n.point, isleaf(n) ? -1.0 : 2.0*n.r, -1)

withnext(cn::CompiledOctTreeNode{T}, next::Int64) where T<:AbstractPoint3D = CompiledOctTreeNode{T}(cn.point, cn.l, next)

mutable struct CompiledOctTree{T<:AbstractPoint3D} <: SpatialTree
    nodes::SharedArray{CompiledOctTreeNode{T}, 1}
    number_of_nodes_used::Int64
    faststack::Array{Int64, 1}
end
CompiledOctTree(n::Int64, ::Type{T}) where T <: AbstractPoint3D =
    CompiledOctTree{T}(SharedArray(CompiledOctTreeNode{T}, 2*n), 0, Array(Int64, 100000))

function stop_cond(q::OctTreeNode{T}, ct::CompiledOctTree{T}) where T <: AbstractPoint3D
    isemptyleaf(q) && return true # nothing to do
    ct.number_of_nodes_used += 1
    ct.nodes[ct.number_of_nodes_used] = CompiledOctTreeNode(q)
    q.id = ct.number_of_nodes_used
    return false
end

function compile!(ct::CompiledOctTree{T}, t::OctTree{T}) where T<:AbstractPoint3D
    ct.number_of_nodes_used = 0
    map(t, ct)
    childs = Array(OctTreeNode{T}, 8)

    # fix neighbours
    @inbounds for i in 1:t.number_of_nodes_used
        q=t.nodes[i]
        !q.is_divided && continue
        childs[1] = q.lxlylz
        childs[2] = q.lxlyhz
        childs[3] = q.lxhylz
        childs[4] = q.lxhyhz
        childs[5] = q.hxlylz
        childs[6] = q.hxlyhz
        childs[7] = q.hxhylz
        childs[8] = q.hxhyhz
        for a in 1:7
            qa = childs[a]
            qa.id <= 0 && continue
            # searching qa neighbor...
            qb = qa
            for b in (a+1):8
                if childs[b].id > 0
                    qb = childs[b]
                    break
                end
            end
            is(qb,qa) && continue # no neighbor found lets leave next=-1
            # qa and qb are neighbors -- fix that in the compiled tree
            ct.nodes[qb.id] = withnext(ct.nodes[qb.id], qa.id)
        end
    end
    ct
end

function map(t::CompiledOctTree{T}, cond_data) where T<:AbstractPoint3D
    curr_stack_ix = 1
    t.faststack[1] = 1
    @inbounds while curr_stack_ix > 0
        node_ix = t.faststack[curr_stack_ix]
        curr_stack_ix -= 1
        if node_ix>0 && node_ix<=t.number_of_nodes_used && !stop_cond(t.nodes[node_ix], cond_data)
            curr_stack_ix += 1
            next_ix = node_ix+1
            t.faststack[curr_stack_ix] = next_ix
            while next_ix > 0
                curr_stack_ix += 1
                next_ix = t.nodes[next_ix].next
                t.faststack[curr_stack_ix] = next_ix
            end
        end
    end
end

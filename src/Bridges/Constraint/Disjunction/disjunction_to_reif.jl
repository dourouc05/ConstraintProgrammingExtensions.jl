"""
Bridges `CP.Disjunction` to reification.
"""
struct Disjunction2ReificationBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_reif::Vector{MOI.ConstraintIndex}
    # Ideally, Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{<: MOI.AbstractSet}}}, 
    # but Julia has no notion of type erasure.
    con_disjunction::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Disjunction2ReificationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Disjunction{S},
) where {T, S}
    return MOIBC.bridge_constraint(
        Disjunction2ReificationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Disjunction2ReificationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Disjunction{S},
) where {T, S}
    vars, vars_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:length(s.constraints)])

    f_scalars = MOIU.scalarize(f)
    cons_reif = Vector{MOI.ConstraintIndex}(undef, length(s.constraints))
    cur_dim = 1
    for i in 1:length(s.constraints)
        cons_reif[i] = MOI.add_constraint(
            model,
            MOIU.vectorize(
                [
                    one(T) * MOI.SingleVariable(vars[i]),
                    f_scalars[cur_dim : (cur_dim + MOI.dimension(s.constraints[i]) - 1)]...,
                ]
            ),
            CP.Reified(s.constraints[i])
        )
        cur_dim += MOI.dimension(s.constraints[i])
    end

    con_disjunction = MOI.add_constraint(
        model, 
        sum(one(T) .* MOI.SingleVariable.(vars)),
        MOI.GreaterThan(one(T))
    )

    return Disjunction2ReificationBridge(vars, vars_bin, cons_reif, con_disjunction)
end

function MOI.supports_constraint(
    ::Type{Disjunction2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Disjunction{S}},
) where {T, S}
    return true
    # Ideally, ensure that the underlying solver supports all the needed 
    # reified constraints:
    # return all(MOI.supports_constraint(model, type, CP.Reified{C}) for C in S.parameters)
end

function MOIB.added_constrained_variable_types(::Type{Disjunction2ReificationBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Disjunction2ReificationBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.VectorAffineFunction{T}, CP.Reified), # TODO: how to be more precise?
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Disjunction2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Disjunction{S}},
) where {T, S}
    return Disjunction2ReificationBridge{T}
end

function MOI.get(b::Disjunction2ReificationBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars)
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_bin)
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Reified,
    },
) where {T}
    return length(b.cons_reif)
end

function MOI.get(
    ::Disjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return b.vars
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return b.vars_bin
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Reified,
    },
) where {T}
    return b.cons_reif
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return [b.con_disjunction]
end

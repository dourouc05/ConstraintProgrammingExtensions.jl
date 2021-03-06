_REIF_LT_FLOAT_EPSILON = 1.0e-5

"""
Bridges `CP.Reified{MOI.LessThan}` to MILP constraints.
"""
struct ReifiedLessThan2MILPBridge{T <: Real} <: MOIBC.AbstractBridge
    con_bigm::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
    con_smallm::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{ReifiedLessThan2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Reified{MOI.LessThan{T}},
) where {T}
    return MOIBC.bridge_constraint(
        ReifiedLessThan2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ReifiedLessThan2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Reified{MOI.LessThan{T}},
) where {T <: Real}
    f_scalars = MOIU.scalarize(f)

    # For this formulation work, both lower and upper bounds are required on
    # the constrained expression (but obviously not on the binary reified 
    # variable).
    @assert CP.is_binary(model, f_scalars[1])
    @assert CP.has_lower_bound(model, f_scalars[2])
    @assert CP.has_upper_bound(model, f_scalars[2])

    # If the reified expression is true/false, then the LessThan constraint 
    # must/cannot be satisfied. (If the constraint is satisfied, the reified 
    # expression is unconstrained.)
    bigm = T(max(
        abs(CP.get_upper_bound(model, f_scalars[2])), 
        abs(CP.get_lower_bound(model, f_scalars[2]))
    ))
    con_bigm = MOI.add_constraint(
        model, 
        f_scalars[2] - bigm * (one(T) - f_scalars[1]), 
        MOI.LessThan(s.set.upper)
    )

    # If the constraint is satisfied, constrain the reified. 
    smallm = if T <: Int
        one(T)
    else
        T(_REIF_LT_FLOAT_EPSILON)
    end

    con_smallm = MOI.add_constraint(
        model, 
        f_scalars[2] - bigm * f_scalars[1],
        MOI.GreaterThan(s.set.upper + smallm)
    )

    return ReifiedLessThan2MILPBridge{T}(con_bigm, con_smallm)
end

function MOI.supports_constraint(
    ::Type{ReifiedLessThan2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reified{MOI.LessThan{T}}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ReifiedLessThan2MILPBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{ReifiedLessThan2MILPBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, MOI.GreaterThan{T}),
        (MOI.VectorAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{ReifiedLessThan2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reified{MOI.LessThan{T}}},
) where {T <: Real}
    return ReifiedLessThan2MILPBridge{T}
end

function MOI.get(::ReifiedLessThan2MILPBridge{T}, ::MOI.NumberOfVariables) where {T <: Real}
    return 0
end

function MOI.get(
    ::ReifiedLessThan2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReifiedLessThan2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    b::ReifiedLessThan2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T <: Real}
    return [b.con_bigm]
end

function MOI.get(
    b::ReifiedLessThan2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T <: Real}
    return [b.con_smallm]
end

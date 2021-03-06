"""
Bridges `CP.FixedCapacityBinPacking` to `CP.VariableCapacityBinPacking` by creating 
capacity variables.
"""
struct FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T} <: MOIBC.AbstractBridge
    capa_var::Vector{MOI.VariableIndex}
    capa_con::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}}
    capa_bound::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{T}}}
    bp::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.VariableCapacityBinPacking{T}}
end

function MOIBC.bridge_constraint(
    ::Type{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.FixedCapacityBinPacking{T},
) where {T}
    return MOIBC.bridge_constraint(
        FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.FixedCapacityBinPacking{T},
) where {T <: Integer}
    # Add the capacity integer variables (because its values are ensured to 
    # be integers, T <: Integer).
    capa_var, capa_con = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:s.n_bins])

    # Add the capacity constraints.
    capa_bound = [MOI.add_constraint(model, capa_var[bin], MOI.LessThan(s.capacities[bin])) for bin in 1:s.n_bins]

    # Create the variable-capacity bin-packing constraint.
    f_scalars = MOIU.scalarize(f)
    new_f = MOIU.vectorize(
        MOI.ScalarAffineFunction{T}[
            f_scalars[1:s.n_bins]...,
            MOI.SingleVariable.(capa_var)...,
            f_scalars[s.n_bins+1:end]...
        ]
    )
    bp_set = CP.VariableCapacityBinPacking(s.n_bins, s.n_items, s.weights)
    bp = MOI.add_constraint(model, new_f, bp_set)

    return FixedCapacityBinPacking2VariableCapacityBinPackingBridge(capa_var, capa_con, capa_bound, bp)
end

function MOIBC.bridge_constraint(
    ::Type{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.FixedCapacityBinPacking{T},
) where {T <: Real}
    # Add the capacity variables, without integer constraint.
    capa_var = MOI.add_variables(model, s.n_bins)
    capa_con = MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}[]

    # Add the capacity constraints.
    capa_bound = [MOI.add_constraint(model, capa_var[bin], MOI.LessThan(s.capacities[bin])) for bin in 1:s.n_bins]

    # Create the variable-capacity bin-packing constraint.
    f_scalars = MOIU.scalarize(f)
    new_f = MOIU.vectorize(
        MOI.ScalarAffineFunction{T}[
            f_scalars[1:s.n_bins]...,
            MOI.SingleVariable.(capa_var)...,
            f_scalars[s.n_bins+1:end]...
        ]
    )
    bp_set = CP.VariableCapacityBinPacking(s.n_bins, s.n_items, s.weights)
    bp = MOI.add_constraint(model, new_f, bp_set)

    return FixedCapacityBinPacking2VariableCapacityBinPackingBridge(capa_var, capa_con, capa_bound, bp)
end

function MOI.supports_constraint(
    ::Type{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.FixedCapacityBinPacking{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:FixedCapacityBinPacking2VariableCapacityBinPackingBridge{<:Integer}})
    return [(MOI.Integer,)]
end

function MOIB.added_constrained_variable_types(::Type{<:FixedCapacityBinPacking2VariableCapacityBinPackingBridge{<:Real}})
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}}) where {T <: Integer}
    return [
        (MOI.VectorAffineFunction{T}, CP.FixedCapacityBinPacking{T}),
        (MOI.SingleVariable, MOI.Integer),
        (MOI.SingleVariable, MOI.LessThan{T}),
    ]
end

function MOIB.added_constraint_types(::Type{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, CP.FixedCapacityBinPacking{T}),
        (MOI.SingleVariable, MOI.LessThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.FixedCapacityBinPacking{T}},
) where {T}
    return FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}
end

function MOI.get(b::FixedCapacityBinPacking2VariableCapacityBinPackingBridge, ::MOI.NumberOfVariables)
    return length(b.capa_var)
end

function MOI.get(
    ::FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T},
        CP.VariableCapacityBinPacking{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable,
        MOI.Integer,
    },
) where {T}
    return length(b.capa_con)
end

function MOI.get(
    b::FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable,
        MOI.LessThan{T},
    },
) where {T}
    return length(b.capa_bound)
end

function MOI.get(
    b::FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return b.capa_var
end

function MOI.get(
    b::FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T},
        CP.VariableCapacityBinPacking{T},
    },
) where {T}
    return [b.bp]
end

function MOI.get(
    b::FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable,
        MOI.Integer,
    },
) where {T}
    return b.capa_con
end

function MOI.get(
    b::FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable,
        MOI.LessThan{T},
    },
) where {T}
    return b.capa_bound
end

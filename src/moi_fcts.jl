# Common supertype for all nonlinear functions.
abstract type AbstractNonlinearScalarFunction <: MOI.AbstractScalarFunction end
abstract type AbstractNonlinearVectorFunction <: MOI.AbstractVectorFunction end

const NL_SV_UNION = Union{MOI.SingleVariable, AbstractNonlinearScalarFunction}
const NL_SV_FCT = Union{
    AbstractNonlinearScalarFunction, 
    MOI.SingleVariable, 
    NL_SV_UNION
}

const NL_VEC_SV_UNION = Union{MOI.VectorOfVariables, AbstractNonlinearVectorFunction}
const NL_VEC_SV_FCT = Union{
    AbstractNonlinearVectorFunction, 
    MOI.VectorOfVariables, 
    NL_VEC_SV_UNION
}

# -----------------------------------------------------------------------------
# - Predicate support
# -----------------------------------------------------------------------------

# Common supertype for predicate constraints, those that return a Boolean 
# value. They should have a simplified syntax at JuMP level: 
#     @constraint(model, predicate(variables))
# Also at MOI level: 
#     MOI.add_constraint(model, predicate(variables))
abstract type AbstractNonlinearPredicate <: AbstractNonlinearScalarFunction end

# Overload add_constraint to provide better error messages in the case 
# of predicates.
function MOI.add_constraint(
    model::MOI.ModelLike,
    func::AbstractNonlinearPredicate,
)
    return MOI.throw_add_constraint_error_fallback(model, func)
end

# No need for an indirection level at throw_add_constraint_error_fallback, 
# no need to check "vectorness" compatibility. Thus, only go for 
# correct_throw_add_constraint_error_fallback.
function MOI.throw_add_constraint_error_fallback(
    model::MOI.ModelLike,
    func::AbstractNonlinearPredicate,
    error_if_supported = AddPredicateNotAllowed{typeof(func)}(),
)
    if supports_constraint(model, typeof(func))
        throw(error_if_supported)
    else
        throw(UnsupportedPredicate{typeof(func)}())
    end
end

"""
    struct UnsupportedPredicate{F<:AbstractNonlinearPredicate} <: MOI.UnsupportedError
        message::String # Human-friendly explanation why the attribute cannot be set
    end

An error indicating that predicates of type `F` are not supported by
the model, i.e. that [`supports_constraint`](@ref) returns `false`.
"""
struct UnsupportedPredicate{F <: AbstractNonlinearPredicate} <: MOI.UnsupportedError
    message::String # Human-friendly explanation why the attribute cannot be set
end
UnsupportedPredicate{F}() where {F} = UnsupportedPredicate{F}("")

function element_name(::UnsupportedPredicate{F}) where {F}
    return "`$F` predicate"
end

"""
    struct AddPredicateNotAllowed{F<:AbstractNonlinearPredicate} <: MOI.NotAllowedError
        message::String # Human-friendly explanation why the attribute cannot be set
    end

An error indicating that predicates of type `F` are supported (see
[`supports_constraint`](@ref)) but cannot be added.
"""
struct AddPredicateNotAllowed{F <: AbstractNonlinearPredicate} <:
       MOI.NotAllowedError
    message::String # Human-friendly explanation why the attribute cannot be set
end
AddPredicateNotAllowed{F}() where {F} = AddPredicateNotAllowed{F}("")

function operation_name(::AddPredicateNotAllowed{F}) where {F}
    return "Adding `$F` predicates"
end


# -----------------------------------------------------------------------------
# - Affine expressions of nonlinear terms, inspired by MOI.ScalarAffineFunction
# - These generalise quadratic expressions too.
# -----------------------------------------------------------------------------

struct NonlinearScalarAffineTerm{T <: Real, F <: NL_SV_FCT}
    coefficient::T
    expr::F

    function NonlinearScalarAffineTerm(coefficient::T, expr::F) where {T <: Real, F <: NL_SV_FCT}
        return new{T, F}(coefficient, expr)
    end

    function NonlinearScalarAffineTerm(coefficient::T, expr::F, ::Bool) where {T <: Real, F <: NL_SV_FCT}
        # Really poor trick... 
        return new{T, NL_SV_FCT}(coefficient, expr)
    end

    function NonlinearScalarAffineTerm(expr::F) where {F <: NL_SV_FCT}
        return new{Float64, F}(1.0, expr)
    end
end

function copy(t::NonlinearScalarAffineTerm{T, F}) where {T <: Real, F <: NL_SV_FCT}
    return NonlinearScalarAffineTerm(copy(t.coefficient), copy(t.expr))
end

function convert(::Type{NonlinearScalarAffineTerm{T, NL_SV_UNION}}, t::NonlinearScalarAffineTerm{T, <: NL_SV_FCT}) where {T <: Real}
    # Useful to merge two arrays of terms with different kinds of functions.
    return NonlinearScalarAffineTerm(t.coefficient, t.expr, false)
end


mutable struct NonlinearScalarAffineFunction{T <: Real, F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    terms::Vector{NonlinearScalarAffineTerm{T, F}}
    constant::T

    function NonlinearScalarAffineFunction(terms::Vector{NonlinearScalarAffineTerm{T, F}}, constant::T) where {T <: Real, F <: NL_SV_FCT}
        return new{T, F}(terms, constant)
    end

    function NonlinearScalarAffineFunction(terms::Vector{NonlinearScalarAffineTerm{T, <: NL_SV_FCT}}, constant::T) where {T <: Real}
        return new{T, NL_SV_UNION}(terms, constant)
    end

    function NonlinearScalarAffineFunction(terms::Vector{NonlinearScalarAffineTerm}, constant::T) where {T <: Real}
        return new{T, NL_SV_UNION}(terms, constant)
    end

    function NonlinearScalarAffineFunction(terms::Vector{NonlinearScalarAffineTerm{T, F}}) where {T <: Real, F <: NL_SV_FCT}
        return NonlinearScalarAffineFunction(terms, one(T))
    end
end

function copy(f::NonlinearScalarAffineFunction{T}) where {T <: Real}
    return NonlinearScalarAffineFunction(copy.(f.terms), copy(f.constant))
end

# -----------------------------------------------------------------------------
# - Geometric programming
# -----------------------------------------------------------------------------

# Aka monomial.
# Division: exponent -1.0.
# Square root: exponent 0.5.
struct NonlinearScalarFactor{T <: Real, F <: NL_SV_FCT}
    exponent::T
    expr::F

    function NonlinearScalarFactor(exponent::T, expr::F) where {T <: Real, F <: NL_SV_FCT}
        return new{T, F}(exponent, expr)
    end

    function NonlinearScalarFactor(exponent::T, expr::F, ::Bool) where {T <: Real, F <: NL_SV_FCT}
        # Really poor trick... 
        return new{T, NL_SV_FCT}(exponent, expr)
    end

    function NonlinearScalarFactor(expr::F) where {F <: NL_SV_FCT}
        return new{Float64, F}(1.0, expr)
    end
end

function copy(f::NonlinearScalarFactor{T, F}) where {T <: Real, F <: NL_SV_FCT}
    return NonlinearScalarFactor(copy(f.exponent), copy(f.expr))
end

function convert(::Type{NonlinearScalarFactor{T, NL_SV_UNION}}, t::NonlinearScalarFactor{T, <: NL_SV_FCT}) where {T <: Real}
    # Useful to merge two arrays of terms with different kinds of functions.
    return NonlinearScalarFactor(t.coefficient, t.expr, false)
end


# Posynomial if the constant is > 0, signomial otherwise.
mutable struct NonlinearScalarProductFunction{T <: Real, F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    factors::Vector{NonlinearScalarFactor{T, F}}
    constant::T

    function NonlinearScalarProductFunction(factors::Vector{NonlinearScalarFactor{T, F}}, constant::T) where {T <: Real, F <: NL_SV_FCT}
        return new{T, F}(factors, constant)
    end

    function NonlinearScalarProductFunction(factors::Vector{NonlinearScalarFactor{T, <: NL_SV_FCT}}, constant::T) where {T <: Real}
        return new{T, NL_SV_UNION}(factors, constant)
    end

    function NonlinearScalarProductFunction(factors::Vector{NonlinearScalarFactor}, constant::T) where {T <: Real}
        return new{T, NL_SV_UNION}(factors, constant)
    end

    function NonlinearScalarProductFunction(factors::Vector{NonlinearScalarFactor{T, F}}) where {T <: Real, F <: NL_SV_FCT}
        return NonlinearScalarProductFunction(factors, one(T))
    end
end

function copy(f::NonlinearScalarProductFunction{T, F}) where {T <: Real, F <: NL_SV_FCT}
    return NonlinearScalarProductFunction(copy.(f.factors), copy(f.constant))
end

# -----------------------------------------------------------------------------
# - Usual nonlinear combinations of functions
# -----------------------------------------------------------------------------

struct AbsoluteValueFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

function copy(f::AbsoluteValueFunction{F}) where {F <: NL_SV_FCT}
    return AbsoluteValueFunction(copy(f.expr))
end


struct ExponentialFunction{T <: Real, F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    exponent::T
    expr::F
end

function ExponentialFunction(expr::F) where {F <: NL_SV_FCT}
    return ExponentialFunction{Float64, F}(ℯ, expr)
end

function copy(f::ExponentialFunction{T, F}) where {T <: Real, F <: NL_SV_FCT}
    return ExponentialFunction(copy(f.exponent), copy(f.expr))
end


struct LogarithmFunction{T <: Real, F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    base::T
    expr::F
end

function LogarithmFunction(expr::F) where {F <: NL_SV_FCT}
    return LogarithmFunction{Float64, F}(ℯ, expr)
end

function copy(f::LogarithmFunction{T, F}) where {T <: Real, F <: NL_SV_FCT}
    return LogarithmFunction(copy(f.base), copy(f.expr))
end

# -----------------------------------------------------------------------------
# - Trigonometry
# -----------------------------------------------------------------------------

struct CosineFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct SineFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct TangentFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct ArcCosineFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct ArcSineFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct ArcTangentFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct HyperbolicCosineFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct HyperbolicSineFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct HyperbolicTangentFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct HyperbolicArcCosineFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct HyperbolicArcSineFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

struct HyperbolicArcTangentFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    expr::F
end

function copy(f::F) where {F <: Union{
    CosineFunction, SineFunction, TangentFunction, 
    ArcCosineFunction, ArcSineFunction, ArcTangentFunction, 
    HyperbolicCosineFunction, HyperbolicSineFunction, HyperbolicTangentFunction, 
    HyperbolicArcCosineFunction, HyperbolicArcSineFunction, HyperbolicArcTangentFunction,
}}
    return F(copy(f.expr))
end

# -----------------------------------------------------------------------------
# - Nicer interface to some functions
# -----------------------------------------------------------------------------

function ProductFunction(fs::F...) where {F <: NL_SV_FCT}
    factors = [NonlinearScalarFactor(f) for f in fs]
    return NonlinearScalarProductFunction(factors)
end

function SquareRootFunction(expr::F) where {F <: NL_SV_FCT}
    factor = NonlinearScalarFactor(0.5, expr)
    return NonlinearScalarProductFunction([factor])
end

function InverseFunction(expr::F) where {F <: NL_SV_FCT}
    factor = NonlinearScalarFactor(-1.0, expr)
    return NonlinearScalarProductFunction([factor])
end

# -----------------------------------------------------------------------------
# - Relations with linear/quadratic types of MOI
# -----------------------------------------------------------------------------

function NonlinearScalarAffineTerm(term::MOI.ScalarAffineTerm{T}) where {T <: Real}
    return NonlinearScalarAffineTerm(term.coefficient, MOI.SingleVariable(term.variable_index))
end

function NonlinearScalarAffineFunction(fct::MOI.ScalarAffineFunction{T}) where {T <: Real}
    return NonlinearScalarAffineFunction(NonlinearScalarAffineTerm.(fct.terms), fct.constant)
end

function NonlinearScalarAffineTerm(term::MOI.ScalarQuadraticTerm{T}) where {T <: Real}
    f1 = MOI.SingleVariable(term.variable_index_1)
    f2 = MOI.SingleVariable(term.variable_index_2)
    prod = ProductFunction(f1, f2)
    return NonlinearScalarAffineTerm(term.coefficient, prod)
end

function NonlinearScalarAffineFunction(fct::MOI.ScalarQuadraticFunction{T}) where {T <: Real}
    terms = [NonlinearScalarAffineTerm(x) for x in vcat(fct.affine_terms, fct.quadratic_terms)]
    return NonlinearScalarAffineFunction(terms, fct.constant)
end

# -----------------------------------------------------------------------------
# - Reification
# -----------------------------------------------------------------------------

struct EquivalenceFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f1::F
    f2::G
end

struct IfThenElseFunction{F <: NL_SV_FCT, G <: NL_SV_FCT, H <: NL_SV_FCT} <: AbstractNonlinearPredicate
    condition::F
    true_constraint::G
    false_constraint::H
end

struct ImplyFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearPredicate
    antecedent::F
    consequent::G
end

struct ConjunctionFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    conditions::Vector{<:F}
end

struct DisjunctionFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    conditions::Vector{<:F}
end

struct NegationFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    condition::F
end

struct TrueFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
end

struct FalseFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
end

# -----------------------------------------------------------------------------
# - Sorting
# -----------------------------------------------------------------------------

struct LexicographicallyLessThanFunction{F <: NL_SV_FCT} <: AbstractNonlinearVectorFunction
    f::Vector{<:F}
end

struct LexicographicallyGreaterThanFunction{F <: NL_SV_FCT} <: AbstractNonlinearVectorFunction
    f::Vector{<:F}
end

struct SortFunction{F <: NL_SV_FCT} <: AbstractNonlinearVectorFunction
    f::Vector{<:F}
end

struct PermutationSortFunction{F <: NL_SV_FCT} <: AbstractNonlinearVectorFunction
    f::Vector{<:F}
end

struct MinimumAmongFunction{F <: NL_SV_FCT} <: AbstractNonlinearVectorFunction
    f::Vector{<:F}
end

struct MaximumAmongFunction{F <: NL_SV_FCT} <: AbstractNonlinearVectorFunction
    f::Vector{<:F}
end

struct IsArgumentMinimumAmongFunction{F <: NL_SV_FCT} <: AbstractNonlinearVectorFunction
    f::Vector{<:F}
end

struct ArgumentMaximumAmongFunction{F <: NL_SV_FCT} <: AbstractNonlinearVectorFunction
    f::Vector{<:F}
end

struct IsIncreasingFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsDecreasingFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

# -----------------------------------------------------------------------------
# - Graphs
# -----------------------------------------------------------------------------

struct IsCircuitFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsCircuitPathFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

# -----------------------------------------------------------------------------
# - Combinatorial
# -----------------------------------------------------------------------------

struct IsBinPackingFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
    n_bins::Int
    n_items::Int
end

struct IsCapacitatedBinPackingFunction{F <: NL_SV_FCT, G <: Union{NL_SV_FCT, Real}, T <: Real} <: AbstractNonlinearPredicate
    bins::Vector{<:F}
    capacity::Vector{<:G}
    n_bins::Int
    n_items::Int
    weights::Vector{T}
end

struct IsKnapsackFunction{F <: NL_SV_FCT, G <: Union{NL_SV_FCT, Real}, T <: Real} <: AbstractNonlinearPredicate
    in_knapsack::Vector{<:F}
    capacity::G
    weights::Vector{T}
end


MOIU.@model(
    MILPModel,
    (),
    (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval),
    (
        MOI.Zeros,
        MOI.Nonnegatives,
        MOI.Nonpositives,
        MOI.NormInfinityCone,
        MOI.NormOneCone,
        MOI.SecondOrderCone,
        MOI.RotatedSecondOrderCone,
        MOI.GeometricMeanCone,
        MOI.RelativeEntropyCone,
        MOI.NormSpectralCone,
        MOI.NormNuclearCone,
        MOI.PositiveSemidefiniteConeTriangle,
        MOI.ExponentialCone,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    BinPackingModel,
    (),
    (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval),
    (
        MOI.Zeros,
        MOI.Nonnegatives,
        MOI.Nonpositives,
        MOI.NormInfinityCone,
        MOI.NormOneCone,
        MOI.SecondOrderCone,
        MOI.RotatedSecondOrderCone,
        MOI.GeometricMeanCone,
        MOI.RelativeEntropyCone,
        MOI.NormSpectralCone,
        MOI.NormNuclearCone,
        MOI.PositiveSemidefiniteConeTriangle,
        MOI.ExponentialCone,
    ),
    (MOI.PowerCone, MOI.DualPowerCone, CP.BinPacking),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    VariableCapacityBinPackingModel,
    (),
    (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval),
    (
        MOI.Zeros,
        MOI.Nonnegatives,
        MOI.Nonpositives,
        MOI.NormInfinityCone,
        MOI.NormOneCone,
        MOI.SecondOrderCone,
        MOI.RotatedSecondOrderCone,
        MOI.GeometricMeanCone,
        MOI.RelativeEntropyCone,
        MOI.NormSpectralCone,
        MOI.NormNuclearCone,
        MOI.PositiveSemidefiniteConeTriangle,
        MOI.ExponentialCone,
    ),
    (MOI.PowerCone, MOI.DualPowerCone, CP.VariableCapacityBinPacking),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    VariableCapacityKnapsackModel,
    (),
    (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval),
    (
        MOI.Zeros,
        MOI.Nonnegatives,
        MOI.Nonpositives,
        MOI.NormInfinityCone,
        MOI.NormOneCone,
        MOI.SecondOrderCone,
        MOI.RotatedSecondOrderCone,
        MOI.GeometricMeanCone,
        MOI.RelativeEntropyCone,
        MOI.NormSpectralCone,
        MOI.NormNuclearCone,
        MOI.PositiveSemidefiniteConeTriangle,
        MOI.ExponentialCone,
    ),
    (MOI.PowerCone, MOI.DualPowerCone, CP.VariableCapacityKnapsack),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

function reified_singlevariable_test(
    model::MOI.ModelLike,
    config::MOIT.TestConfig,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.EqualTo{Int})
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        CP.Reified{MOI.EqualTo{Int}},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x2, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, _vov([x1, x2]), CP.Reified(MOI.EqualTo(2)))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 0
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 1
    end
end

function reified_scalaraffinefunction_test(
    model::MOI.ModelLike,
    config::MOIT.TestConfig,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{Int},
        CP.Reified{MOI.EqualTo{Int}},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, _saf(x2), MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, _vaf([x1, x2]), CP.Reified(MOI.EqualTo(2)))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 0
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 1
    end
end

const reifiedtests = Dict(
    "reified_singlevariable" => reified_singlevariable_test,
    "reified_scalaraffinefunction" => reified_scalaraffinefunction_test,
)

MOIT.@moitestset reified

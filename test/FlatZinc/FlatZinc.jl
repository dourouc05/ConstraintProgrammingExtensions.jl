@testset "FlatZinc" begin
    @testset "Model" begin
        @testset "Optimiser attributes" begin
            m = CP.FlatZinc.Optimizer()
            @test sprint(show, m) == "A FlatZinc (fzn) model"
        end

        @testset "Supported constraints" begin
            m = CP.FlatZinc.Optimizer()

            @test MOI.supports_constraint(
                m,
                MOI.SingleVariable,
                MOI.LessThan{Int},
            )
            @test MOI.supports_constraint(
                m,
                MOI.SingleVariable,
                MOI.LessThan{Float64},
            )
            @test MOI.supports_constraint(
                m,
                MOI.SingleVariable,
                CP.Strictly{MOI.LessThan{Float64}},
            )
            @test MOI.supports_constraint(m, MOI.SingleVariable, CP.Domain{Int})
            @test MOI.supports_constraint(
                m,
                MOI.SingleVariable,
                MOI.Interval{Float64},
            )
            @test MOI.supports_constraint(
                m,
                MOI.VectorOfVariables,
                CP.Element{Int},
            )
            @test MOI.supports_constraint(
                m,
                MOI.VectorOfVariables,
                CP.Element{Bool},
            )
            @test MOI.supports_constraint(
                m,
                MOI.VectorOfVariables,
                CP.Element{Float64},
            )
            @test MOI.supports_constraint(
                m,
                MOI.VectorOfVariables,
                CP.MaximumAmong,
            )
            @test MOI.supports_constraint(
                m,
                MOI.VectorOfVariables,
                CP.MinimumAmong,
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Int},
                MOI.EqualTo{Int},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Int},
                MOI.LessThan{Int},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Int},
                CP.DifferentFrom{Int},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Float64},
                MOI.LessThan{Float64},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Float64},
                CP.Strictly{MOI.LessThan{Float64}},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Float64},
                CP.DifferentFrom{Float64},
            )
        end

        @testset "Supported constrained variable with $(S)" for S in [
            MOI.EqualTo{Float64},
            MOI.LessThan{Float64},
            MOI.GreaterThan{Float64},
            MOI.Interval{Float64},
            MOI.EqualTo{Int},
            MOI.LessThan{Int},
            MOI.GreaterThan{Int},
            MOI.Interval{Int},
            MOI.EqualTo{Bool},
            MOI.ZeroOne,
            MOI.Integer,
        ]
            m = CP.FlatZinc.Optimizer()
            @test MOI.supports_add_constrained_variables(m, S)
        end
    end

    @testset "Writing" begin
        @testset "Variables" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            a, a_c = MOI.add_constrained_variable(m, MOI.GreaterThan(0.0))
            b, b_c = MOI.add_constrained_variable(m, MOI.LessThan(0.0))
            c, c_c = MOI.add_constrained_variable(m, MOI.EqualTo(0.0))
            d, d_c = MOI.add_constrained_variable(m, MOI.Interval(0.0, 1.0))
            e, e_c = MOI.add_constrained_variable(m, MOI.GreaterThan(0))
            f, f_c = MOI.add_constrained_variable(m, MOI.LessThan(0))
            g, g_c = MOI.add_constrained_variable(m, MOI.EqualTo(0))
            h, h_c = MOI.add_constrained_variable(m, MOI.Interval(0, 1))
            i, i_c = MOI.add_constrained_variable(m, MOI.EqualTo(false))
            j = MOI.add_variable(m)

            @test MOI.is_valid(m, a)
            @test MOI.is_valid(m, a_c)
            @test MOI.is_valid(m, b)
            @test MOI.is_valid(m, b_c)
            @test MOI.is_valid(m, c)
            @test MOI.is_valid(m, c_c)
            @test MOI.is_valid(m, d)
            @test MOI.is_valid(m, d_c)
            @test MOI.is_valid(m, e)
            @test MOI.is_valid(m, e_c)
            @test MOI.is_valid(m, f)
            @test MOI.is_valid(m, f_c)
            @test MOI.is_valid(m, g)
            @test MOI.is_valid(m, g_c)
            @test MOI.is_valid(m, h)
            @test MOI.is_valid(m, h_c)
            @test MOI.is_valid(m, i)
            @test MOI.is_valid(m, i_c)
            @test MOI.is_valid(m, j)

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var 0.0..1.7976931348623157e308: x1;
                var -1.7976931348623157e308..0.0: x2;
                var float: x3 = 0.0;
                var 0.0..1.0: x4;
                var 0..9223372036854775807: x5;
                var -9223372036854775808..0: x6;
                var int: x7 = 0;
                var 0..1: x8;
                var bool: x9 = false;
                var float: x10;
                
                
                
                
                solve satisfy;
                """
        end

        @testset "Constraints: CP.MinimumAmong / CP.MaximumAmong" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variables.
            x, x_int =
                MOI.add_constrained_variables(m, [MOI.Integer() for _ in 1:5])
            y = MOI.add_variables(m, 5)

            @test !MOI.is_empty(m)
            for i in 1:5
                @test MOI.is_valid(m, x[i])
                @test MOI.is_valid(m, x_int[i])
                @test MOI.is_valid(m, y[i])
            end

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints.
            c1 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables([x[1], x[2], x[3]]),
                CP.MaximumAmong(2),
            )
            c2 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(x),
                CP.MinimumAmong(4),
            )
            c3 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables([y[1], y[2], y[3]]),
                CP.MaximumAmong(2),
            )
            c4 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(y),
                CP.MinimumAmong(4),
            )

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)

            # Test some attributes for these constraints.
            @test MOI.get(m, MOI.ConstraintFunction(), c1) ==
                  MOI.VectorOfVariables([x[1], x[2], x[3]])
            @test MOI.get(m, MOI.ConstraintSet(), c1) == CP.MaximumAmong(2)
            @test MOI.get(
                m,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    CP.Element{Int},
                }(),
            ) == MOI.ConstraintIndex[]
            @test MOI.get(
                m,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    CP.MaximumAmong,
                }(),
            ) == [c1, c3]
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 3

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                var int: x2;
                var int: x3;
                var int: x4;
                var int: x5;
                var float: x6;
                var float: x7;
                var float: x8;
                var float: x9;
                var float: x10;
                
                
                
                constraint array_int_maximum(x1, [x2, x3]);
                constraint array_int_minimum(x1, [x2, x3, x4, x5]);
                constraint array_float_maximum(x6, [x7, x8]);
                constraint array_float_minimum(x6, [x7, x8, x9, x10]);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in x
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.Element" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variables.
            x, x_int =
                MOI.add_constrained_variables(m, [MOI.Integer() for _ in 1:2])
            y, y_bool =
                MOI.add_constrained_variables(m, [MOI.ZeroOne() for _ in 1:2])
            z = MOI.add_variables(m, 2)

            @test !MOI.is_empty(m)
            for i in 1:2
                @test MOI.is_valid(m, x[i])
                @test MOI.is_valid(m, x_int[i])
                @test MOI.is_valid(m, y[i])
                @test MOI.is_valid(m, y_bool[i])
                @test MOI.is_valid(m, z[i])
            end

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints.
            c1 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(x),
                CP.Element([6, 5, 4]),
            )
            c2 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(y),
                CP.Element([true, false]),
            )
            c3 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(z),
                CP.Element([1.0, 2.0]),
            )

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)

            # Test some attributes for these constraints.
            @test MOI.get(m, MOI.ConstraintFunction(), c1) ==
                  MOI.VectorOfVariables(x)
            @test MOI.get(m, MOI.ConstraintSet(), c1) == CP.Element([6, 5, 4])
            @test MOI.get(
                m,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    CP.Element{Int},
                }(),
            ) == [c1]
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 5

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                var int: x2;
                var bool: x3;
                var bool: x4;
                var float: x5;
                var float: x6;
                
                
                array [1..3] of int: ARRAY0 = [6, 5, 4];
                array [1..2] of bool: ARRAY1 = [true, false];
                array [1..2] of float: ARRAY2 = [1.0, 2.0];
                
                constraint array_int_element(x2, ARRAY0, x1);
                constraint array_bool_element(x4, ARRAY1, x3);
                constraint array_float_element(x6, ARRAY2, x5);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x..., y..., z...]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.DifferentFrom" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variables.
            x, x_int =
                MOI.add_constrained_variables(m, [MOI.Integer() for _ in 1:2])
            y = MOI.add_variables(m, 2)

            @test !MOI.is_empty(m)
            for i in 1:2
                @test MOI.is_valid(m, x[i])
                @test MOI.is_valid(m, x_int[i])
                @test MOI.is_valid(m, y[i])
            end

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints.
            c1 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], x), 0),
                CP.DifferentFrom(2),
            )
            c2 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 2.0], y),
                    0.0,
                ),
                CP.DifferentFrom(2.0),
            )

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)

            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 3

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                var int: x2;
                var float: x3;
                var float: x4;
                
                

                constraint int_lin_ne([1, 1], [x1, x2], 2);
                constraint float_lin_ne([1.0, 2.0], [x3, x4], 2.0);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x..., y...]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.Domain" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variable.
            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_int)

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Create constraint.
            c = MOI.add_constraint(m, x, CP.Domain(Set([0, 1, 2])))
            @test MOI.is_valid(m, c)

            # Test some attributes for this constraint.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 2

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                
                set of int: SET0 = {0, 2, 1};
                
                
                constraint set_in(x1, SET0);
                
                solve satisfy;
                """

            # Test that the name has been correctly transformed.
            xn = MOI.get(m, MOI.VariableName(), x)
            @test match(r"^x\d+$", xn) !== nothing
        end

        @testset "Constraints: CP.Interval" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variable.
            x = MOI.add_variable(m)
            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Create constraint.
            c = MOI.add_constraint(m, x, MOI.Interval(1.0, 2.0))
            @test MOI.is_valid(m, c)

            # Test some attributes for this constraint.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 1

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var float: x1;
                
                
                
                constraint float_in(x1, 1.0, 2.0);
                
                solve satisfy;
                """

            # Test that the name has been correctly transformed.
            xn = MOI.get(m, MOI.VariableName(), x)
            @test match(r"^x\d+$", xn) !== nothing
        end

        @testset "Constraints: MOI.ScalarAffineFunction in MOI.EqualTo / MOI.LessThan / CP.Strictly{MOI.LessThan} / CP.DifferentFrom" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variables.
            x, x_int =
                MOI.add_constrained_variables(m, [MOI.Integer() for _ in 1:2])
            y, y_bool =
                MOI.add_constrained_variables(m, [MOI.ZeroOne() for _ in 1:2])
            z = MOI.add_variables(m, 2)

            @test !MOI.is_empty(m)
            for i in 1:2
                @test MOI.is_valid(m, x[i])
                @test MOI.is_valid(m, x_int[i])
                @test MOI.is_valid(m, y[i])
                @test MOI.is_valid(m, y_bool[i])
                @test MOI.is_valid(m, z[i])
            end

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints.
            c1 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], x), 0),
                MOI.EqualTo(2),
            )
            c2 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], x), 0),
                MOI.LessThan(2),
            )
            c3 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], y), 0),
                MOI.EqualTo(true),
            )
            c4 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], y), 0),
                MOI.EqualTo(0),
            )
            c5 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 2.0], z),
                    0.0,
                ),
                MOI.EqualTo(2.0),
            )
            c6 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 2.0], z),
                    0.0,
                ),
                MOI.LessThan(2.0),
            )
            c7 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 2.0], z),
                    0.0,
                ),
                CP.Strictly(MOI.LessThan(2.0)),
            )
            c8 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], y), 0),
                CP.DifferentFrom(true),
            )
            c9 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 1.0], z),
                    0.0,
                ),
                CP.DifferentFrom(1.0),
            )
            c10 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], x), 0),
                CP.DifferentFrom(1),
            )
            c11 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], y), 0),
                MOI.LessThan(1),
            )

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)
            @test MOI.is_valid(m, c5)
            @test MOI.is_valid(m, c6)
            @test MOI.is_valid(m, c7)
            @test MOI.is_valid(m, c8)
            @test MOI.is_valid(m, c9)
            @test MOI.is_valid(m, c10)
            @test MOI.is_valid(m, c11)

            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 11

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                var int: x2;
                var bool: x3;
                var bool: x4;
                var float: x5;
                var float: x6;
                
                
                
                constraint int_lin_eq([1, 1], [x1, x2], 2);
                constraint int_lin_le([1, 1], [x1, x2], 2);
                constraint bool_lin_eq([1, 1], [x3, x4], 1);
                constraint bool_lin_eq([1, 1], [x3, x4], 0);
                constraint float_lin_eq([1.0, 2.0], [x5, x6], 2.0);
                constraint float_lin_le([1.0, 2.0], [x5, x6], 2.0);
                constraint float_lin_lt([1.0, 2.0], [x5, x6], 2.0);
                constraint int_lin_ne([1, 1], [x3, x4], 1);
                constraint float_lin_ne([1.0, 1.0], [x5, x6], 1.0);
                constraint int_lin_ne([1, 1], [x1, x2], 1);
                constraint bool_lin_le([1, 1], [x3, x4], 1);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x..., y..., z...]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: MOI.SingleVariable of integer in MOI.EqualTo / MOI.LessThan / CP.Strictly{MOI.LessThan} / CP.DifferentFrom" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variable.
            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
            y, y_bool = MOI.add_constrained_variable(m, MOI.ZeroOne())

            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_int)
            @test MOI.is_valid(m, y)
            @test MOI.is_valid(m, y_bool)

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints. 
            c1 = MOI.add_constraint(m, x, MOI.EqualTo(4))
            c2 = MOI.add_constraint(m, y, MOI.EqualTo(false))
            c3 = MOI.add_constraint(m, y, MOI.EqualTo(1)) # 1 will be cast to true.
            c4 = MOI.add_constraint(m, x, MOI.LessThan(2))
            c5 = MOI.add_constraint(m, y, MOI.LessThan(true))
            c6 = MOI.add_constraint(m, x, CP.Strictly(MOI.LessThan(2)))
            c7 = MOI.add_constraint(m, y, CP.Strictly(MOI.LessThan(true)))
            c8 = MOI.add_constraint(m, x, CP.DifferentFrom(2))
            c9 = MOI.add_constraint(m, y, CP.DifferentFrom(false))

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)
            @test MOI.is_valid(m, c5)
            @test MOI.is_valid(m, c6)
            @test MOI.is_valid(m, c7)
            @test MOI.is_valid(m, c8)
            @test MOI.is_valid(m, c9)

            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 10

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                var bool: x2;
                
                
                
                constraint int_eq(x1, 4);
                constraint bool_eq(x2, false);
                constraint bool_eq(x2, true);
                constraint int_le(x1, 2);
                constraint bool_le(x2, true);
                constraint int_lt(x1, 2);
                constraint bool_lt(x2, true);
                constraint int_ne(x1, 2);
                constraint int_ne(x2, false);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x, y]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: MOI.SingleVariable of float in MOI.EqualTo / MOI.LessThan / CP.Strictly{MOI.LessThan} / CP.DifferentFrom" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variable.
            x = MOI.add_variable(m)

            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints. 
            c1 = MOI.add_constraint(m, x, MOI.EqualTo(5.0))
            c2 = MOI.add_constraint(m, x, MOI.LessThan(5.0))
            c3 = MOI.add_constraint(m, x, CP.Strictly(MOI.LessThan(5.0)))
            c4 = MOI.add_constraint(m, x, CP.DifferentFrom(5.0))

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)

            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 4

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var float: x1;
                
                
                
                constraint float_eq(x1, 5.0);
                constraint float_le(x1, 5.0);
                constraint float_lt(x1, 5.0);
                constraint float_ne(x1, 5.0);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.Reified{MOI.VectorOfVariables of integers in MOI.EqualTo / MOI.LessThan / CP.Strictly{MOI.LessThan} / CP.DifferentFrom}" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variable.
            x, x_bool = MOI.add_constrained_variable(m, MOI.ZeroOne())
            y, y_int = MOI.add_constrained_variable(m, MOI.Integer())

            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_bool)
            @test MOI.is_valid(m, y)
            @test MOI.is_valid(m, y_int)

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints. 
            c1 = MOI.add_constraint(m, [x, y], CP.Reified(MOI.EqualTo(2)))
            c2 = MOI.add_constraint(m, [x, y], CP.Reified(MOI.LessThan(2)))
            c3 = MOI.add_constraint(
                m,
                [x, y],
                CP.Reified(CP.Strictly(MOI.LessThan(2))),
            )
            c4 = MOI.add_constraint(m, [x, y], CP.Reified(CP.DifferentFrom(2)))

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)

            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 6

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var bool: x1;
                var int: x2;
                
                
                
                constraint int_eq_reif(x2, 2, x1);
                constraint int_le_reif(x1, 2, x1);
                constraint int_lt_reif(x2, 2, x1);
                constraint int_ne_reif(x2, 2, x1);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x, y]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.Reified{MOI.VectorOfVariables of floats in MOI.EqualTo / MOI.LessThan / CP.Strictly{MOI.LessThan} / CP.DifferentFrom}" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variable.
            x, x_bool = MOI.add_constrained_variable(m, MOI.ZeroOne())
            y = MOI.add_variable(m)

            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_bool)
            @test MOI.is_valid(m, y)

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints. 
            c1 = MOI.add_constraint(m, [x, y], CP.Reified(MOI.EqualTo(2.0)))
            c2 = MOI.add_constraint(m, [x, y], CP.Reified(MOI.LessThan(2.0)))
            c3 = MOI.add_constraint(
                m,
                [x, y],
                CP.Reified(CP.Strictly(MOI.LessThan(2.0))),
            )
            c4 =
                MOI.add_constraint(m, [x, y], CP.Reified(CP.DifferentFrom(2.0)))

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)

            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 5

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var bool: x1;
                var float: x2;
                
                
                
                constraint float_eq_reif(x2, 2.0, x1);
                constraint float_le_reif(x2, 2.0, x1);
                constraint float_lt_reif(x2, 2.0, x1);
                constraint float_ne_reif(x2, 2.0, x1);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x, y]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.Reified{MOI.VectorAffineFunction of integers in MOI.EqualTo / MOI.LessThan / CP.Strictly{MOI.LessThan} / CP.DifferentFrom}" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variable.
            w, w_bool = MOI.add_constrained_variable(m, MOI.ZeroOne())
            x, x_bool = MOI.add_constrained_variable(m, MOI.ZeroOne())
            y, y_int = MOI.add_constrained_variable(m, MOI.Integer())
            z, z_int = MOI.add_constrained_variable(m, MOI.Integer())

            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, w)
            @test MOI.is_valid(m, w_bool)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_bool)
            @test MOI.is_valid(m, y)
            @test MOI.is_valid(m, y_int)
            @test MOI.is_valid(m, z)
            @test MOI.is_valid(m, z_int)

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints. 
            vaf = MOI.VectorAffineFunction(
                MOI.VectorAffineTerm.(
                    [1, 2, 2, 2],
                    MOI.ScalarAffineTerm.([1, 1, 1, 1], [w, x, y, z]),
                ),
                [0, 0],
            )

            c1 = MOI.add_constraint(m, vaf, CP.Reified(MOI.EqualTo(2)))
            c2 = MOI.add_constraint(m, vaf, CP.Reified(MOI.LessThan(2)))
            c3 = MOI.add_constraint(
                m,
                vaf,
                CP.Reified(CP.Strictly(MOI.LessThan(2))),
            )
            c4 = MOI.add_constraint(m, vaf, CP.Reified(CP.DifferentFrom(2)))

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)

            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 6

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var bool: x1;
                var bool: x2;
                var int: x3;
                var int: x4;
                
                
                
                constraint int_lin_eq_reif([1, 1, 1], [x2, x3, x4], 2, x1);
                constraint int_lin_le_reif([1, 1, 1], [x2, x3, x4], 2, x1);
                constraint int_lin_lt_reif([1, 1, 1], [x2, x3, x4], 2, x1);
                constraint int_lin_ne_reif([1, 1, 1], [x2, x3, x4], 2, x1);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x, y]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.Reified{MOI.VectorAffineFunction of floats in MOI.EqualTo / MOI.LessThan / CP.Strictly{MOI.LessThan} / CP.DifferentFrom}" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variable.
            w, w_bool = MOI.add_constrained_variable(m, MOI.ZeroOne())
            x, x_bool = MOI.add_constrained_variable(m, MOI.ZeroOne())
            y, y_int = MOI.add_constrained_variable(m, MOI.Integer())
            z = MOI.add_variable(m)

            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, w)
            @test MOI.is_valid(m, w_bool)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_bool)
            @test MOI.is_valid(m, y)
            @test MOI.is_valid(m, y_int)
            @test MOI.is_valid(m, z)

            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Add constraints. 
            vaf = MOI.VectorAffineFunction(
                MOI.VectorAffineTerm.(
                    [1, 2, 2, 2],
                    MOI.ScalarAffineTerm.([1.0, 1.0, 1.0, 1.0], [w, x, y, z]),
                ),
                [0.0, 0.0],
            )

            c1 = MOI.add_constraint(m, vaf, CP.Reified(MOI.EqualTo(2.0)))
            c2 = MOI.add_constraint(m, vaf, CP.Reified(MOI.LessThan(2.0)))
            c3 = MOI.add_constraint(
                m,
                vaf,
                CP.Reified(CP.Strictly(MOI.LessThan(2.0))),
            )
            c4 = MOI.add_constraint(m, vaf, CP.Reified(CP.DifferentFrom(2.0)))

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)

            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 6

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var bool: x1;
                var bool: x2;
                var int: x3;
                var float: x4;
                
                
                
                constraint float_lin_eq_reif([1.0, 1.0, 1.0], [x2, x3, x4], 2.0, x1);
                constraint float_lin_le_reif([1.0, 1.0, 1.0], [x2, x3, x4], 2.0, x1);
                constraint float_lin_lt_reif([1.0, 1.0, 1.0], [x2, x3, x4], 2.0, x1);
                constraint float_lin_ne_reif([1.0, 1.0, 1.0], [x2, x3, x4], 2.0, x1);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x, y]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Name rewriting" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            # Create variables.
            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
            y, y_bool =
                MOI.add_constrained_variables(m, [MOI.ZeroOne() for _ in 1:5])

            # Set names. The name for x in invalid for FlatZinc, but not 
            # the ones for y.
            MOI.set(m, MOI.VariableName(), x, "_x")
            for i in 1:5
                MOI.set(m, MOI.VariableName(), y[i], "y_$(i)")
            end

            @test MOI.get(m, MOI.VariableName(), x) == "_x"
            for i in 1:5
                @test MOI.get(m, MOI.VariableName(), y[i]) == "y_$(i)"
            end

            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x_x;
                var bool: y_1;
                var bool: y_2;
                var bool: y_3;
                var bool: y_4;
                var bool: y_5;
                
                
                
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            @test MOI.get(m, MOI.VariableName(), x) == "x_x"
            for i in 1:5
                @test MOI.get(m, MOI.VariableName(), y[i]) == "y_$(i)"
            end
        end

        @testset "Maximising" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())

            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_int)

            MOI.set(
                m,
                MOI.ObjectiveFunction{MOI.SingleVariable}(),
                MOI.SingleVariable(x),
            )

            MOI.set(m, MOI.ObjectiveSense(), MOI.MAX_SENSE)

            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;




            solve maximize x1;
            """
        end

        @testset "Minimising" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())

            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_int)

            MOI.set(
                m,
                MOI.ObjectiveFunction{MOI.SingleVariable}(),
                MOI.SingleVariable(x),
            )

            MOI.set(m, MOI.ObjectiveSense(), MOI.MIN_SENSE)

            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;




            solve minimize x1;
            """
        end
    end

    @testset "Reading" begin
        @testset "Item-splitting helper" begin
            io = IOBuffer(b"""var int: x1; 
                constraint int_eq(x1, 2);
                solve satisfy;""")

            @test CP.FlatZinc.get_fzn_item(io) == "var int: x1;"
            @test CP.FlatZinc.get_fzn_item(io) == "constraint int_eq(x1, 2);"
            @test CP.FlatZinc.get_fzn_item(io) == "solve satisfy;"
            @test CP.FlatZinc.get_fzn_item(io) == ""

            io = IOBuffer(b"""var int: x1; 
                var int: x2; % Comment at the end of a line
                
                % Comment feeling alone.
                
                constraint int_lin_eq([1, 1], [x1, x2], 2);
                
                solve satisfy;""")

            @test CP.FlatZinc.get_fzn_item(io) == "var int: x1;"
            @test CP.FlatZinc.get_fzn_item(io) == "var int: x2;"
            @test CP.FlatZinc.get_fzn_item(io) ==
                  "constraint int_lin_eq([1, 1], [x1, x2], 2);"
            @test CP.FlatZinc.get_fzn_item(io) == "solve satisfy;"
            @test CP.FlatZinc.get_fzn_item(io) == ""

            io = IOBuffer(b"""% Comment at the beginning of a file
                
                % Comment feeling alone.
                
                solve satisfy;""")

            @test CP.FlatZinc.get_fzn_item(io) == "solve satisfy;"
            @test CP.FlatZinc.get_fzn_item(io) == ""
        end

        @testset "Parsing helpers" begin
            @testset "parse_array_type" begin
                @test_throws AssertionError CP.FlatZinc.parse_array_type("5")
                @test_throws AssertionError CP.FlatZinc.parse_array_type("2..5")
                @test_throws AssertionError CP.FlatZinc.parse_array_type(
                    "[2..5]",
                )
                @test_throws AssertionError CP.FlatZinc.parse_array_type(
                    "[2..5] ",
                )
                @test_throws AssertionError CP.FlatZinc.parse_array_type(
                    " [2..5]",
                )
                @test_throws AssertionError CP.FlatZinc.parse_array_type(
                    " [2..5] ",
                )

                @test CP.FlatZinc.parse_array_type("") === nothing
                @test CP.FlatZinc.parse_array_type("[1..5]") == 5
                @test CP.FlatZinc.parse_array_type("[  1  ..  5  ]") == 5
                @test CP.FlatZinc.parse_array_type("[1..9846515]") == 9846515
                @test CP.FlatZinc.parse_array_type(
                    "[          1.. 9846515 ]",
                ) == 9846515
                @test CP.FlatZinc.parse_array_type("[1  ..9846515]") == 9846515
            end

            @testset "parse_range" begin
                @test_throws AssertionError CP.FlatZinc.parse_range("")
                @test_throws AssertionError CP.FlatZinc.parse_range("5")
                @test_throws ErrorException CP.FlatZinc.parse_range("[2..5]")
                @test_throws ErrorException CP.FlatZinc.parse_range("[2..5] ")
                @test_throws ErrorException CP.FlatZinc.parse_range(" [2..5]")
                @test_throws ErrorException CP.FlatZinc.parse_range(" [2..5] ")

                @test CP.FlatZinc.parse_range("1..5") ==
                      (CP.FlatZinc.FznInt, 1, 5)
                @test CP.FlatZinc.parse_range("1  ..  5") ==
                      (CP.FlatZinc.FznInt, 1, 5)
                @test CP.FlatZinc.parse_range("1..9846515") ==
                      (CP.FlatZinc.FznInt, 1, 9846515)
                @test CP.FlatZinc.parse_range("1.. 9846515") ==
                      (CP.FlatZinc.FznInt, 1, 9846515)

                @test CP.FlatZinc.parse_range("1..1.5") ==
                      (CP.FlatZinc.FznFloat, 1, 1.5)
                @test CP.FlatZinc.parse_range("1  ..  1.5") ==
                      (CP.FlatZinc.FznFloat, 1, 1.5)
                @test CP.FlatZinc.parse_range("1..9.846515") ==
                      (CP.FlatZinc.FznFloat, 1, 9.846515)
                @test CP.FlatZinc.parse_range("1.. 9.846515") ==
                      (CP.FlatZinc.FznFloat, 1, 9.846515)
            end

            @testset "parse_set" begin
                @test_throws AssertionError CP.FlatZinc.parse_set("")
                @test_throws AssertionError CP.FlatZinc.parse_set("5")
                @test_throws AssertionError CP.FlatZinc.parse_set("[2..5]")
                @test_throws AssertionError CP.FlatZinc.parse_set("{2, 5} ")
                @test_throws AssertionError CP.FlatZinc.parse_set(" {2, 5}")
                @test_throws AssertionError CP.FlatZinc.parse_set(" {2, 5} ")
                @test_throws AssertionError CP.FlatZinc.parse_set(" {a, b} ")

                @test CP.FlatZinc.parse_set("{}") == (CP.FlatZinc.FznInt, Int[])
                @test CP.FlatZinc.parse_set("{2}") == (CP.FlatZinc.FznInt, [2])
                @test CP.FlatZinc.parse_set("{2, 5}") ==
                      (CP.FlatZinc.FznInt, [2, 5])
                @test CP.FlatZinc.parse_set("{ 2 , 5 }") ==
                      (CP.FlatZinc.FznInt, [2, 5])
                @test CP.FlatZinc.parse_set("{1, 9846515}") ==
                      (CP.FlatZinc.FznInt, [1, 9846515])

                # No empty float set, impossible to distinguish from integers.
                @test CP.FlatZinc.parse_set("{2.0}") ==
                      (CP.FlatZinc.FznFloat, [2.0])
                @test CP.FlatZinc.parse_set("{2.0, 5.1}") ==
                      (CP.FlatZinc.FznFloat, [2.0, 5.1])
                @test CP.FlatZinc.parse_set("{ 2.0 , 5.1 }") ==
                      (CP.FlatZinc.FznFloat, [2.0, 5.1])
                @test CP.FlatZinc.parse_set("{1.0, 9.846515}") ==
                      (CP.FlatZinc.FznFloat, [1.0, 9.846515])
            end

            @testset "parse_variable_type" begin
                @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                    "set of",
                )
                @test_throws ErrorException CP.FlatZinc.parse_variable_type(
                    "set of [2..5]",
                )
                @test_throws ErrorException CP.FlatZinc.parse_variable_type(
                    "set of [2..5",
                )
                @test_throws ErrorException CP.FlatZinc.parse_variable_type(
                    "set of 2..5]",
                )
                @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                    "set of {2, 5",
                )
                @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                    "set of 2, 5}",
                )
                @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                    "set of {2..5",
                )
                @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                    "set of 2..5}",
                )
                @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                    "this is garbage",
                )

                @test CP.FlatZinc.parse_variable_type("bool") == (
                    CP.FlatZinc.FznBool,
                    CP.FlatZinc.FznScalar,
                    nothing,
                    nothing,
                    nothing,
                )
                @test CP.FlatZinc.parse_variable_type("int") == (
                    CP.FlatZinc.FznInt,
                    CP.FlatZinc.FznScalar,
                    nothing,
                    nothing,
                    nothing,
                )
                @test CP.FlatZinc.parse_variable_type("float") == (
                    CP.FlatZinc.FznFloat,
                    CP.FlatZinc.FznScalar,
                    nothing,
                    nothing,
                    nothing,
                )
                @test CP.FlatZinc.parse_variable_type("set of int") == (
                    CP.FlatZinc.FznInt,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    nothing,
                )

                @test CP.FlatZinc.parse_variable_type("set of {}") == (
                    CP.FlatZinc.FznInt,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    Int[],
                )
                @test CP.FlatZinc.parse_variable_type("set of {2}") == (
                    CP.FlatZinc.FznInt,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    [2],
                )
                @test CP.FlatZinc.parse_variable_type("set of {2, 5}") == (
                    CP.FlatZinc.FznInt,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    [2, 5],
                )
                @test CP.FlatZinc.parse_variable_type("set of { 2 , 5 }") == (
                    CP.FlatZinc.FznInt,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    [2, 5],
                )
                @test CP.FlatZinc.parse_variable_type("set of {1, 9846515}") ==
                      (
                    CP.FlatZinc.FznInt,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    [1, 9846515],
                )

                # No empty float set, impossible to distinguish from integers.
                @test CP.FlatZinc.parse_variable_type("set of {2.0}") == (
                    CP.FlatZinc.FznFloat,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    [2.0],
                )
                @test CP.FlatZinc.parse_variable_type("set of {2.0, 5.1}") == (
                    CP.FlatZinc.FznFloat,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    [2.0, 5.1],
                )
                @test CP.FlatZinc.parse_variable_type("set of { 2.0 , 5.1 }") ==
                      (
                    CP.FlatZinc.FznFloat,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    [2.0, 5.1],
                )
                @test CP.FlatZinc.parse_variable_type(
                    "set of {1.0, 9.846515}",
                ) == (
                    CP.FlatZinc.FznFloat,
                    CP.FlatZinc.FznSet,
                    nothing,
                    nothing,
                    [1.0, 9.846515],
                )

                @test CP.FlatZinc.parse_variable_type("set of 2..5") ==
                      (CP.FlatZinc.FznInt, CP.FlatZinc.FznSet, 2, 5, nothing)
            end

            @testset "parse_basic_expression" begin
                @test CP.FlatZinc.parse_basic_expression("true") == true
                @test CP.FlatZinc.parse_basic_expression("false") == false
                @test CP.FlatZinc.parse_basic_expression("1") == 1
                @test CP.FlatZinc.parse_basic_expression("1.0") == 1.0
                @test CP.FlatZinc.parse_basic_expression("x1") == "x1"
            end
        end

        @testset "Predicate section" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
            @test_throws ErrorException CP.FlatZinc.parse_predicate!("", m)
        end

        @testset "Parameter section" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
            @test_throws ErrorException CP.FlatZinc.parse_parameter!("", m)
        end

        @testset "Variable section" begin
            @testset "Split a variable entry" begin
                @test_throws AssertionError CP.FlatZinc.split_variable("")
                @test_throws AssertionError CP.FlatZinc.split_variable(
                    "solve satisfy;",
                )

                # Vanilla declaration.
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable("var int: x1;")
                @test var_array == ""
                @test var_type == "int"
                @test var_name == "x1"
                @test var_annotations == ""
                @test var_value == ""

                # With another type (still a string) and an *invalid* variable name.
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable("var bool: 5454;")
                @test var_array == ""
                @test var_type == "bool"
                @test var_name == "5454"
                @test var_annotations == ""
                @test var_value == ""

                # With another type (range of integers).
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable("var 4..8: x1;")
                @test var_array == ""
                @test var_type == "4..8"
                @test var_name == "x1"
                @test var_annotations == ""
                @test var_value == ""

                # With another type (range of floats).
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable("var 4.5..8.4: x1;")
                @test var_array == ""
                @test var_type == "4.5..8.4"
                @test var_name == "x1"
                @test var_annotations == ""
                @test var_value == ""

                # With another type (set of floats, intension).
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable("var set of 4.5..8.4: x1;")
                @test var_array == ""
                @test var_type == "set of 4.5..8.4"
                @test var_name == "x1"
                @test var_annotations == ""
                @test var_value == ""

                # With another type (set of floats, extension).
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable("var set of {4.5, 8.4}: x1;")
                @test var_array == ""
                @test var_type == "set of {4.5, 8.4}"
                @test var_name == "x1"
                @test var_annotations == ""
                @test var_value == ""

                # With annotations.
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable(
                        "var int: x1 :: some_annotation;",
                    )
                @test var_array == ""
                @test var_type == "int"
                @test var_name == "x1"
                @test var_annotations == "some_annotation"
                @test var_value == ""

                # With value.
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable("var int: x1 = some_value;")
                @test var_array == ""
                @test var_type == "int"
                @test var_name == "x1"
                @test var_annotations == ""
                @test var_value == "some_value"

                # With annotations and value.
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable(
                        "var int: x1 :: some_annotation = some_value;",
                    )
                @test var_array == ""
                @test var_type == "int"
                @test var_name == "x1"
                @test var_annotations == "some_annotation"
                @test var_value == "some_value"

                # Array declaration.
                var_array, var_type, var_name, var_annotations, var_value =
                    CP.FlatZinc.split_variable("array [1..5] of var int: x1;")
                @test var_array == "[1..5]"
                @test var_type == "int"
                @test var_name == "x1"
                @test var_annotations == ""
                @test var_value == ""
            end

            @testset "Variable entry" begin
                m = CP.FlatZinc.Optimizer()
                @test MOI.is_empty(m)

                moi_var_1 = CP.FlatZinc.parse_variable!("var bool: x1;", m)
                @test !MOI.is_empty(m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 1
                @test MOI.get(
                    m,
                    MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}(),
                ) == 1
                @test length(m.variable_info) == 1
                @test m.variable_info[moi_var_1] !== nothing
                @test m.variable_info[moi_var_1].name == "x1"
                @test m.variable_info[moi_var_1].set == MOI.ZeroOne()
                @test length(m.constraint_info) == 1
                @test m.constraint_info[1].f == MOI.SingleVariable(moi_var_1)
                @test m.constraint_info[1].s == MOI.ZeroOne()
                @test m.constraint_info[1].output_as_part_of_variable

                @test_throws ErrorException CP.FlatZinc.parse_variable!(
                    "var bool: x1;",
                    m,
                )

                moi_var_2 = CP.FlatZinc.parse_variable!("var int: x2;", m)
                @test !MOI.is_empty(m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 2
                @test MOI.get(
                    m,
                    MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}(),
                ) == 1
                @test length(m.variable_info) == 2
                @test m.variable_info[moi_var_2] !== nothing
                @test m.variable_info[moi_var_2].name == "x2"
                @test m.variable_info[moi_var_2].set == MOI.Integer()
                @test length(m.constraint_info) == 2
                @test m.constraint_info[2].f == MOI.SingleVariable(moi_var_2)
                @test m.constraint_info[2].s == MOI.Integer()
                @test m.constraint_info[2].output_as_part_of_variable

                moi_var_3 = CP.FlatZinc.parse_variable!("var float: x3;", m)
                @test !MOI.is_empty(m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 3
                @test length(m.variable_info) == 3
                @test m.variable_info[moi_var_3] !== nothing
                @test m.variable_info[moi_var_3].name == "x3"
                @test m.variable_info[moi_var_3].set == MOI.Reals(1)
                @test length(m.constraint_info) == 2

                moi_var_4 = CP.FlatZinc.parse_variable!("var 0..7: x4;", m)
                @test !MOI.is_empty(m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 4
                @test MOI.get(
                    m,
                    MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}(),
                ) == 2
                @test length(m.variable_info) == 4
                @test m.variable_info[moi_var_4] !== nothing
                @test m.variable_info[moi_var_4].name == "x4"
                @test m.variable_info[moi_var_4].set == MOI.Integer()
                @test length(m.constraint_info) == 4
                @test m.constraint_info[3].f == MOI.SingleVariable(moi_var_4)
                @test m.constraint_info[3].s == MOI.Integer()
                @test m.constraint_info[3].output_as_part_of_variable
                @test m.constraint_info[4].f == MOI.SingleVariable(moi_var_4)
                @test m.constraint_info[4].s == MOI.Interval(0, 7)
                @test !m.constraint_info[4].output_as_part_of_variable

                moi_var_5 = CP.FlatZinc.parse_variable!("var 0.0..7.0: x5;", m)
                @test !MOI.is_empty(m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 5
                @test length(m.variable_info) == 5
                @test m.variable_info[moi_var_5] !== nothing
                @test m.variable_info[moi_var_5].name == "x5"
                @test m.variable_info[moi_var_5].set == MOI.Reals(1)
                @test length(m.constraint_info) == 5
                @test m.constraint_info[5].f == MOI.SingleVariable(moi_var_5)
                @test m.constraint_info[5].s == MOI.Interval(0.0, 7.0)
                @test !m.constraint_info[5].output_as_part_of_variable

                moi_var_6 = CP.FlatZinc.parse_variable!("var {0, 7}: x6;", m)
                @test !MOI.is_empty(m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 6
                @test MOI.get(
                    m,
                    MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}(),
                ) == 3
                @test length(m.variable_info) == 6
                @test m.variable_info[moi_var_6] !== nothing
                @test m.variable_info[moi_var_6].name == "x6"
                @test m.variable_info[moi_var_6].set == MOI.Integer()
                @test length(m.constraint_info) == 7
                @test m.constraint_info[6].f == MOI.SingleVariable(moi_var_6)
                @test m.constraint_info[6].s == MOI.Integer()
                @test m.constraint_info[6].output_as_part_of_variable
                @test m.constraint_info[7].f == MOI.SingleVariable(moi_var_6)
                @test m.constraint_info[7].s == CP.Domain(Set([0, 7]))
                @test !m.constraint_info[7].output_as_part_of_variable

                moi_var_7 =
                    CP.FlatZinc.parse_variable!("var {0.0, 7.0}: x7;", m)
                @test !MOI.is_empty(m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 7
                @test length(m.variable_info) == 7
                @test m.variable_info[moi_var_7] !== nothing
                @test m.variable_info[moi_var_7].name == "x7"
                @test m.variable_info[moi_var_7].set == MOI.Reals(1)
                @test length(m.constraint_info) == 8
                @test m.constraint_info[8].f == MOI.SingleVariable(moi_var_7)
                @test m.constraint_info[8].s == CP.Domain(Set([0.0, 7.0]))
                @test !m.constraint_info[8].output_as_part_of_variable

                # TODO: implement this.
                @test_throws ErrorException CP.FlatZinc.parse_variable!(
                    "array [1..5] of var int: x1;",
                    m,
                )

                @test_throws ErrorException CP.FlatZinc.parse_variable!(
                    "var set of int: x1;",
                    m,
                )

                @test_logs (
                    :warn,
                    "Annotations are not supported and are currently ignored.",
                ) CP.FlatZinc.parse_variable!(
                    "var {0.0, 7.0}: x42 :: SOME_ANNOTATION;",
                    m,
                )
            end
        end

        @testset "Constraint section" begin
            @testset "Split a constraint entry" begin
                @test_throws AssertionError CP.FlatZinc.split_constraint("")
                @test_throws AssertionError CP.FlatZinc.split_constraint(
                    "var int: x456389564;",
                ) # More than 10 characters to avoid the first assertion.

                @test CP.FlatZinc.split_constraint(
                    "constraint int_le(0, x);",
                ) == ("int_le", "0, x", nothing)
                @test CP.FlatZinc.split_constraint(
                    "constraint int_lin_eq([2, 3], [x, y], 10);",
                ) == ("int_lin_eq", "[2, 3], [x, y], 10", nothing)
                @test CP.FlatZinc.split_constraint(
                    "constraint int_lin_eq([2, 3], [x, y], 10) :: domain;",
                ) == ("int_lin_eq", "[2, 3], [x, y], 10", "domain")
            end

            @testset "Split arguments" begin
                @test_throws AssertionError CP.FlatZinc.split_constraint_arguments(
                    "",
                )

                @test CP.FlatZinc.split_constraint_arguments("1") == ["1"]
                @test CP.FlatZinc.split_constraint_arguments("1.1") == ["1.1"]
                @test CP.FlatZinc.split_constraint_arguments("x1") == ["x1"]
                @test CP.FlatZinc.split_constraint_arguments("true") == ["true"]
                @test CP.FlatZinc.split_constraint_arguments("false") ==
                      ["false"]

                @test CP.FlatZinc.split_constraint_arguments("1,") == ["1"]
                @test CP.FlatZinc.split_constraint_arguments("1.1,") == ["1.1"]
                @test CP.FlatZinc.split_constraint_arguments("x1,") == ["x1"]
                @test CP.FlatZinc.split_constraint_arguments("true,") ==
                      ["true"]
                @test CP.FlatZinc.split_constraint_arguments("false,") ==
                      ["false"]

                @test CP.FlatZinc.split_constraint_arguments("1, 1.1") ==
                      ["1", "1.1"]
                @test CP.FlatZinc.split_constraint_arguments("1.1, x1") ==
                      ["1.1", "x1"]
                @test CP.FlatZinc.split_constraint_arguments("x1, true") ==
                      ["x1", "true"]
                @test CP.FlatZinc.split_constraint_arguments("true, false") ==
                      ["true", "false"]
                @test CP.FlatZinc.split_constraint_arguments("false, 1") ==
                      ["false", "1"]
                @test CP.FlatZinc.split_constraint_arguments(
                    "false  ,     1",
                ) == ["false", "1"]

                @test CP.FlatZinc.split_constraint_arguments("[1, 1.1]") ==
                      CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "1",
                    "1.1",
                ]]
                @test CP.FlatZinc.split_constraint_arguments("[1.1, x1]") ==
                      CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "1.1",
                    "x1",
                ]]
                @test CP.FlatZinc.split_constraint_arguments("[x1, true]") ==
                      CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "x1",
                    "true",
                ]]
                @test CP.FlatZinc.split_constraint_arguments("[true, false]") ==
                      CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "true",
                    "false",
                ]]
                @test CP.FlatZinc.split_constraint_arguments("[false, 1]") ==
                      CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "false",
                    "1",
                ]]

                @test CP.FlatZinc.split_constraint_arguments("[1, 1.1], x1") ==
                      CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["1", "1.1"],
                    "x1",
                ]
                @test CP.FlatZinc.split_constraint_arguments(
                    "[1.1, x1], true",
                ) == CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["1.1", "x1"],
                    "true",
                ]
                @test CP.FlatZinc.split_constraint_arguments(
                    "[x1, true], false",
                ) == CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["x1", "true"],
                    "false",
                ]
                @test CP.FlatZinc.split_constraint_arguments(
                    "[true, false], 1",
                ) == CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["true", "false"],
                    "1",
                ]
                @test CP.FlatZinc.split_constraint_arguments(
                    "[false, 1], 1.1",
                ) == CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["false", "1"],
                    "1.1",
                ]
            end

            @testset "Parse arguments" begin
                @test CP.FlatZinc.parse_constraint_arguments(["1"]) == [1]
                @test CP.FlatZinc.parse_constraint_arguments(["1.1"]) == [1.1]
                @test CP.FlatZinc.parse_constraint_arguments(["x1"]) == ["x1"]
                @test CP.FlatZinc.parse_constraint_arguments(["true"]) == [true]
                @test CP.FlatZinc.parse_constraint_arguments(["false"]) ==
                      [false]

                @test CP.FlatZinc.parse_constraint_arguments(["1", "1.1"]) ==
                      [1, 1.1]
                @test CP.FlatZinc.parse_constraint_arguments(["1.1", "x1"]) ==
                      [1.1, "x1"]
                @test CP.FlatZinc.parse_constraint_arguments(["x1", "true"]) ==
                      ["x1", true]
                @test CP.FlatZinc.parse_constraint_arguments([
                    "true",
                    "false",
                ]) == [true, false]
                @test CP.FlatZinc.parse_constraint_arguments(["false", "1"]) ==
                      [false, 1]

                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                        "1",
                        "1.1",
                    ]],
                ) == [[1, 1.1]]
                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                        "1.1",
                        "x1",
                    ]],
                ) == [[1.1, "x1"]]
                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                        "x1",
                        "true",
                    ]],
                ) == [["x1", true]]
                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                        "true",
                        "false",
                    ]],
                ) == [[true, false]]
                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                        "false",
                        "1",
                    ]],
                ) == [[false, 1]]

                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                        AbstractString["1", "1.1"],
                        "x1",
                    ],
                ) == [[1, 1.1], "x1"]
                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                        AbstractString["1.1", "x1"],
                        "true",
                    ],
                ) == [[1.1, "x1"], true]
                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                        AbstractString["x1", "true"],
                        "false",
                    ],
                ) == [["x1", true], false]
                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                        AbstractString["true", "false"],
                        "1",
                    ],
                ) == [[true, false], 1]
                @test CP.FlatZinc.parse_constraint_arguments(
                    CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                        AbstractString["false", "1"],
                        "1.1",
                    ],
                ) == [[false, 1], 1.1]
            end

            @testset "Parse constraint verbs from strings into enumeration" begin
                @test CP.FlatZinc.parse_constraint_verb("array_int_element") ==
                      CP.FlatZinc.FznArrayIntElement
                # Call it a day.
            end

            @testset "Array of mixed values to MOI variables" begin
                @testset "Variables and Booleans" begin
                    m = CP.FlatZinc.Optimizer()
                    @test MOI.is_empty(m)

                    x = CP.FlatZinc.parse_variable!("var bool: x;", m)
                    @test MOI.get(m, MOI.NumberOfVariables()) == 1

                    a = CP.FlatZinc.array_mixed_var_bool_to_moi_var(
                        ["x", true],
                        m,
                    )
                    @test MOI.get(m, MOI.NumberOfVariables()) == 2
                    @test length(a) == 2
                    @test a[1] == x
                    @test a[2] != x

                    @test_throws ErrorException CP.FlatZinc.array_mixed_var_bool_to_moi_var(
                        ["x", MOI.Interval],
                        m,
                    )
                end

                @testset "Variables and integers" begin
                    m = CP.FlatZinc.Optimizer()
                    @test MOI.is_empty(m)

                    x = CP.FlatZinc.parse_variable!("var int: x;", m)
                    @test MOI.get(m, MOI.NumberOfVariables()) == 1

                    a = CP.FlatZinc.array_mixed_var_int_to_moi_var(["x", 1], m)
                    @test MOI.get(m, MOI.NumberOfVariables()) == 2
                    @test length(a) == 2
                    @test a[1] == x
                    @test a[2] != x

                    @test_throws ErrorException CP.FlatZinc.array_mixed_var_int_to_moi_var(
                        ["x", MOI.Interval],
                        m,
                    )
                end

                @testset "Variables and floats" begin
                    m = CP.FlatZinc.Optimizer()
                    @test MOI.is_empty(m)

                    x = CP.FlatZinc.parse_variable!("var float: x;", m)
                    @test MOI.get(m, MOI.NumberOfVariables()) == 1

                    a = CP.FlatZinc.array_mixed_var_float_to_moi_var(
                        ["x", 1.0],
                        m,
                    )
                    @test MOI.get(m, MOI.NumberOfVariables()) == 2
                    @test length(a) == 2
                    @test a[1] == x
                    @test a[2] != x

                    @test_throws ErrorException CP.FlatZinc.array_mixed_var_float_to_moi_var(
                        ["x", MOI.Interval],
                        m,
                    )
                end
            end

            @testset "Constraint entry" begin
                m = CP.FlatZinc.Optimizer()
                @test MOI.is_empty(m)

                x1 = CP.FlatZinc.parse_variable!("var bool: x1;", m)
                x2 = CP.FlatZinc.parse_variable!("var bool: x2;", m)
                x3 = CP.FlatZinc.parse_variable!("var int: x3;", m)
                x4 = CP.FlatZinc.parse_variable!("var int: x4;", m)
                x5 = CP.FlatZinc.parse_variable!("var float: x5;", m)
                x6 = CP.FlatZinc.parse_variable!("var float: x6;", m)

                nc = 0

                # Missing semicolon (;).
                @test_throws AssertionError CP.FlatZinc.parse_constraint!(
                    "constraint array_int_element(x2, [1, 2, 3], x2)",
                    m,
                )

                CP.FlatZinc.parse_constraint!(
                    "constraint array_int_element(x3, [1, 2, 3], x4);",
                    m,
                )
                nc += 5
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f == MOI.VectorOfVariables([x4, x3])
                @test m.constraint_info[nc].s == CP.Element([1, 2, 3])

                CP.FlatZinc.parse_constraint!(
                    "constraint array_int_maximum(x3, [1, 2, 3]);",
                    m,
                )
                for i in 1:3
                    nc += 1
                    @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                    @test m.constraint_info[nc].s == MOI.Integer()

                    nc += 1
                    @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                    @test typeof(m.constraint_info[nc].s) <: MOI.EqualTo{Int}
                end
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[12].f) <: MOI.VectorOfVariables
                @test m.constraint_info[12].f.variables[1] == x3
                @test m.constraint_info[12].s == CP.MaximumAmong(3)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_int_maximum(x3, [x3, x4]);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[13].f.variables[1] == x3
                @test m.constraint_info[13].f.variables[2] == x3
                @test m.constraint_info[13].f.variables[3] == x4
                @test m.constraint_info[13].s == CP.MaximumAmong(2)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_int_minimum(x3, [1, 2, 3]);",
                    m,
                )
                for i in 1:3
                    nc += 1
                    @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                    @test m.constraint_info[nc].s == MOI.Integer()
                    nc += 1

                    @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                    @test typeof(m.constraint_info[nc].s) <: MOI.EqualTo{Int}
                end
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
                @test m.constraint_info[nc].f.variables[1] == x3
                @test m.constraint_info[nc].s == CP.MinimumAmong(3)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_int_minimum(x3, [x3, x4]);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f.variables[1] == x3
                @test m.constraint_info[nc].f.variables[2] == x3
                @test m.constraint_info[nc].f.variables[3] == x4
                @test m.constraint_info[nc].s == CP.MinimumAmong(2)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_var_int_element(x3, [x1, x2, x3, x4], x4);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f ==
                      MOI.VectorOfVariables([x4, x3, x1, x2, x3, x4])
                @test m.constraint_info[nc].s == CP.ElementVariableArray(4)

                CP.FlatZinc.parse_constraint!("constraint int_eq(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == MOI.EqualTo(0)

                CP.FlatZinc.parse_constraint!("constraint int_eq(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == MOI.EqualTo(3)

                CP.FlatZinc.parse_constraint!("constraint int_eq(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == MOI.EqualTo(4)

                CP.FlatZinc.parse_constraint!(
                    "constraint int_eq_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(0))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_eq_reif(3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(3))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_eq_reif(x3, 4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(4))

                CP.FlatZinc.parse_constraint!("constraint int_le(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == MOI.LessThan(0)

                CP.FlatZinc.parse_constraint!("constraint int_le(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x4).
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === -1
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == MOI.LessThan(-3)

                CP.FlatZinc.parse_constraint!("constraint int_le(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x3).
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == MOI.LessThan(4)

                CP.FlatZinc.parse_constraint!(
                    "constraint int_le_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(0))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_le_reif(3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(-3))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_le_reif(x3, 4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(4))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lin_eq([2, 3], [x1, x2], 5);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == MOI.EqualTo(5)

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lin_eq_reif([2, 3], [x1, x2], 5, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      2
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      3
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x2
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(5))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lin_le([2, 3], [x1, x2], 5);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == MOI.LessThan(5)

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lin_le_reif([2, 3], [x1, x2], 5, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      2
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      3
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x2
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(5))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lin_ne([2, 3], [x1, x2], 5);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == CP.DifferentFrom(5)

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lin_ne_reif([2, 3], [x1, x2], 5, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      2
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      3
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x2
                @test m.constraint_info[nc].s == CP.Reified(CP.DifferentFrom(5))

                CP.FlatZinc.parse_constraint!("constraint int_lt(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(0))

                CP.FlatZinc.parse_constraint!("constraint int_lt(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x4).
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === -1
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(-3))

                CP.FlatZinc.parse_constraint!("constraint int_lt(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x3).
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(4))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lt_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(0)))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lt_reif(3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(-3)))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_lt_reif(x3, 4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(4)))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_max(x1, x2, x3);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
                @test m.constraint_info[nc].f.variables[1] == x3
                @test m.constraint_info[nc].f.variables[2] == x1
                @test m.constraint_info[nc].f.variables[3] == x2
                @test m.constraint_info[nc].s == CP.MaximumAmong(2)

                CP.FlatZinc.parse_constraint!(
                    "constraint int_min(x1, x2, x3);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
                @test m.constraint_info[nc].f.variables[1] == x3
                @test m.constraint_info[nc].f.variables[2] == x1
                @test m.constraint_info[nc].f.variables[3] == x2
                @test m.constraint_info[nc].s == CP.MinimumAmong(2)

                CP.FlatZinc.parse_constraint!("constraint int_ne(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == CP.DifferentFrom(0)

                CP.FlatZinc.parse_constraint!("constraint int_ne(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == CP.DifferentFrom(3)

                CP.FlatZinc.parse_constraint!("constraint int_ne(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == CP.DifferentFrom(4)

                CP.FlatZinc.parse_constraint!(
                    "constraint int_ne_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(CP.DifferentFrom(0))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_ne_reif(3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(CP.DifferentFrom(3))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_ne_reif(x3, 4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s == CP.Reified(CP.DifferentFrom(4))

                CP.FlatZinc.parse_constraint!(
                    "constraint int_plus(x1, x2, x3);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 1
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].f.terms[3].coefficient === -1
                @test m.constraint_info[nc].f.terms[3].variable_index == x3
                @test m.constraint_info[nc].s == MOI.EqualTo(0)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_bool_element(x3, [true, false, false], x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f == MOI.VectorOfVariables([x1, x3])
                @test m.constraint_info[nc].s ==
                      CP.Element([true, false, false])

                CP.FlatZinc.parse_constraint!(
                    "constraint array_var_bool_element(x3, [x1, x2], x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f ==
                      MOI.VectorOfVariables([x1, x3, x1, x2])
                @test m.constraint_info[nc].s == CP.ElementVariableArray(2)

                CP.FlatZinc.parse_constraint!("constraint bool2int(x1, x3);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === -1
                @test m.constraint_info[nc].f.terms[2].variable_index == x3
                @test m.constraint_info[nc].s == MOI.EqualTo(0)

                CP.FlatZinc.parse_constraint!("constraint bool_eq(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == MOI.EqualTo(0)

                CP.FlatZinc.parse_constraint!("constraint bool_eq(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == MOI.EqualTo(3)

                CP.FlatZinc.parse_constraint!("constraint bool_eq(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == MOI.EqualTo(4)

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_eq_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(0))

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_eq_reif(3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(3))

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_eq_reif(x3, 4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(4))

                CP.FlatZinc.parse_constraint!("constraint bool_le(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == MOI.LessThan(0)

                CP.FlatZinc.parse_constraint!("constraint bool_le(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x4).
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === -1
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == MOI.LessThan(-3)

                CP.FlatZinc.parse_constraint!("constraint bool_le(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x3).
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == MOI.LessThan(4)

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_le_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(0))

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_le_reif(3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(-3))

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_le_reif(x3, 4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(4))

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_lin_eq([2, 3], [x1, x2], 5);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == MOI.EqualTo(5)

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_lin_le([2, 3], [x1, x2], 5);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == MOI.LessThan(5)

                CP.FlatZinc.parse_constraint!("constraint bool_lt(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int}
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(0))

                CP.FlatZinc.parse_constraint!("constraint bool_lt(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x4).
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === -1
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(-3))

                CP.FlatZinc.parse_constraint!("constraint bool_lt(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x3).
                @test m.constraint_info[nc].f.constant === 0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(4))

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_lt_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(0)))

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_lt_reif(3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      -1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(-3)))

                CP.FlatZinc.parse_constraint!(
                    "constraint bool_lt_reif(x3, 4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(4)))

                CP.FlatZinc.parse_constraint!(
                    "constraint array_float_element(x3, [1.0, 2.0, 3.0], x5);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f == MOI.VectorOfVariables([x5, x3])
                @test m.constraint_info[nc].s == CP.Element([1.0, 2.0, 3.0])

                CP.FlatZinc.parse_constraint!(
                    "constraint array_float_maximum(x5, [1.0, 2.0, 3.0]);",
                    m,
                )
                for i in 1:3
                    nc += 1
                    @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                    @test typeof(m.constraint_info[nc].s) <:
                          MOI.EqualTo{Float64}
                end
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
                @test m.constraint_info[nc].f.variables[1] == x5
                @test m.constraint_info[nc].s == CP.MaximumAmong(3)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_float_maximum(x5, [x5, x6]);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f.variables[1] == x5
                @test m.constraint_info[nc].f.variables[2] == x5
                @test m.constraint_info[nc].f.variables[3] == x6
                @test m.constraint_info[nc].s == CP.MaximumAmong(2)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_float_minimum(x5, [1.0, 2.0, 3.0]);",
                    m,
                )
                for i in 1:3
                    nc += 1
                    @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                    @test typeof(m.constraint_info[nc].s) <:
                          MOI.EqualTo{Float64}
                end
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
                @test m.constraint_info[nc].f.variables[1] == x5
                @test m.constraint_info[nc].s == CP.MinimumAmong(3)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_float_minimum(x5, [x5, x6]);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f.variables[1] == x5
                @test m.constraint_info[nc].f.variables[2] == x5
                @test m.constraint_info[nc].f.variables[3] == x6
                @test m.constraint_info[nc].s == CP.MinimumAmong(2)

                CP.FlatZinc.parse_constraint!(
                    "constraint array_var_float_element(x3, [x1, x2, x3, x4, x5, x6], x6);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f ==
                      MOI.VectorOfVariables([x6, x3, x1, x2, x3, x4, x5, x6])
                @test m.constraint_info[nc].s == CP.ElementVariableArray(6)

                CP.FlatZinc.parse_constraint!("constraint float_eq(x5, x6);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x5
                @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x6
                @test m.constraint_info[nc].s == MOI.EqualTo(0.0)

                CP.FlatZinc.parse_constraint!("constraint float_eq(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == MOI.EqualTo(3.0)

                CP.FlatZinc.parse_constraint!("constraint float_eq(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == MOI.EqualTo(4.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_eq_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64}
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1.0
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(0.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_eq_reif(3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(3.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_eq_reif(x3, 4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0, 0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(4.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_in(x5, 1.0, 2.0);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f == MOI.SingleVariable(x5)
                @test m.constraint_info[nc].s == MOI.Interval(1.0, 2.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_in_reif(x5, 1.0, 2.0, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test m.constraint_info[nc].f == MOI.VectorOfVariables([x1, x5])
                @test m.constraint_info[nc].s ==
                      CP.Reified(MOI.Interval(1.0, 2.0))

                CP.FlatZinc.parse_constraint!("constraint float_le(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == MOI.LessThan(0.0)

                CP.FlatZinc.parse_constraint!("constraint float_le(3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64} # Equivalent to MOI.SingleVariable(x4).
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === -1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == MOI.LessThan(-3.0)

                CP.FlatZinc.parse_constraint!("constraint float_le(x3, 4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64} # Equivalent to MOI.SingleVariable(x3).
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == MOI.LessThan(4.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_le_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64}
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1.0
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(0.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_le_reif(3.0, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      -1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(-3.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_le_reif(x3, 4.0, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(4.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lin_eq([2.0, 3.0], [x1, x2], 5.0);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == MOI.EqualTo(5.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lin_eq_reif([2.0, 3.0], [x1, x2], 5.0, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64}
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      2.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      3.0
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x2
                @test m.constraint_info[nc].s == CP.Reified(MOI.EqualTo(5.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lin_le([2.0, 3.0], [x1, x2], 5.0);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == MOI.LessThan(5.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lin_le_reif([2.0, 3.0], [x1, x2], 5.0, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64}
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      2.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      3.0
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x2
                @test m.constraint_info[nc].s == CP.Reified(MOI.LessThan(5.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lin_lt([2.0, 3.0], [x1, x2], 5.0);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(5.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lin_lt_reif([2.0, 3.0], [x1, x2], 5.0, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64}
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      2.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      3.0
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x2
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(5.0)))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lin_ne([2.0, 3.0], [x1, x2], 5.0);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 2.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 3.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].s == CP.DifferentFrom(5.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lin_ne_reif([2.0, 3.0], [x1, x2], 5.0, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64}
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      2.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      3.0
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x2
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.DifferentFrom(5.0))

                CP.FlatZinc.parse_constraint!("constraint float_lt(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(0.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lt(3.0, x4);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64} # Equivalent to MOI.SingleVariable(x4).
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === -1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(-3.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lt(x3, 4.0);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64} # Equivalent to MOI.SingleVariable(x3).
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(4.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lt_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64}
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1.0
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(0.0)))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lt_reif(3.0, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      -1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(-3.0)))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_lt_reif(x3, 4.0, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.Strictly(MOI.LessThan(4.0)))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_max(x1, x2, x3);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
                @test m.constraint_info[nc].f.variables[1] == x3
                @test m.constraint_info[nc].f.variables[2] == x1
                @test m.constraint_info[nc].f.variables[3] == x2
                @test m.constraint_info[nc].s == CP.MaximumAmong(2)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_min(x1, x2, x3);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
                @test m.constraint_info[nc].f.variables[1] == x3
                @test m.constraint_info[nc].f.variables[2] == x1
                @test m.constraint_info[nc].f.variables[3] == x2
                @test m.constraint_info[nc].s == CP.MinimumAmong(2)

                CP.FlatZinc.parse_constraint!("constraint float_ne(x3, x4);", m)
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x4
                @test m.constraint_info[nc].s == CP.DifferentFrom(0.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_ne(3.0, x4);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x4
                @test m.constraint_info[nc].s == CP.DifferentFrom(3.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_ne(x3, 4.0);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
                @test length(m.constraint_info[nc].f.terms) == 1
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].s == CP.DifferentFrom(4.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint float_ne_reif(x3, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64}
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].f.terms[3].output_index == 2
                @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                      -1.0
                @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.DifferentFrom(0.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_ne_reif(3.0, x4, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x4]).
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x4
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.DifferentFrom(3.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_ne_reif(x3, 4.0, x1);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x3]).
                @test m.constraint_info[nc].f.constants == [0.0, 0.0]
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].output_index == 1
                @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                      x1
                @test m.constraint_info[nc].f.terms[2].output_index == 2
                @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                      1.0
                @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                      x3
                @test m.constraint_info[nc].s ==
                      CP.Reified(CP.DifferentFrom(4.0))

                CP.FlatZinc.parse_constraint!(
                    "constraint float_plus(x1, x2, x3);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction
                @test length(m.constraint_info[nc].f.terms) == 3
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x1
                @test m.constraint_info[nc].f.terms[2].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x2
                @test m.constraint_info[nc].f.terms[3].coefficient === -1.0
                @test m.constraint_info[nc].f.terms[3].variable_index == x3
                @test m.constraint_info[nc].s == MOI.EqualTo(0.0)

                CP.FlatZinc.parse_constraint!(
                    "constraint int2float(x3, x5);",
                    m,
                )
                nc += 1
                @test length(m.constraint_info) == nc
                @test typeof(m.constraint_info[nc].f) <:
                      MOI.ScalarAffineFunction{Float64}
                @test m.constraint_info[nc].f.constant === 0.0
                @test length(m.constraint_info[nc].f.terms) == 2
                @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
                @test m.constraint_info[nc].f.terms[1].variable_index == x3
                @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
                @test m.constraint_info[nc].f.terms[2].variable_index == x5
                @test m.constraint_info[nc].s == MOI.EqualTo(0.0)
            end
        end

        @testset "Solve section" begin
            @testset "Split a solve entry" begin
                @test_throws AssertionError CP.FlatZinc.split_solve("")
                @test_throws AssertionError CP.FlatZinc.split_solve(
                    "var int: x1;",
                )
                @test_throws AssertionError CP.FlatZinc.split_solve(
                    "solve var int: x1;",
                )

                # Satisfy.
                obj_sense, obj_var = CP.FlatZinc.split_solve("solve satisfy;")
                @test obj_sense == CP.FlatZinc.FznSatisfy
                @test obj_var === nothing

                obj_sense, obj_var =
                    CP.FlatZinc.split_solve("solve    satisfy   ;")
                @test obj_sense == CP.FlatZinc.FznSatisfy
                @test obj_var === nothing

                # Minimise.
                obj_sense, obj_var =
                    CP.FlatZinc.split_solve("solve minimize x1;")
                @test obj_sense == CP.FlatZinc.FznMinimise
                @test obj_var == "x1"

                obj_sense, obj_var =
                    CP.FlatZinc.split_solve("solve    minimize    x1   ;")
                @test obj_sense == CP.FlatZinc.FznMinimise
                @test obj_var == "x1"

                # Maximise.
                obj_sense, obj_var =
                    CP.FlatZinc.split_solve("solve maximize x1;")
                @test obj_sense == CP.FlatZinc.FznMaximise
                @test obj_var == "x1"

                obj_sense, obj_var =
                    CP.FlatZinc.split_solve("solve    maximize    x1   ;")
                @test obj_sense == CP.FlatZinc.FznMaximise
                @test obj_var == "x1"
            end

            @testset "Solve entry" begin
                m = CP.FlatZinc.Optimizer()
                @test MOI.is_empty(m)
                moi_var = CP.FlatZinc.parse_variable!("var bool: x1;", m)
                @test MOI.get(m, MOI.ObjectiveSense()) == MOI.FEASIBILITY_SENSE

                CP.FlatZinc.parse_solve!("solve satisfy;", m)
                @test MOI.get(m, MOI.ObjectiveSense()) == MOI.FEASIBILITY_SENSE

                CP.FlatZinc.parse_solve!("solve minimize x1;", m)
                @test MOI.get(m, MOI.ObjectiveSense()) == MOI.MIN_SENSE
                @test MOI.get(m, MOI.ObjectiveFunction{MOI.SingleVariable}()) ==
                      MOI.SingleVariable(moi_var)

                CP.FlatZinc.parse_solve!("solve maximize x1;", m)
                @test MOI.get(m, MOI.ObjectiveSense()) == MOI.MAX_SENSE
                @test MOI.get(m, MOI.ObjectiveFunction{MOI.SingleVariable}()) ==
                      MOI.SingleVariable(moi_var)
            end
        end

        @testset "Base.read!" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)

            fzn = """var int: x1;
            constraint int_le(0, x1);
            solve maximize x1;"""

            read!(IOBuffer(fzn), m)

            @test !MOI.is_empty(m)
            @test MOI.get(m, MOI.NumberOfVariables()) == 1
            @test MOI.get(
                m,
                MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}(),
            ) == 1
            @test MOI.get(
                m,
                MOI.NumberOfConstraints{MOI.SingleVariable, MOI.LessThan}(),
            ) == 0
            @test MOI.get(
                m,
                MOI.NumberOfConstraints{
                    MOI.ScalarAffineFunction{Int},
                    MOI.LessThan,
                }(),
            ) == 0
            @test MOI.get(m, MOI.ObjectiveSense()) == MOI.MAX_SENSE

            @test_throws ErrorException read!(IOBuffer(fzn), m)
        end
    end
end

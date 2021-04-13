@testset "AllDifferent" begin
    mock = MOIU.MockOptimizer(COIU.Model{Int}())
    config = MOIT.TestConfig()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 2])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 2])),
    )
    COIT.alldifferenttest(mock, config)
end
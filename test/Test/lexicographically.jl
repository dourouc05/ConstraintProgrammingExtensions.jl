@testset "Lexicographically" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.TestConfig()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [2, 2, 2, 2])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [2, 2, 2, 2])),
    )
    COIT.lexicographicallytest(mock, config)
end

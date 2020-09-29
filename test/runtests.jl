using Test, DataFrames, PairsMacros
df = DataFrame(x = [1, 2], y = [3, 4], z = [5, 6])

# one arg
@test (@cols(z = sum(x))) == (:x => sum => :z)
@test (@cols(sum(x))) == (:x => sum)
@test (@cols(z = x)) == (:x => :z)
@test (@cols(x)) == :x

@test select(df, @cols(x)).x == df.x
@test (@cols(z = sum(skipmissing(x)))) == (:x => sum ∘ skipmissing => :z)
@test transform(df, @cols(z = exp.(x))).z == exp.(df.x)
@test transform(df, @cols(z = 1)).z == fill(1, size(df, 1))
@test transform(df, @cols(z = sum([1, 2, 3]))).z == fill(sum([1, 2, 3]), size(df, 1))
@test transform(df, @cols sum(x) first(x)).x_sum == [3, 3]


@test transform(df, @rows(z = exp.(x))).z == exp.(df.x)
@test isequal(transform(df, @rows(z2 = x >= 2 ? missing : z)).z2, [5, missing])





@test size(filter(@cols(x > 1), df), 1) == 1
@test size(filter(@cols((x > 1) & (y < 3)), df), 1) == 0

@test (@rows(z = rand())) == (Any[] => (DataFrames.ByRow{typeof(rand)}(rand) => :z))
@test transform(df, @rows(z = x - y)).z  == df.x .- df.y
@test transform(df, @rows(z = y - x)).z  == df.y .- df.x
@test transform(df, @rows(z = x - x)).z  == df.x .- df.x
@test transform(df, @rows abs(x) x^2).x_abs == abs.(df.x)
@test transform(df, @rows(z = x^2)).z  == df.x.^2
@test transform(df, @rows abs(x) x^2).x_abs  == abs.(df.x)


df = DataFrame(x = [[-1, -2], [-3, -4]])
@test transform(df, @rows(z = abs.(x))).z == [abs.(x) for x in df.x]

# test $
u = :y
@test (@cols(z = sum($u))) == (:y => sum => :z)
@test (@cols(z = sum($u))) == (:y => sum => :z)
@test (@rows($u = x)) == (:x => :y)
@test (@cols(z = sum(skipmissing($u)))) == (:y => sum ∘ skipmissing => :z)
u = [:y]
@test (@cols(z = sum($(u[1])))) == (:y => sum => :z)

# test obj
u = [3, 4]
@test combine(df, @cols(z = sum(^(u)))).z == [sum(u)]


# test hygiene
mean = x -> x
@test transform(df, @cols(z = mean(x))).z == df.x


# weird symbols
df = DataFrame(x = [1, 2])
@test transform!(df, @cols($("ok now") = x))."ok now" == df.x
@test transform(df, @cols(z = sum($("ok now")))).z == [3, 3]




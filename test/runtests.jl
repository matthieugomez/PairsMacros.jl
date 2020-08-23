using Test, DataFrames, DataFramesMacros
df = DataFrame(x = [1, 2], y = [3, 4], z = [5, 6])
# one arg
@test (@cols(z = sum(x))) == ([:x] => sum => :z)
@test (@cols(sum(x))) == ([:x] => sum)
@test (@cols(z = x)) == ([:x] => identity => :z)
@test (@cols(z = sum(skipmissing(x)))) == ([:x] => sum ∘ skipmissing => :z)
@test transform(df, @cols(z = exp.(x))).z == exp.(df.x)

@test size(filter(@cols(x > 1), df), 1) == 1
@test size(filter(@cols((x > 1) & (y < 3)), df), 1) == 0


@test (@rows(z = rand())) == (Any[] => (DataFrames.ByRow{typeof(rand)}(rand) => :z))
@test (@rows(z = x - y))  == ([:x, :y] => (DataFrames.ByRow{typeof(-)}(-) => :z))
@test (@rows(z = y - x))  == ([:y, :x] => (DataFrames.ByRow{typeof(-)}(-) => :z))
@test transform(df, @cols(z = 1)).z == fill(1, size(df, 1))
@test transform(df, @cols(z = sum([1, 2, 3]))).z == fill(sum([1, 2, 3]), size(df, 1))


# multiple args
@test combine(df, @cols(z1 = sum(x), z2 = sum(y))).z2 == [sum(df.y)]
@test combine(df, @cols(z1 = sum(x), z2 = sum(y))).z2 == [sum(df.y)]

# test $
u = :y
@test (@cols(z = sum($u))) == ([:y] => sum => :z)
@test (@cols(z = sum($u))) == ([:y] => sum => :z)
@test (@rows($u = x)) == ([:x] => ByRow(identity) => :y)
@test (@cols(z = sum(skipmissing($u)))) == ([:y] => sum ∘ skipmissing => :z)
u = [:y]
@test (@cols(z = sum($(u[1])))) == ([:y] => sum => :z)

# test obj
u = [3, 4]
transform(df, @cols(z = sum(^(u)))).z == sum(u)

# test macro string
u = :y
@test(repr(cols"z = sum($(u)_v)") == repr([:y_v] => (sum => :z)))

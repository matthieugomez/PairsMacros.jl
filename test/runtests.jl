using Test, DataFrames, DataFramesMacros
df = DataFrame(x = [1, 2], y = [3, 4], z = [5, 6])
@test repr(@cols(z = sum(x))) == "[:x] => (sum => :z)"
@test repr(@rows(z = x + y)) == "[:x, :y] => (ByRow{typeof(+)}(+) => :z)"
@test combine(df, @cols(z1 = sum(x), z2 = sum(y))).z2 == [sum(df.y)]
@test combine(df, @cols(z1 = sum(x), z2 = sum(y))).z2 == [sum(df.y)]
@test size(filter(@cols(x > 1), df), 1) == 1
@test @cols(z = sum(skipmissing(x)))

# test $
u = :y
@test repr(@cols(z = sum($u))) == "[:y] => (sum => :z)"
@test repr(@cols(z = sum($u))) == "[:y] => (sum => :z)"
@test repr(@rows($u = x)) == "[:x] => (ByRow{typeof(identity)}(identity) => :y)"
u = [:y]
@test repr(@cols(z = sum($(u[1])))) == "[:y] => (sum => :z)"

# test obj
u = [3, 4]
transform(df, @cols(z = sum(^(u)))).z == sum(u)


# test fast path



using Test, DataFrames, DataFramesMacros
df = DataFrame(x = [1, 2], y = [3, 4], z = [5, 6])
@test combine(df, @cols(z = sum(x))).z == [sum(df.x) ]
@test combine(df, @cols(z1 = sum(x), z2 = sum(y))).z2 == [sum(df.y)]
@test transform(df, @rows(z = x + y)).z == df.x .+ df.y
@test combine(df, @cols(z1 = sum(x), z2 = sum(y))).z2 == [sum(df.y)]
@test size(filter(@cols(x > 1), df), 1) == 1

# test $
u = :y
@test combine(df, @cols(z = sum($u))).z == [sum(df.y)]
@test transform(df, @rows($u = x)).y == df.x

# test obj
global u = [3, 4]
transform(df, @cols(z = sum(^(u)))).z == sum(u)

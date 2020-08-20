using DataFrames, DataFramesMacros
df = DataFrame(x = [1, 2], y = [3, 4], z = [5, 6])
transform(df, @cols(z = sum(x)))
transform(df, @cols(z1 = sum(x), z2 = sum(y)))
transform(df, @rows(z = x + y))
combine(df, @cols(z1 = sum(x), z2 = sum(y)))
filter(@cols(x > 1), df)

# test $
u = :y
transform(df, @cols(z2 = sum($u)))
transform(df, @rows($u = x))

# test obj
global u = [3, 4]
transform(df, @cols(z2 = sum(obj(u))))

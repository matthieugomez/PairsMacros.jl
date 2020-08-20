DataFramesMacros.jl
=============

This package  makes it easier to construct calls `args => function => name` required by `DataFrames.jl`.
This experimental package is an alternative to `DataFramesMeta`.


Use `@cols` to apply a function on columns
```julia
@cols(z = mean(x))
#> :x => mean => :z
```

Use `@rows` to apply a function on rows
```julia
@rows(z = x + y))
#> [:x, :y] => ByRow(+) => :z
```


Use `$` to substitute the name of certain columns
```julia
u = :y
@rows(z = x + $u)
#> [:x, :y] => ByRow(+) => :z)
```

Use `obj` to use outside variables
```julia
u = [3, 4]
@cols(z = mean(obj(u)))
# Any[] => mean(u) => :z
```


These macros are intended to be used within a `transform`/`combine`/`select`/`filter` call from  `DataFrames.jl`:

```julia
using DataFrames, DataFramesMacros
df = DataFrame(x = [1, 2], y = [3, 4], z = [5, 6])
transform!(df, @cols(z = mean(x)))
transform!(df, @cols(z1 = mean(x), z2 = mean(y)))
transform!(df, @rows(z = x + y))
combine(df, @cols(z1 = mean(x), z2 = mean(y)))
u = :y
transform!(df, @rows(z2 = x + $u))
transform!(df, @rows($u = x))
u = [3, 4]
transform!(df, @cols(z2 = x .+ obj(u)))
filter(@cols(x > 1), df)
```


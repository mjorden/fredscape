# Perfect substitutes (linear) functions

Builds \\f(x, y) = A (a x + b y)\\: straight-line contours with constant
MRS \\a / b\\. The consumer spends everything on whichever good gives
more utility per unit of money, so the optimum is a corner unless \\a /
p_x = b / p_y\\ exactly, when every point on the budget line is equally
good. In that knife-edge case
[`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
returns the midpoint of the budget line and flags the result with an
`indeterminate` attribute set to `TRUE`.

## Usage

``` r
perfect_substitutes(a = 1, b = 1, A = 1, kind = c("utility", "production"))
```

## Arguments

- a, b:

  Marginal utility of `x` and `y`. Positive.

- A:

  Scale factor. Positive.

- kind:

  `"utility"` or `"production"`.

## Value

A function of `x` and `y` of class `perfect_substitutes`, with `a`, `b`,
`A` and `kind` as attributes.

## Examples

``` r
u <- perfect_substitutes(a = 1, b = 2)   # y is worth twice x
optimal_bundle(u, budget(100, 1, 1))     # all y
#>   x   y utility
#> 1 0 100     200
optimal_bundle(u, budget(100, 1, 3))     # all x
#>     x y utility
#> 1 100 0     100
attr(optimal_bundle(u, budget(100, 1, 2)), "indeterminate")
#> [1] TRUE
```

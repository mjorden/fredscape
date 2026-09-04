# A budget constraint

Describes the set of bundles affordable at income `income` when the two
goods cost `px` and `py`: every \\(x, y)\\ with \\p_x x + p_y y \le I\\.
For a producer the same object is an isocost line, with `income` read as
total outlay and the prices as input prices.

## Usage

``` r
budget(income, px, py)
```

## Arguments

- income:

  Income, or total outlay. Positive.

- px, py:

  Prices of `x` and `y`. Positive.

## Value

A list of class `budget` with the inputs plus the derived `x_max`
(`income / px`), `y_max` (`income / py`) and `slope` (`-px / py`).

## See also

[`budget_line()`](https://mjorden.github.io/fredscape/reference/budget_line.md)
to get plottable coordinates,
[`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
to solve against a utility function.

## Examples

``` r
b <- budget(income = 100, px = 2, py = 5)
b
#> <Budget constraint>
#>   2 * x + 5 * y <= 100
#>   intercepts: x = 50, y = 20; slope -0.4
b$x_max
#> [1] 50
```

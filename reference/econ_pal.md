# Build a fredscape palette function

Build a fredscape palette function

## Usage

``` r
econ_pal(palette = "main", reverse = FALSE)
```

## Arguments

- palette:

  One of `"main"` (7 categorical hues), `"cool"`, `"contrast"`,
  `"blues"` (sequential) or `"redblue"` (diverging).

- reverse:

  Reverse the colour order?

## Value

A function of one argument `n` returning `n` colours. Categorical
palettes return their first `n` colours and error if `n` exceeds what
the palette holds; continuous palettes interpolate.

## Examples

``` r
econ_pal()(3)
#> [1] "#006BA2" "#3EBCD2" "#379A8B"
econ_pal("blues")(9)
#> [1] "#EBF3F7" "#CDE2EB" "#B0D2E0" "#92C2D5" "#6DAFC8" "#479BBB" "#2787AC"
#> [8] "#10709C" "#00588D"
```

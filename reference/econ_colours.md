# Look up fredscape colours by name

Look up fredscape colours by name

## Usage

``` r
econ_colours(...)

econ_colors(...)
```

## Arguments

- ...:

  Unquoted or quoted colour names, e.g. `"blue"`, `"red"`. With no
  arguments the whole dictionary is returned.

## Value

A named character vector of hex colours.

## Examples

``` r
econ_colours()
#>       blue       cyan      green     yellow      olive     purple        tan 
#>  "#006BA2"  "#3EBCD2"  "#379A8B"  "#EBB434"  "#B4BA39"  "#9A607F"  "#D1B07C" 
#>        red panel_blue panel_dark  grid_blue grid_white  grid_dark        ink 
#>  "#E3120B"  "#D5E4EB"  "#1C2B36"  "#FFFFFF"  "#D5E4EB"  "#3B4C5A"  "#1A1A1A" 
#>  ink_light      muted muted_dark      white 
#>  "#F2F2F2"  "#5A6E78"  "#A8B6BF"  "#FFFFFF" 
econ_colours("red", "blue")
#>       red      blue 
#> "#E3120B" "#006BA2" 
```

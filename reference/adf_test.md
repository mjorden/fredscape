# Augmented Dickey-Fuller test for a unit root

Estimates \\\Delta y_t = \alpha + \beta t + \gamma y\_{t-1} +
\sum\_{i=1}^{p} \phi_i \Delta y\_{t-i} + \varepsilon_t\\ and tests
\\\gamma = 0\\ (a unit root) against \\\gamma \< 0\\ (stationarity) with
the t statistic on \\\gamma\\. Under the null that statistic does not
have a t distribution; critical values come from MacKinnon's (2010)
response surfaces, which adjust for sample size.

## Usage

``` r
adf_test(x, lags = NULL, type = c("drift", "trend", "none"), max_lags = NULL)
```

## Arguments

- x:

  A numeric vector, or a single-series data frame with a `value` column.

- lags:

  Number of lagged differences `p`. With `NULL` the lag length is chosen
  by AIC over `0:max_lags`.

- type:

  Deterministic terms: `"drift"`, `"trend"` or `"none"`.

- max_lags:

  Upper bound for the AIC search. Defaults to Schwert's \\\lfloor 12
  (T/100)^{1/4} \rfloor\\.

## Value

An object of class `adf_test`: a list with `statistic`, `critical`
(named vector at 1, 5 and 10 percent), `reject` (logical, per level),
`lags`, `type`, `nobs` and the fitted `regression`. No p-value is
reported; compare the statistic with the critical values, which is what
the printer does.

## Details

Choose `type` by what the series looks like under the alternative:
`"drift"` (the default) for a series that fluctuates around a non-zero
level, `"trend"` for one that grows, `"none"` only for a series known to
be centred on zero. Including deterministic terms the data do not need
costs power; leaving out terms it does need makes the test invalid.

## References

MacKinnon, J. G. (2010). Critical values for cointegration tests.
Queen's Economics Department Working Paper 1227.

Said, S. E. and Dickey, D. A. (1984). Testing for unit roots in
autoregressive-moving average models of unknown order. *Biometrika*
71(3).

## Examples

``` r
set.seed(1)
rw <- cumsum(rnorm(200))         # a random walk: do not reject
adf_test(rw)
#> <Augmented Dickey-Fuller test: constant, 0 lagged differences, 199 observations>
#>   statistic -2.132
#>     1% critical value -3.464  cannot reject
#>     5% critical value -2.876  cannot reject
#>    10% critical value -2.574  cannot reject

ar <- as.numeric(stats::arima.sim(list(ar = 0.5), 200))   # stationary: reject
adf_test(ar)
#> <Augmented Dickey-Fuller test: constant, 0 lagged differences, 199 observations>
#>   statistic -8.543
#>     1% critical value -3.464  reject unit root
#>     5% critical value -2.876  reject unit root
#>    10% critical value -2.574  reject unit root
```

#' Ordinary least squares with robust standard errors
#'
#' [stats::lm()] underneath, with the covariance matrix replaced by one that
#' survives the two things macro data always has: heteroskedasticity and
#' serial correlation.
#'
#' * `"classical"` -- the usual \eqn{\sigma^2 (X'X)^{-1}}.
#' * `"hc1"` -- White's heteroskedasticity-consistent estimator with the
#'   \eqn{n / (n - k)} degrees-of-freedom correction (the default in Stata's
#'   `robust` option).
#' * `"hac"` -- Newey and West (1987): Bartlett-weighted autocovariances of
#'   the score up to `lags`. With `lags = NULL` the bandwidth is
#'   \eqn{\lfloor 4 (n/100)^{2/9} \rfloor}, the rule of thumb most software
#'   uses. No small-sample adjustment is applied.
#'
#' Both robust estimators are computed directly from the design matrix and
#' residuals -- a dozen lines of linear algebra -- rather than through a
#' dependency, and the tests pin them against hand-computed sandwich matrices.
#'
#' @param formula A model formula, as for [stats::lm()].
#' @param data A data frame.
#' @param se Which standard errors: `"classical"`, `"hc1"` or `"hac"`.
#' @param lags Bandwidth for `"hac"`. Ignored otherwise.
#' @param ... Passed to [stats::lm()], e.g. `subset` or `weights`.
#'
#' @return An object of class `econ_fit`: a list with `fit` (the `lm`),
#'   `vcov`, `se_type`, `lags`, `nobs` and `df`. [coef_table()] gives the
#'   coefficient table; [plot_coefficients()] draws it.
#'
#' @examples
#' econ <- ggplot2::economics
#' econ$unemp_rate <- 100 * econ$unemploy / econ$pop
#'
#' # Saving and unemployment, with serial correlation handled
#' fit <- ols(psavert ~ unemp_rate, econ, se = "hac")
#' fit
#' coef_table(fit)
#' @export
ols <- function(formula, data, se = c("classical", "hc1", "hac"), lags = NULL, ...) {
  se <- match.arg(se)
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  fit <- stats::lm(formula, data = data, ...)
  X <- stats::model.matrix(fit)
  e <- stats::residuals(fit)
  n <- nrow(X)
  k <- ncol(X)
  if (n <= k) {
    cli::cli_abort("Need more observations ({n}) than coefficients ({k}).")
  }
  if (se != "hac") {
    lags <- NULL
  } else if (is.null(lags)) {
    lags <- as.integer(floor(4 * (n / 100)^(2 / 9)))
  } else {
    check_positive(lags, zero_ok = TRUE)
    lags <- as.integer(lags)
  }

  V <- switch(se,
    classical = vcov_classical(X, e),
    hc1 = vcov_hc1(X, e),
    hac = vcov_hac(X, e, lags)
  )
  dimnames(V) <- list(colnames(X), colnames(X))

  structure(
    list(fit = fit, vcov = V, se_type = se, lags = lags, nobs = n, df = n - k,
         formula = formula),
    class = "econ_fit"
  )
}

#' Sandwich pieces
#'
#' Each takes the design matrix `X` and residuals `e` and returns the
#' covariance of the coefficient estimates. `bread` is \eqn{(X'X)^{-1}}; the
#' meat is the estimated covariance of the score \eqn{\sum_t x_t e_t}.
#' @noRd
vcov_classical <- function(X, e) {
  n <- nrow(X)
  k <- ncol(X)
  sigma2 <- sum(e^2) / (n - k)
  sigma2 * solve(crossprod(X))
}

#' @noRd
vcov_hc1 <- function(X, e) {
  n <- nrow(X)
  k <- ncol(X)
  bread <- solve(crossprod(X))
  meat <- crossprod(X * e)          # sum_t e_t^2 x_t x_t'
  (n / (n - k)) * bread %*% meat %*% bread
}

#' @noRd
vcov_hac <- function(X, e, lags) {
  bread <- solve(crossprod(X))
  scores <- X * e                   # rows: x_t e_t
  S <- crossprod(scores)            # lag 0
  if (lags > 0) {
    n <- nrow(scores)
    for (l in seq_len(lags)) {
      w <- 1 - l / (lags + 1)       # Bartlett kernel
      gamma_l <- crossprod(scores[(l + 1):n, , drop = FALSE], scores[1:(n - l), , drop = FALSE])
      S <- S + w * (gamma_l + t(gamma_l))
    }
  }
  bread %*% S %*% bread
}

#' Coefficient table for an `econ_fit`
#'
#' @param x An `econ_fit` from [ols()].
#' @param level Confidence level for the interval.
#'
#' @return A data frame with one row per coefficient: `term`, `estimate`,
#'   `std_error`, `statistic`, `p_value`, `conf_low`, `conf_high`. The
#'   statistic is compared to a t distribution with the residual degrees of
#'   freedom whichever standard errors were chosen.
#'
#' @examples
#' fit <- ols(psavert ~ uempmed, ggplot2::economics, se = "hc1")
#' coef_table(fit)
#' @export
coef_table <- function(x, level = 0.95) {
  if (!inherits(x, "econ_fit")) {
    cli::cli_abort("{.arg x} must be an {.cls econ_fit} from {.fn ols}.")
  }
  if (!is.numeric(level) || length(level) != 1L || level <= 0 || level >= 1) {
    cli::cli_abort("{.arg level} must be between 0 and 1.")
  }
  est <- stats::coef(x$fit)
  se <- sqrt(diag(x$vcov))
  stat <- est / se
  crit <- stats::qt(1 - (1 - level) / 2, df = x$df)
  data.frame(
    term = names(est),
    estimate = unname(est),
    std_error = unname(se),
    statistic = unname(stat),
    p_value = unname(2 * stats::pt(-abs(stat), df = x$df)),
    conf_low = unname(est - crit * se),
    conf_high = unname(est + crit * se),
    stringsAsFactors = FALSE
  )
}

#' @export
coef.econ_fit <- function(object, ...) {
  stats::coef(object$fit)
}

#' @export
vcov.econ_fit <- function(object, ...) {
  object$vcov
}

#' @export
nobs.econ_fit <- function(object, ...) {
  object$nobs
}

#' @export
residuals.econ_fit <- function(object, ...) {
  stats::residuals(object$fit)
}

#' @export
fitted.econ_fit <- function(object, ...) {
  stats::fitted(object$fit)
}

#' @export
print.econ_fit <- function(x, digits = 3, ...) {
  tab <- coef_table(x)
  stars <- ifelse(tab$p_value < 0.01, "***",
                  ifelse(tab$p_value < 0.05, "**", ifelse(tab$p_value < 0.1, "*", "")))
  se_label <- switch(x$se_type,
    classical = "classical",
    hc1 = "heteroskedasticity-robust (HC1)",
    hac = sprintf("Newey-West HAC, %d lag%s", x$lags, if (x$lags == 1) "" else "s")
  )
  cat(sprintf("<OLS: %s>\n", deparse(x$formula)))
  cat(sprintf("  %d observations; %s standard errors\n", x$nobs, se_label))
  out <- data.frame(
    estimate = formatC(tab$estimate, digits = digits, format = "g"),
    std_error = formatC(tab$std_error, digits = digits, format = "g"),
    t = formatC(tab$statistic, digits = digits, format = "g"),
    p = formatC(tab$p_value, digits = 2, format = "g"),
    ` ` = stars,
    row.names = tab$term,
    check.names = FALSE
  )
  print(out, right = TRUE)
  s <- summary(x$fit)
  cat(sprintf("  R-squared %s (adjusted %s); residual s.e. %s on %d df\n",
              formatC(s$r.squared, digits = 3, format = "f"),
              formatC(s$adj.r.squared, digits = 3, format = "f"),
              formatC(s$sigma, digits = digits, format = "g"), x$df))
  invisible(x)
}

#' @export
summary.econ_fit <- function(object, ...) {
  print(object, ...)
}

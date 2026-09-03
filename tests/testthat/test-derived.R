u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)

test_that("Cobb-Douglas demand is a rectangular hyperbola", {
  d <- demand_curve(u, b, prices = c(1, 2, 4, 8))
  expect_named(d, c("price", "quantity", "good"))
  expect_equal(d$quantity, 0.4 * 120 / d$price)
  expect_true(all(d$good == "x"))
  # price * quantity is constant: the fixed expenditure share.
  expect_equal(d$price * d$quantity, rep(48, 4))
})

test_that("demand_curve() can vary the price of y instead", {
  d <- demand_curve(u, b, prices = c(2, 4), good = "y")
  expect_equal(d$quantity, 0.6 * 120 / c(2, 4))
  expect_true(all(d$good == "y"))
})

test_that("the Cobb-Douglas Engel curve is a ray through the origin", {
  e <- engel_curve(u, b, incomes = c(60, 120, 240))
  expect_named(e, c("income", "quantity", "good"))
  expect_equal(e$quantity, 0.4 * e$income / 3)
  expect_equal(engel_curve(u, b, incomes = 120, good = "y")$quantity, 0.6 * 120 / 4)
})

test_that("quasi-linear demand ignores income at an interior optimum", {
  q <- quasilinear(log, f_prime = function(x) 1 / x)
  e <- engel_curve(q, b, incomes = c(60, 120, 240))
  expect_equal(e$quantity, rep(4 / 3, 3))
  # ... while y takes all the extra income
  ey <- engel_curve(q, b, incomes = c(60, 120, 240), good = "y")
  expect_equal(diff(ey$quantity), diff(c(60, 120, 240)) / 4)
})

test_that("the Leontief price-consumption path stays on the ray", {
  l <- leontief(a = 1, b = 2)
  p <- price_consumption_path(l, b, prices = c(1, 3, 9))
  expect_named(p, c("price", "x", "y", "good"))
  expect_equal(p$y, 2 * p$x)
  expect_true(all(diff(p$x) < 0))   # dearer x, less of both
})

test_that("the income-consumption path satisfies each budget", {
  p <- income_consumption_path(u, b, incomes = c(60, 120, 180))
  expect_named(p, c("income", "x", "y"))
  expect_equal(3 * p$x + 4 * p$y, p$income)
  expect_equal(p$y / p$x, rep(0.6 / 0.4 * 3 / 4, 3))   # a ray for Cobb-Douglas
})

test_that("perfect substitutes switch corner as the price crosses the threshold", {
  s <- perfect_substitutes(a = 1, b = 2)
  d <- demand_curve(s, budget(100, 1, 2), prices = c(0.5, 4))
  expect_equal(d$quantity, c(200, 0))
})

test_that("the derived-curve functions validate their inputs", {
  expect_error(demand_curve(u, list(), 1), "budget")
  expect_error(demand_curve(u, b, prices = c(1, -1)), "positive")
  expect_error(demand_curve(u, b, prices = 1, good = "z"), "must be")
  expect_error(engel_curve(u, b, incomes = 0), "positive")
  expect_error(income_consumption_path(u, b, incomes = "a"), "positive")
})

test_that("geom_demand() maps quantity to x and price to y, sorted by price", {
  d <- demand_curve(u, b, prices = c(4, 1, 2))
  layer <- geom_demand(d)
  built <- ggplot2::ggplot_build(ggplot2::ggplot() + layer)$data[[1]]
  expect_equal(built$y, c(1, 2, 4))
  expect_equal(built$x, 48 / c(1, 2, 4))
  expect_error(geom_demand(data.frame(a = 1)), "demand_curve")
})

test_that("geom_engel() maps income to x and quantity to y", {
  e <- engel_curve(u, b, incomes = c(120, 60))
  built <- ggplot2::ggplot_build(ggplot2::ggplot() + geom_engel(e))$data[[1]]
  expect_equal(built$x, c(60, 120))
  expect_error(geom_engel(data.frame(a = 1)), "engel_curve")
})

test_that("geom_budget() draws one segment per budget in a list", {
  bs <- list(budget(60, 3, 4), budget(120, 3, 4), budget(180, 3, 4))
  built <- ggplot2::ggplot_build(ggplot2::ggplot() + geom_budget(bs))$data[[1]]
  expect_identical(nrow(built), 3L)
  expect_equal(built$xend, c(20, 40, 60))
  expect_equal(built$y, c(15, 30, 45))
  # A single budget still works, and a bad list is rejected.
  single <- ggplot2::ggplot_build(ggplot2::ggplot() + geom_budget(b))$data[[1]]
  expect_identical(nrow(single), 1L)
  expect_error(geom_budget(list(b, "not a budget")), "list of them")
  expect_error(geom_budget(list()), "list of them")
})

test_that("geom_budget() recycles linetype across a family of lines", {
  bs <- list(budget(60, 3, 4), budget(120, 3, 4))
  built <- ggplot2::ggplot_build(
    ggplot2::ggplot() + geom_budget(bs, linetype = c("solid", "dashed"))
  )$data[[1]]
  expect_equal(built$linetype, c("solid", "dashed"))
})

test_that("geom_consumption_path() adds a path and points, or just a path", {
  p <- income_consumption_path(u, b, incomes = c(60, 120, 180))
  expect_length(geom_consumption_path(p), 2L)
  expect_length(geom_consumption_path(p, size = 0), 1L)
  built <- ggplot2::ggplot_build(ggplot2::ggplot() + geom_consumption_path(p))$data
  expect_equal(built[[2]]$x, p$x)
  expect_error(geom_consumption_path(data.frame(a = 1)), "columns")
})

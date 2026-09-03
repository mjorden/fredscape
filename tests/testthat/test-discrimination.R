d <- linear_demand(intercept = 100, slope = 1)
students <- linear_demand(intercept = 60, slope = 0.5)
flat <- quadratic_cost(a = 20)
rising <- quadratic_cost(fixed = 50, a = 20, b = 0.25)

## aggregate_demand() --------------------------------------------------------

test_that("aggregate_demand() sums quantities horizontally", {
  both <- aggregate_demand(list(students, d))
  expect_s3_class(both, "general_demand")
  expect_equal(both$q_max, 120 + 100)
  expect_equal(quantity_at(both, 40), 40 + 60, tolerance = 1e-8)
  # Above the students' choke price only the other group buys.
  expect_equal(quantity_at(both, 80), 20, tolerance = 1e-8)
  expect_equal(price_at(both, 100), 40, tolerance = 1e-6)
  expect_equal(price_at(both, 0), 100)
  expect_equal(price_at(both, 500), 0)
  expect_error(aggregate_demand(list(d, "x")), "demand object")
})

test_that("a single demand aggregates to itself", {
  one <- aggregate_demand(d)
  expect_equal(price_at(one, c(10, 50)), c(90, 50), tolerance = 1e-6)
})

## first_degree() -------------------------------------------------------------

test_that("first-degree discrimination is efficient and takes all surplus", {
  fd <- first_degree(d, flat)
  expect_s3_class(fd, "market_outcome")
  expect_equal(fd$quantity, 80)                  # (a - c) / b
  expect_equal(fd$price, 20)                     # last unit at marginal cost
  expect_equal(fd$consumer_surplus, 0)
  expect_equal(fd$producer_surplus, 0.5 * 80 * 80)
  expect_equal(fd$profit_firm, 3200)
  expect_equal(fd$deadweight_loss, 0)
  m <- monopoly(d, flat)
  expect_true(fd$profit_firm > m$profit_firm)
  expect_equal(fd$profit_firm, m$profit_firm + m$consumer_surplus + m$deadweight_loss)
  expect_output(print(fd), "first-degree")
})

test_that("first-degree discrimination with rising marginal cost and a fixed cost", {
  fd <- first_degree(d, rising)
  expect_equal(price_at(d, fd$quantity), marginal_cost(rising, fd$quantity))
  expect_equal(fd$profit_firm, fd$producer_surplus - 50)
  expect_equal(fd$deadweight_loss, 0, tolerance = 1e-8)
})

## third_degree() -------------------------------------------------------------

test_that("third-degree discrimination sets MR = MC in each segment", {
  td <- third_degree(list(students = students, others = d), flat)
  expect_s3_class(td, "third_degree")
  s <- td$segments
  expect_identical(s$segment, c("students", "others"))
  # students: MR = 60 - Q = 20 -> Q = 40, P = 40; others: Q = 40, P = 60.
  expect_equal(s$quantity, c(40, 40))
  expect_equal(s$price, c(40, 60))
  expect_equal(td$quantity, 80)
  expect_equal(td$marginal_cost, 20)
  expect_equal(td$profit, 40 * 40 + 60 * 40 - 20 * 80)
  expect_output(print(td), "students")
})

test_that("the less elastic segment pays more, by the inverse-elasticity rule", {
  s <- third_degree(list(students, d), flat)$segments
  expect_equal(s$lerner, -1 / s$elasticity)
  expect_true(s$price[which.max(abs(s$elasticity))] < s$price[which.min(abs(s$elasticity))])
})

test_that("segmenting beats a uniform price", {
  td <- third_degree(list(students, d), flat)
  expect_s3_class(td$uniform, "market_outcome")
  expect_true(td$profit > td$uniform$profit_firm)
  # The uniform price lies between the two segment prices.
  expect_true(td$uniform$price > min(td$segments$price))
  expect_true(td$uniform$price < max(td$segments$price))
})

test_that("third-degree discrimination with a common rising marginal cost", {
  td <- third_degree(list(students, d), rising)
  mc <- marginal_cost(rising, td$quantity)
  expect_equal(marginal_revenue(students, td$segments$quantity[1]), mc, tolerance = 1e-6)
  expect_equal(marginal_revenue(d, td$segments$quantity[2]), mc, tolerance = 1e-6)
  expect_equal(td$marginal_cost, mc)
})

test_that("a single segment reduces to the ordinary monopoly", {
  td <- third_degree(d, flat)
  expect_equal(td$segments$quantity, monopoly(d, flat)$quantity)
  expect_identical(td$segments$segment, "segment_1")
})

## two_part_tariff() ----------------------------------------------------------

test_that("identical consumers: price at marginal cost, fee equal to surplus", {
  tp <- two_part_tariff(d, flat)
  expect_s3_class(tp, "two_part_tariff")
  expect_equal(tp$price, 20)
  expect_equal(tp$fee, 3200)
  expect_equal(tp$quantity, 80)
  expect_equal(tp$profit, first_degree(d, flat)$profit_firm)
  expect_true(tp$served)
  expect_equal(tp$types$surplus, 0)
  expect_output(print(tp), "fee 3200")
})

test_that("many identical consumers scale the fee revenue", {
  tp <- two_part_tariff(d, flat, n = 10)
  expect_equal(tp$price, 20)
  expect_equal(tp$quantity, 800)
  expect_equal(tp$profit, 10 * 3200)
})

test_that("with rising marginal cost the unit price equals MC at the total quantity", {
  tp <- two_part_tariff(d, rising, n = 4)
  expect_equal(tp$price, marginal_cost(rising, tp$quantity), tolerance = 1e-6)
  expect_equal(tp$fee, consumer_surplus(d, quantity_at(d, tp$price)))
})

test_that("two types: exclude the light users when they are few", {
  light <- linear_demand(intercept = 60, slope = 1)
  tp <- two_part_tariff(list(light = light, heavy = d), flat, n = c(1, 1))
  expect_identical(tp$served, c(FALSE, TRUE))
  expect_equal(tp$price, 20)
  expect_equal(tp$fee, 3200)
  expect_equal(tp$profit, 3200)
  expect_equal(tp$types$quantity[1], 0)
  expect_output(print(tp), "not served")
})

test_that("two types: serve everyone when light users are many, at a price above MC", {
  light <- linear_demand(intercept = 60, slope = 1)
  tp <- two_part_tariff(list(light = light, heavy = d), flat, n = c(5, 1))
  expect_identical(tp$served, c(TRUE, TRUE))
  expect_true(tp$price > 20)                       # the Disneyland result
  expect_equal(tp$fee, consumer_surplus(light, quantity_at(light, tp$price)))
  expect_equal(tp$types$surplus[1], 0)             # light users' surplus is the fee
  expect_true(tp$types$surplus[2] > 0)             # heavy users keep some
  # Better than serving both at marginal cost, and than excluding the light users.
  at_mc <- 6 * consumer_surplus(light, 40)
  expect_true(tp$profit > at_mc)
  expect_true(tp$profit > 3200)
  expect_identical(nrow(tp$candidates), 2L)
})

test_that("two_part_tariff() validates its inputs", {
  expect_error(two_part_tariff(d, flat, n = c(1, 2)), "one per type")
  expect_error(two_part_tariff(d, flat, n = 0), "positive")
  expect_error(two_part_tariff(list(), flat), "demand object")
})

## plot_two_part_tariff() -----------------------------------------------------

test_that("plot_two_part_tariff() builds and picks the fee-setting type", {
  light <- linear_demand(intercept = 60, slope = 1)
  tp <- two_part_tariff(list(light = light, heavy = d), flat, n = c(5, 1))
  p <- plot_two_part_tariff(tp)
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
  expect_match(p$labels$x, "light")
  expect_match(p$labels$subtitle, "Fee")
  heavy <- plot_two_part_tariff(tp, type = "heavy")
  expect_match(heavy$labels$x, "heavy")
  expect_error(plot_two_part_tariff(tp, type = "nobody"), "served type")
  expect_error(plot_two_part_tariff(list()), "two_part_tariff")
  single <- plot_two_part_tariff(two_part_tariff(d, flat))
  expect_s3_class(ggplot2::ggplot_build(single), "ggplot_built")
})

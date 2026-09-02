test_that("observations parse into a tidy three-column frame", {
  df <- parse_observations(read_fixture("observations.json"), series_id = "UNRATE")

  expect_s3_class(df, "data.frame")
  expect_named(df, c("series_id", "date", "value"))
  expect_identical(nrow(df), 6L)
  expect_s3_class(df$date, "Date")
  expect_type(df$value, "double")
  expect_true(all(df$series_id == "UNRATE"))
})

test_that("a missing observation becomes NA without a coercion warning", {
  expect_silent(
    df <- parse_observations(read_fixture("observations.json"), series_id = "UNRATE")
  )
  # FRED writes missing values as "."; row 4 of the fixture is one.
  expect_true(is.na(df$value[df$date == as.Date("2020-04-01")]))
  expect_identical(sum(is.na(df$value)), 1L)
})

test_that("observations come back in date order", {
  df <- parse_observations(read_fixture("observations.json"), series_id = "UNRATE")
  expect_false(is.unsorted(df$date))
})

test_that("an empty observations payload gives a zero-row frame of the right type", {
  df <- parse_observations(list(observations = list()), series_id = "X")
  expect_identical(nrow(df), 0L)
  expect_named(df, c("series_id", "date", "value"))
  expect_s3_class(df$date, "Date")
})

test_that("a truncated payload warns rather than silently dropping rows", {
  body <- read_fixture("observations.json")
  body$count <- 200000
  body$limit <- 100000
  expect_warning(
    parse_observations(body, series_id = "UNRATE"),
    "only"
  )
})

test_that("series metadata parses, with dates and popularity typed", {
  df <- parse_series_meta(read_fixture("series.json"))

  expect_identical(nrow(df), 1L)
  expect_identical(df$series_id, "UNRATE")
  expect_identical(df$title, "Unemployment Rate")
  expect_identical(df$units_short, "%")
  expect_s3_class(df$observation_start, "Date")
  expect_type(df$popularity, "double")
})

test_that("search results parse into the same shape as series metadata", {
  search <- parse_series_meta(read_fixture("search.json"))
  info <- parse_series_meta(read_fixture("series.json"))

  expect_identical(names(search), names(info))
  expect_identical(nrow(search), 2L)
  expect_identical(search$series_id, c("UNRATE", "UNRATENSA"))
})

test_that("a field absent from the payload becomes NA, not an error", {
  # The search fixture has no `notes`, which FRED omits for some series.
  search <- parse_series_meta(read_fixture("search.json"))
  expect_true(all(is.na(search$notes)))
})

test_that("an empty seriess payload gives a typed zero-row frame", {
  df <- parse_series_meta(list(seriess = list()))
  expect_identical(nrow(df), 0L)
  expect_identical(names(df), names(parse_series_meta(read_fixture("series.json"))))
  expect_s3_class(df$observation_start, "Date")
})

test_that("bad arguments are caught before any network call", {
  withr::local_envvar(FRED_API_KEY = "")

  expect_error(fred_series(1), "character vector")
  expect_error(fred_series(character(0)), "character vector")
  expect_error(fred_series("UNRATE", units = "bogus"), "units")
  expect_error(fred_series("UNRATE", frequency = "hourly"), "frequency")
  expect_error(fred_series("UNRATE", aggregation_method = "median"), "aggregation_method")
  expect_error(fred_series("UNRATE", start = "yesterday"), "must be a single date")

  expect_error(fred_search(""), "non-empty string")
  expect_error(fred_search("cpi", limit = 0), "between 1 and 1000")
  expect_error(fred_search("cpi", limit = 5000), "between 1 and 1000")
  expect_error(fred_search("cpi", order_by = "relevance"), "order_by")

  expect_error(fred_series_info(NA_character_), "character vector")
})

test_that("a missing key is only demanded once the arguments are valid", {
  withr::local_envvar(FRED_API_KEY = "")
  expect_error(fred_series("UNRATE"), "No FRED API key")
})

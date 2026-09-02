test_that("fred_key() errors with a pointer to the sign-up page", {
  withr::local_envvar(FRED_API_KEY = "")
  expect_false(fred_has_key())
  expect_error(fred_key(), "No FRED API key")
})

test_that("fred_key() returns the key when one is set", {
  key <- strrep("a", 32)
  withr::local_envvar(FRED_API_KEY = key)
  expect_true(fred_has_key())
  expect_identical(fred_key(), key)
})

test_that("keys of the wrong shape are rejected locally", {
  expect_error(validate_key("too-short"), "does not look like")
  expect_error(validate_key(strrep("A", 32)), "does not look like")
  expect_error(validate_key(c(strrep("a", 32), strrep("b", 32))), "single string")
  expect_error(validate_key(NA), "single string")
})

test_that("the rejection message does not echo the key", {
  secret <- paste0(strrep("z", 31), "!")
  err <- tryCatch(validate_key(secret), error = function(e) conditionMessage(e))
  expect_false(grepl(secret, err, fixed = TRUE))
})

test_that("fred_set_key() returns the previous value so it can be restored", {
  withr::local_envvar(FRED_API_KEY = strrep("a", 32))
  old <- fred_set_key(strrep("b", 32))
  expect_identical(old, strrep("a", 32))
  expect_identical(fred_key(), strrep("b", 32))
})

# Load a saved FRED payload the way the client would receive it: nested lists,
# no simplification. Keeping this in one place means the parser tests exercise
# exactly the structure httr2::resp_body_json() hands over.
read_fixture <- function(name) {
  skip_if_not_installed("jsonlite")
  jsonlite::fromJSON(
    testthat::test_path("fixtures", name),
    simplifyVector = FALSE
  )
}

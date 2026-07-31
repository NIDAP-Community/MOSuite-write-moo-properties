test_that("syncweaver lock embeds MOSuite main", {
  repo_root <- normalizePath(
    file.path(testthat::test_path(), "..", ".."),
    mustWork = TRUE
  )
  lock <- jsonlite::read_json(
    file.path(repo_root, ".syncweaver-lock.json"),
    simplifyVector = TRUE
  )
  mosuite_source <- lock$sources[["code/MOSuite"]]

  expect_equal(mosuite_source$repo_url, "https://github.com/CCBR/MOSuite")
  expect_equal(mosuite_source$ref, "main")
  expect_match(mosuite_source$git_sha, "^[0-9a-f]{40}$")
})

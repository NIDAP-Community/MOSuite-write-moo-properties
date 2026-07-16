test_that("code/run executes successfully with default CLI arguments", {
  setup <- setup_cli_workspace("mosuite_write_moo_props_test_")
  on.exit(unlink(setup$workspace, recursive = TRUE), add = TRUE)

  test_data_file <- file.path(
    setup$repo_root,
    "tests",
    "data",
    "moo-diff-filt.rds"
  )

  expect_true(
    file.exists(test_data_file),
    info = paste("Test data file should exist at", test_data_file)
  )
  file.copy(
    test_data_file,
    file.path(setup$data_dir, "moo.rds"),
    overwrite = TRUE
  )

  prepare_main_and_mosuite(setup$repo_root, setup$code_dir)

  old_wd <- getwd()
  setwd(setup$code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  exit_code <- system2("bash", args = c("run"))
  expect_equal(exit_code, 0, info = "run script should execute without error")

  output_dir <- file.path(setup$results_dir, "moo-properties")
  expect_true(
    dir.exists(output_dir),
    info = "Output directory moo-properties should be created"
  )

  assert_properties_output(output_dir)
})

test_that("code/run executes with custom output directory argument", {
  setup <- setup_cli_workspace("mosuite_write_moo_props_custom_test_")
  on.exit(unlink(setup$workspace, recursive = TRUE), add = TRUE)

  test_data_file <- file.path(
    setup$repo_root,
    "tests",
    "data",
    "moo-diff-filt.rds"
  )

  file.copy(
    test_data_file,
    file.path(setup$data_dir, "moo.rds"),
    overwrite = TRUE
  )

  prepare_main_and_mosuite(setup$repo_root, setup$code_dir)

  old_wd <- getwd()
  setwd(setup$code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  custom_output_dir <- "custom-output"
  exit_code <- system2(
    "bash",
    args = c(
      "run",
      paste0("--output_dir=", custom_output_dir)
    )
  )

  expect_equal(
    exit_code,
    0,
    info = "run script with custom output_dir should execute without error"
  )

  custom_path <- file.path(setup$results_dir, custom_output_dir)
  expect_true(
    dir.exists(custom_path),
    info = paste("Custom output directory should be created at", custom_path)
  )

  assert_properties_output(custom_path, label = "custom output")
})

test_that("code/run creates readable property files from input data", {
  setup <- setup_cli_workspace("mosuite_write_moo_props_validation_test_")
  on.exit(unlink(setup$workspace, recursive = TRUE), add = TRUE)

  test_data_file <- file.path(
    setup$repo_root,
    "tests",
    "data",
    "moo-diff-filt.rds"
  )

  input_moo <- readr::read_rds(test_data_file)
  file.copy(
    test_data_file,
    file.path(setup$data_dir, "moo.rds"),
    overwrite = TRUE
  )

  prepare_main_and_mosuite(setup$repo_root, setup$code_dir)

  old_wd <- getwd()
  setwd(setup$code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  exit_code <- system2("bash", args = c("run"))
  expect_equal(exit_code, 0)

  expect_true(
    S7::S7_inherits(input_moo, MOSuite::multiOmicDataSet),
    info = "Input should be a multiOmicDataSet object"
  )
  expect_true(
    nrow(input_moo@sample_meta) > 0,
    info = "Input MOO should have sample metadata"
  )
  expect_true(
    nrow(input_moo@annotation) > 0,
    info = "Input MOO should have annotation data"
  )
  expect_true(
    length(input_moo@counts) > 0,
    info = "Input MOO should have count data"
  )

  output_dir <- file.path(setup$results_dir, "moo-properties")
  assert_properties_output(output_dir)

  written_sample_meta <- readr::read_csv(
    file.path(output_dir, "sample_metadata.csv"),
    show_col_types = FALSE
  )
  expect_equal(
    nrow(written_sample_meta),
    nrow(input_moo@sample_meta),
    info = "Written sample metadata should have same number of rows as input"
  )

  written_annotation <- readr::read_csv(
    file.path(output_dir, "feature_annotation.csv"),
    show_col_types = FALSE
  )
  expect_equal(
    nrow(written_annotation),
    nrow(input_moo@annotation),
    info = "Written annotation should have same number of rows as input"
  )
})

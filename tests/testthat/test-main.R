assert_properties_output <- function(output_dir, label = "") {
  label_prefix <- if (nzchar(label)) paste0(label, " ") else ""

  expect_true(
    file.exists(file.path(output_dir, "sample_metadata.csv")),
    info = paste0(label_prefix, "sample_metadata.csv should be created")
  )
  expect_true(
    file.exists(file.path(output_dir, "feature_annotation.csv")),
    info = paste0(label_prefix, "feature_annotation.csv should be created")
  )
  expect_true(
    dir.exists(file.path(output_dir, "counts")),
    info = paste0(label_prefix, "counts/ subdirectory should be created")
  )
  expect_true(
    dir.exists(file.path(output_dir, "analyses")),
    info = paste0(label_prefix, "analyses/ subdirectory should be created")
  )

  count_files <- list.files(file.path(output_dir, "counts"), recursive = TRUE)
  expect_true(
    length(count_files) > 0,
    info = paste0(label_prefix, "counts/ should contain count type files")
  )

  analyses_files <- list.files(
    file.path(output_dir, "analyses"),
    recursive = TRUE
  )
  expect_true(
    length(analyses_files) > 0,
    info = paste0(
      label_prefix,
      "analyses/ should contain analysis result files"
    )
  )
}

prepare_main_and_mosuite <- function(repo_root, code_dir) {
  copied_main <- file.copy(
    file.path(repo_root, "code", "main.R"),
    file.path(code_dir, "main.R")
  )
  copied_run <- file.copy(
    file.path(repo_root, "code", "run"),
    file.path(code_dir, "run")
  )
  copied_mosuite <- file.copy(
    file.path(repo_root, "code", "MOSuite"),
    code_dir,
    recursive = TRUE
  )
  expect_true(copied_main, info = "Failed to copy code/main.R into test workspace")
  expect_true(copied_run, info = "Failed to copy code/run into test workspace")
  expect_true(
    copied_mosuite,
    info = "Failed to copy code/MOSuite subtree into test workspace"
  )
  main_file <- file.path(code_dir, "main.R")
  load_all_call <- "devtools::load_all('/code/MOSuite')"
  main_lines <- readLines(main_file)
  updated_lines <- gsub(
    load_all_call,
    "devtools::load_all('MOSuite')",
    main_lines,
    fixed = TRUE
  )
  expect_false(
    identical(main_lines, updated_lines),
    info = "main.R patch failed: expected load_all('/code/MOSuite')"
  )
  writeLines(updated_lines, main_file)
}

test_that("code/run executes successfully with default CLI arguments", {
  # Create temporary workspace
  workspace <- tempfile("mosuite_write_moo_props_test_")
  dir.create(workspace)
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)

  # Set up directory structure
  code_dir <- file.path(workspace, "code")
  data_dir <- file.path(workspace, "data")
  results_dir <- file.path(code_dir, "..", "results")
  dir.create(code_dir)
  dir.create(data_dir)
  dir.create(results_dir)

  # Get test data from package tests directory
  repo_root <- normalizePath(file.path(dirname(getwd()), ".."))
  test_data_file <- file.path(repo_root, "tests", "data", "moo-diff-filt.rds")

  expect_true(
    file.exists(test_data_file),
    info = paste("Test data file should exist at", test_data_file)
  )
  file.copy(test_data_file, file.path(data_dir, "moo.rds"))

  # Copy main.R and run script to workspace
  prepare_main_and_mosuite(repo_root, code_dir)

  # Run the script from code directory
  old_wd <- getwd()
  setwd(code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  # Execute run script with default CLI arguments
  exit_code <- system2(
    "bash",
    args = c("run")
  )

  # Check for successful execution
  expect_equal(exit_code, 0, info = "run script should execute without error")

  # Validate output directory structure
  output_dir <- file.path(results_dir, "moo-properties")
  expect_true(
    dir.exists(output_dir),
    info = "Output directory moo-properties should be created"
  )

  # Check that expected property files were created
  assert_properties_output(output_dir)
})

test_that("code/run executes with custom output directory argument", {
  # Create temporary workspace
  workspace <- tempfile("mosuite_write_moo_props_custom_test_")
  dir.create(workspace)
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)

  # Set up directory structure
  code_dir <- file.path(workspace, "code")
  data_dir <- file.path(workspace, "data")
  results_dir <- file.path(code_dir, "..", "results")
  dir.create(code_dir)
  dir.create(data_dir)
  dir.create(results_dir)

  # Get test data from package tests directory
  repo_root <- normalizePath(file.path(dirname(getwd()), ".."))
  test_data_file <- file.path(repo_root, "tests", "data", "moo-diff-filt.rds")

  file.copy(test_data_file, file.path(data_dir, "moo.rds"))

  # Copy main.R and run script to workspace
  prepare_main_and_mosuite(repo_root, code_dir)

  # Run the script from code directory
  old_wd <- getwd()
  setwd(code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  # Execute run script with custom output directory
  custom_output_dir <- "custom-output"
  exit_code <- system2(
    "bash",
    args = c(
      "run",
      paste0("--output_dir=", custom_output_dir)
    )
  )

  # Check for successful execution
  expect_equal(
    exit_code,
    0,
    info = "run script with custom output_dir should execute without error"
  )

  # Validate custom output directory exists
  custom_path <- file.path(results_dir, custom_output_dir)
  expect_true(
    dir.exists(custom_path),
    info = paste("Custom output directory should be created at", custom_path)
  )

  # Check that expected property files were created in custom directory
  assert_properties_output(custom_path, label = "custom output")
})

test_that("code/run creates readable property files from input data", {
  # Create temporary workspace
  workspace <- tempfile("mosuite_write_moo_props_validation_test_")
  dir.create(workspace)
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)

  # Set up directory structure
  code_dir <- file.path(workspace, "code")
  data_dir <- file.path(workspace, "data")
  results_dir <- file.path(code_dir, "..", "results")
  dir.create(code_dir)
  dir.create(data_dir)
  dir.create(results_dir)

  # Get test data
  repo_root <- normalizePath(file.path(dirname(getwd()), ".."))
  test_data_file <- file.path(repo_root, "tests", "data", "moo-diff-filt.rds")

  # Load the input MOO to verify properties later
  input_moo <- readr::read_rds(test_data_file)
  file.copy(test_data_file, file.path(data_dir, "moo.rds"))

  # Copy main.R and run script to workspace
  prepare_main_and_mosuite(repo_root, code_dir)

  # Run the script from code directory
  old_wd <- getwd()
  setwd(code_dir)
  on.exit(setwd(old_wd), add = TRUE)

  # Execute run script
  exit_code <- system2(
    "bash",
    args = c("run")
  )

  expect_equal(exit_code, 0)

  # Verify that the input MOO has expected components
  expect_true(
    S7::S7_inherits(input_moo, MOSuite::multiOmicDataSet),
    info = "Input should be a multiOmicDataSet object"
  )

  # Check that it has sample metadata, annotation, and counts
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

  # Verify output files were created
  output_dir <- file.path(results_dir, "moo-properties")
  expect_true(dir.exists(output_dir))

  # Validate all required CSV files exist
  expect_true(
    file.exists(file.path(output_dir, "sample_metadata.csv")),
    info = "sample_metadata.csv should be created"
  )
  expect_true(
    file.exists(file.path(output_dir, "feature_annotation.csv")),
    info = "feature_annotation.csv should be created"
  )

  # Validate subdirectories exist
  expect_true(
    dir.exists(file.path(output_dir, "counts")),
    info = "counts/ subdirectory should be created"
  )
  expect_true(
    dir.exists(file.path(output_dir, "analyses")),
    info = "analyses/ subdirectory should be created"
  )

  # Verify count files match input count types
  count_types <- names(input_moo@counts)
  for (count_type in count_types) {
    counts_dat <- input_moo@counts[[count_type]]
    if (inherits(counts_dat, "list")) {
      # Nested list counts - check for subdirectory
      sub_dir <- file.path(output_dir, "counts", count_type)
      expect_true(
        dir.exists(sub_dir),
        info = glue::glue(
          "counts/{count_type}/ subdirectory should exist for nested counts"
        )
      )
      for (sub_count_type in names(counts_dat)) {
        csv_file <- file.path(sub_dir, paste0(sub_count_type, "_counts.csv"))
        expect_true(
          file.exists(csv_file),
          info = glue::glue(
            "{sub_count_type}_counts.csv should exist in counts/{count_type}/"
          )
        )
      }
    } else {
      # Simple data frame counts
      csv_file <- file.path(
        output_dir,
        "counts",
        paste0(count_type, "_counts.csv")
      )
      expect_true(
        file.exists(csv_file),
        info = glue::glue("{count_type}_counts.csv should exist in counts/")
      )
    }
  }

  # Verify analyses files exist
  analyses_names <- names(input_moo@analyses)
  for (analysis_name in analyses_names) {
    analysis_dat <- input_moo@analyses[[analysis_name]]
    if (inherits(analysis_dat, "list")) {
      # Nested list analyses - check for subdirectory
      sub_dir <- file.path(output_dir, "analyses", analysis_name)
      expect_true(
        dir.exists(sub_dir),
        info = glue::glue(
          "analyses/{analysis_name}/ subdirectory should exist for nested analyses"
        )
      )
    } else if (inherits(analysis_dat, "data.frame")) {
      # Data frame analyses - check for CSV file
      csv_file <- file.path(
        output_dir,
        "analyses",
        paste0(analysis_name, ".csv")
      )
      expect_true(
        file.exists(csv_file),
        info = glue::glue("{analysis_name}.csv should exist in analyses/")
      )
    } else {
      # Other analyses - check for RDS file
      rds_file <- file.path(
        output_dir,
        "analyses",
        paste0(analysis_name, ".rds")
      )
      expect_true(
        file.exists(rds_file),
        info = glue::glue("{analysis_name}.rds should exist in analyses/")
      )
    }
  }

  # Verify written sample metadata can be read and has correct dimensions
  written_sample_meta <- readr::read_csv(
    file.path(output_dir, "sample_metadata.csv"),
    show_col_types = FALSE
  )
  expect_equal(
    nrow(written_sample_meta),
    nrow(input_moo@sample_meta),
    info = "Written sample metadata should have same number of rows as input"
  )
  expect_equal(
    ncol(written_sample_meta),
    ncol(input_moo@sample_meta),
    info = "Written sample metadata should have same number of columns as input"
  )

  # Verify written annotation can be read and has correct dimensions
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

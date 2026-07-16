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

setup_cli_workspace <- function(prefix = "mosuite_write_moo_props_test_") {
  workspace <- tempfile(prefix)
  dir.create(workspace)

  code_dir <- file.path(workspace, "code")
  data_dir <- file.path(workspace, "data")
  results_dir <- file.path(workspace, "results")
  dir.create(code_dir, recursive = TRUE)
  dir.create(data_dir, recursive = TRUE)
  dir.create(results_dir, recursive = TRUE)

  repo_root <- normalizePath(
    file.path(testthat::test_path(), "..", ".."),
    mustWork = TRUE
  )

  list(
    workspace = workspace,
    code_dir = code_dir,
    data_dir = data_dir,
    results_dir = results_dir,
    repo_root = repo_root
  )
}

prepare_main_and_mosuite <- function(repo_root, code_dir) {
  copied_main <- file.copy(
    file.path(repo_root, "code", "main.R"),
    file.path(code_dir, "main.R"),
    overwrite = TRUE
  )
  copied_run <- file.copy(
    file.path(repo_root, "code", "run"),
    file.path(code_dir, "run"),
    overwrite = TRUE
  )
  copied_mosuite <- file.copy(
    file.path(repo_root, "code", "MOSuite"),
    code_dir,
    recursive = TRUE
  )
  expect_true(
    copied_main,
    info = "Failed to copy code/main.R into test workspace"
  )
  expect_true(copied_run, info = "Failed to copy code/run into test workspace")
  expect_true(
    copied_mosuite,
    info = "Failed to copy code/MOSuite subtree into test workspace"
  )
  main_file <- file.path(code_dir, "main.R")
  load_all_pattern <- "devtools::load_all\\(\\s*['\\\"]/code/MOSuite['\\\"]\\s*\\)"
  main_lines <- readLines(main_file)
  expect_true(
    any(grepl(load_all_pattern, main_lines)),
    info = "main.R does not contain expected load_all('/code/MOSuite')"
  )
  updated_lines <- gsub(
    load_all_pattern,
    "devtools::load_all('MOSuite')",
    main_lines
  )
  expect_false(
    any(grepl(load_all_pattern, updated_lines)),
    info = "main.R patch failed: original /code/MOSuite load_all call still present"
  )
  expect_true(
    any(grepl("devtools::load_all\\('MOSuite'\\)", updated_lines)),
    info = "main.R patch failed: expected local MOSuite load_all call"
  )
  writeLines(updated_lines, main_file)
}

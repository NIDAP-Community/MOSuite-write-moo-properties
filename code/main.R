#!/usr/bin/env Rscript
library(argparse)
library(glue)
devtools::load_all('/code/MOSuite')

# set up capsule environment
setup_capsule_environment()

# parse CLI arguments
parser <- ArgumentParser(
  description = "Write multiOmicDataSet properties to disk"
)

parser$add_argument(
  "--output_dir",
  type = "character",
  default = "moo-properties",
  help = "Directory in results/ where properties will be saved as individual CSV and/or RDS files"
)

args <- parser$parse_args()

# load multiOmicDataSet from data directory
moo <- load_moo_from_data_dir()

# write multiOmicDataSet properties
output_path <- file.path("..", "results", args$output_dir)
message(glue("Writing results to {output_path}"))
write_multiOmicDataSet_properties(moo, output_dir = output_path)

#!/usr/bin/env Rscript
rlang::global_entrace()
library(argparse)
library(glue)
library(MOSuite)

# set up capsule environment
setup_capsule_environment()

# parse CLI arguments
parser <- ArgumentParser(description = "Write multiOmicDataSet properties to disk")

parser$add_argument("--output_dir", type="character", default="moo", help="Directory where properties will be saved")

args <- parser$parse_args()

# load multiOmicDataSet from data directory
moo <- load_moo_from_data_dir()

# write multiOmicDataSet properties
output_path <- file.path("..", "results", args$output_dir)
message(glue("Writing results to {output_path}"))
write_multiOmicDataSet_properties(moo, output_dir = output_path)
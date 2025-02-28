#####################################################
# Clean hospital data before loading into SQL database
# Author: Julia Muller
# Date: 2 December 2024
# Last modified: February 2025
#####################################################

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
})

# Source utility functions
source('scripts/utils.R')

# Import raw hospital data
data <- read_csv('source_data/hospital_data.csv', show_col_types = F)

# Ensure all column names are lowercase and replace spaces with underscores
col_names <- names(data) %>%
  str_to_lower(.) %>%
  str_replace_all(., ' ',  '_')
names(data) <- col_names

# Create admission ID column and tidy column names
data <- data %>%
  rowid_to_column(.) %>%
  rename(zip_code = `zip_code_-_3_digits`,
         admission_id = rowid)

# Save cleaned data set
ensure_directory('derived_data')
write_csv(data, 'derived_data/hospital_discharges_tidied.csv')

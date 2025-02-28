
suppressPackageStartupMessages(library(tidyverse))

source('scripts/utils.R')

data <- read_csv('source_data/hospital_data.csv', show_col_types = F)

# Ensure all column names are lowercase with no spaces
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
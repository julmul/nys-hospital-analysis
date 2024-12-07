library(tidyverse)

source('scripts/utils.R')

data <- read_csv('source_data/NYS_hospital_discharges_2022_20241004.csv')

col_names <- names(data) %>%
  str_to_lower(.) %>%
  str_replace_all(., ' ',  '_')
names(data) <- col_names

data <- data %>%
  rowid_to_column(.) %>%
  rename(zip_code = `zip_code_-_3_digits`,
         admission_id = rowid)

ensure_directory('derived_data')
write_csv(data, 'derived_data/hospital_discharges_tidied.csv')

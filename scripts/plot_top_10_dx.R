library(tidyverse)
library(RSQLite)
library(forcats)

source('scripts/utils.R')

conn <- dbConnect(RSQLite::SQLite(), dbname = 'derived_data/hospital-discharges.db')
hospitals <- dbGetQuery(conn, 'SELECT admission_id, hospital_service_area FROM hospital')
clinical <- dbGetQuery(conn, 'SELECT admission_id, apr_drg_description, apr_drg_code FROM clinical')
dbDisconnect(conn)

# Summarize diagnoses, removing major birth codes
dx <- clinical %>% 
  filter(!(apr_drg_code %in% c(540, 640, 560))) %>%
  group_by(apr_drg_code, apr_drg_description) %>%
  summarize(n = n()) %>%
  arrange(desc(n))

# Select top 10 diagnoses
top_10_dx <-dx[1:10, ]

# Calculate proportion of top diagnoses by hospital service area
dx_by_region <- clinical %>%
  filter(apr_drg_code %in% top_10_dx$apr_drg_code) %>%
  left_join(hospitals, by = 'admission_id') %>%
  group_by(hospital_service_area, apr_drg_description) %>%
  summarize(n = n()) %>%
  ungroup() %>%
  group_by(hospital_service_area) %>%
  mutate(n_prop = n/sum(n)) %>%
  filter(!is.na(hospital_service_area)) %>%
  ungroup()

# Reorder by descending diagnosis
dx_by_region$apr_drg_description <- forcats::fct_reorder(dx_by_region$apr_drg_description, dx_by_region$n_prop, .fun = median, .desc = TRUE)

# Plot most common diagnosis by hospital service area
plt <- ggplot(data = dx_by_region) +
  geom_bar(aes(x = apr_drg_description, y = n_prop, fill = hospital_service_area), stat = 'identity', position = 'dodge') +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 20)) +
  scale_fill_manual(values = c('#E69F00', '#56B4E9', '#009E73', '#F0E442', '#0072B2', '#D55E00', '#CC79A7', '#000000')) +
  labs(x = 'APR-DRG Diagnosis Description', y = 'Proportion of Patients', fill = 'Hospital Service Area')

# Save figure
ggsave('figures/top_10_diagnosis_overall.png', plt, height = 6, width = 8, dpi = 600)

#####################################################
# Generate bar plot of top diagnoses in dataset
# Author: Julia Muller
# Date: 6 December 2024
# Last modified: February 2025
#####################################################

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(RSQLite)
  library(forcats) 
})

# Source utility functions
source('scripts/utils.R')

# Pull hospital and clinical data from database
hospitals <- query_db('SELECT admission_id, hospital_service_area FROM hospital')
clinical <- query_db('SELECT admission_id, apr_drg_description, apr_drg_code FROM clinical')

# Remove birth codes and summarize remaining top 10 diagnoses
top_10_dx <- clinical %>% 
  filter(!(apr_drg_code %in% c(540, 640, 560))) %>%
  group_by(apr_drg_code, apr_drg_description) %>%
  summarize(n = n(), .groups = 'drop') %>%
  arrange(desc(n)) %>%
  slice_head(n = 10)

# Calculate proportion of top diagnoses by hospital service area
dx_by_region <- clinical %>%
  filter(apr_drg_code %in% top_10_dx$apr_drg_code) %>%
  left_join(hospitals, by = 'admission_id') %>%
  group_by(hospital_service_area, apr_drg_description) %>%
  summarize(n = n(), .groups = 'drop') %>%
  group_by(hospital_service_area) %>%
  mutate(n_prop = n/sum(n)) %>%
  filter(!is.na(hospital_service_area)) %>%
  ungroup()

# Simplify diagnosis naming for plotting
dx_by_region <- dx_by_region %>%
  mutate(apr_drg_description = case_when(
    apr_drg_description == 'SEPTICEMIA AND DISSEMINATED INFECTIONS' ~ 'Sepsis',
    apr_drg_description == 'MAJOR RESPIRATORY INFECTIONS AND INFLAMMATIONS' ~ 'Major Respiratory Infections',
    apr_drg_description == 'HEART FAILURE' ~ 'Heart Failure',
    apr_drg_description == 'SCHIZOPHRENIA' ~ 'Schizophrenia',
    apr_drg_description == 'KIDNEY AND URINARY TRACT INFECTIONS' ~ 'Kidney Infections',
    apr_drg_description == 'CVA AND PRECEREBRAL OCCLUSION WITH INFARCTION' ~ 'Stroke',
    apr_drg_description == 'OTHER PNEUMONIA' ~ 'Pneumonia',
    apr_drg_description == 'CARDIAC ARRHYTHMIA AND CONDUCTION DISORDERS' ~ 'Cardiac Arrhythmia',
    apr_drg_description == 'ACUTE KIDNEY INJURY' ~ 'Acute Kidney Injury',
    apr_drg_description == 'SEIZURE' ~ 'Seizures',
    TRUE ~ apr_drg_description))

# Reorder by descending diagnosis
dx_by_region <- dx_by_region %>%
  mutate(apr_drg_description = fct_reorder(apr_drg_description, n_prop, .fun = median, .desc = TRUE))

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

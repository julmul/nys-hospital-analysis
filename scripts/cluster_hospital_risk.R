#####################################################
# Perform k-means clustering of hospital risk
# Author: Julia Muller
# Date: 7 December 2024
# Last modified: February 2025
#####################################################

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(RSQLite)
  library(sf)
})

# Source utility functions
source('scripts/utils.R')

# Pull hospital, clinical, and payment data from database
hospital <- query_db('SELECT admission_id, facility_name, permanent_facility_id, hospital_service_area, hospital_county FROM hospital')
clinical <- query_db('SELECT admission_id, length_of_stay, apr_risk_of_mortality, apr_severity_of_illness_code FROM clinical')
payment <- query_db('SELECT admission_id, total_charges FROM payment')

# Import shapefiles and GPS data
nys <- read_sf('source_data/Counties_Shoreline.shp')
gps <- read_csv('source_data/hospital_gps_coords.csv', show_col_types = F)

# Combine and clean the data
data <- hospital %>%
  full_join(clinical, by = 'admission_id') %>%
  full_join(payment, by = 'admission_id') %>%
  filter(complete.cases(.)) %>% 
  mutate(apr_risk_of_mortality_code = case_when(
      apr_risk_of_mortality == 'Minor' ~ 1,
      apr_risk_of_mortality == 'Moderate' ~ 2,
      apr_risk_of_mortality == 'Major' ~ 3,
      apr_risk_of_mortality == 'Complete' ~ 4))

# Summarize data at the hospital level
hospital_data <- data %>%
  group_by(permanent_facility_id) %>%
  summarize(
    avg_apr_risk_of_mortality = mean(apr_risk_of_mortality_code, na.rm = TRUE),
    avg_apr_severity_of_illness = mean(apr_severity_of_illness_code, na.rm = TRUE),
    avg_length_of_stay = mean(length_of_stay, na.rm = TRUE),
    avg_total_charges = mean(total_charges, na.rm = TRUE))

# Scale hospital data and perform k-means clustering
hospital_data_scaled <- scale(hospital_data[ , -1])
set.seed(123)
kmeans_result <- kmeans(hospital_data_scaled, centers = 2, nstart = 25)
hospital_data$high_risk_cluster <- kmeans_result$cluster

# Visualize hospital clusters
plt <- ggplot(hospital_data, aes(x = avg_length_of_stay, y = avg_apr_risk_of_mortality, color = factor(high_risk_cluster))) +
  geom_point() +
  labs(x = 'Average Length of Stay',
       y = 'Average APR Risk of Mortality',
       color = 'Cluster') +
  theme_minimal()

# Check major high-risk outliers
data %>% filter(permanent_facility_id == '001138') %>% distinct(facility_name, hospital_county) # Blythedale Children's Hospital (Westchester)
data %>% filter(permanent_facility_id == '001486') %>% distinct(facility_name, hospital_county) # Henry J. Carter Specialty Hospital (Manhattan)
data %>% filter(permanent_facility_id == '001175') %>% distinct(facility_name, hospital_county) # Calvary Hospital Inc (Bronx)
data %>% filter(permanent_facility_id == '010223') %>% distinct(facility_name, hospital_county) # Calvary Hospital.(Kings)

# Summarize cluster statistics
aggregate(cbind(avg_apr_risk_of_mortality, avg_apr_severity_of_illness, avg_length_of_stay) ~ high_risk_cluster, data = hospital_data, FUN = mean)

# Merge GPS with hospital clusters
gps <- gps %>%
  st_as_sf(coords = c('longitude', 'latitude'), crs = 4326) %>%
  left_join(hospital_data, by = 'permanent_facility_id') %>%
  mutate(high_risk_cluster = if_else(high_risk_cluster == 1, 'Low-Risk', 'High-Risk'))

# Visualize hospital clusters on map of NYS
map <- ggplot() +
  geom_sf(data = nys, color = 'black', fill = 'grey') +
  geom_sf(data = gps, aes(fill = factor(high_risk_cluster)), shape = 21, stroke = 0.5) +
  labs(fill = 'Hospital Cluster') +
  theme_void()

# Save figures
ensure_directory('figures')
ggsave('figures/hospital_clusters_high_risk.png', plt, height = 7, width = 7, dpi = 600)
write_rds(map, 'figures/nys_map_hospital_clusters.rds')

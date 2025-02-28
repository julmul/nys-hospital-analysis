#####################################################
# Generate map of NYS hospital service areas
# Author: Julia Muller
# Date: 5 December 2024
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

# Pull hospital data from database
hospitals <- query_db('SELECT hospital_service_area, hospital_county FROM hospital')

# Import NYS shape file
nys <- read_sf('source_data/Counties_Shoreline.shp')

# Get hospital counties and hospital service areas
hospitals_summarized <- hospitals %>%
  distinct(hospital_service_area, hospital_county)

# Group and summarize geometries by hospital service area
hsa <- nys %>%
  left_join(hospitals_summarized, by = c('NAME' = 'hospital_county')) %>%
  mutate(hospital_service_area = case_when(
    NAME == 'Seneca' ~ 'Finger Lakes',
    NAME == 'Tioga' ~ 'Southern Tier',
    NAME == 'Washington' ~ 'Capital/Adirond',
    NAME == 'Greene' ~ 'Capital/Adirond',
    NAME == 'Hamilton' ~ 'Capital/Adirond',
    NAME == 'New York' ~ 'New York City',
    TRUE ~ hospital_service_area)) %>%
  group_by(hospital_service_area) %>%
  summarize(geometry = st_union(geometry), .groups = 'drop')

# Calculate centroids of each hospital service area for labeling
centroids <- st_centroid(hsa)
centroids$labels <- hsa$hospital_service_area
centroid_coords <- st_coordinates(centroids)
centroids <- cbind(centroids, centroid_coords)

# Plot hospital service areas in NYS
plt <- ggplot() +
  geom_sf(data = hsa) +
  theme_void() +
  geom_text(data = centroids, aes(x = X, y = Y, label = labels), color = 'black', size = 3) +
  coord_sf(expand = FALSE)

# Save figure
ensure_directory('figures')
ggsave('figures/nys_hospital_service_areas.png', plt, height = 7, width = 7, dpi = 600)
write_rds(plt, 'figures/nys_hospital_service_areas.rds')

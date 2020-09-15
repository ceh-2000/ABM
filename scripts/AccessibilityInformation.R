rm(list = ls(all = TRUE))

library(raster)
library(sf)
library(tidyverse)
library(maptools)
library(spatstat)
library(units)

setwd("~/Desktop/data-science/data")

load("Rdata/urban_areas.RData")
load("Rdata/pigg_adm2.RData")

# Read in road shape file
# Data source: https://data.humdata.org/dataset/hotosm_swz_roads
LMIC_roads <- read_sf("hotosm_swz_roads_lines_shp/hotosm_swz_roads_lines.shp")

# Crop roads information according to urban_areas polygon
adm2_roads <- st_crop(LMIC_roads, urban_areas)

# Information about highway classification: https://wiki.openstreetmap.org/wiki/Key:highway
# I had the following types of highways: primary, secondary, unclassified, tertiary, residential, track, service, and path  
roads_1 <- adm2_roads %>%
  filter(highway %in% c("primary", "secondary"))

roads_2 <- adm2_roads %>%
  filter(highway %in% c("unclassified", "tertiary"))

roads_3 <- adm2_roads %>%
  filter(highway %in% c("residential", "path"))

# Use ggplot to plot three levels of roads
ggplot() +
  theme_light() +
  geom_sf(data = pigg_adm2,
          size = 1,
          color = "black",
          fill = "pink",
          alpha = 0.3) +
  geom_sf(data = urban_areas,
          size = 1,
          color = "black",
          fill = "purple",
          alpha = 0.15) +
  geom_sf(data = roads_1,
          size = 0.6,
          color = "red") +
  geom_sf(data = roads_2,
          size = 0.4,
          color = "red") +
  geom_sf(data = roads_3,
          size = 0.2,
          color = "red") +
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Roadways through Pigg's Peak in Eswitini") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

ggsave("images/roads.png")

# Data source: https://data.humdata.org/dataset/hotosm_swz_health_facilities
LMIC_health <- read_sf("hotosm_swz_health_facilities_points_shp/hotosm_swz_health_facilities_points.shp")

# Crop healthcare to the region we are currently looking at 
adm2_health <- st_crop(LMIC_health, pigg_adm2)

# Filter healthcare for hospitals (that was the only returned data)
hospital <- adm2_health %>%
  filter(healthcare %in% c("hospital"))

# Use ggplot to plot healthcare facilities
ggplot() +
  theme_light() +
  geom_sf(data = pigg_adm2,
          size = 1,
          color = "black",
          fill = "pink",
          alpha = 0.3) +
  geom_sf(data = urban_areas,
          size = 1,
          color = "black",
          mapping = aes(fill = pop20),
          alpha = 0.45) +
  geom_sf(data = roads_1,
          size = 0.6,
          color = "red") +
  geom_sf(data = roads_2,
          size = 0.4,
          color = "red") +
  geom_sf(data = roads_3,
          size = 0.2,
          color = "red") +
  geom_sf(data = hospital,
          size = 1,
          color = "blue") +
  scale_fill_gradient2(low = "blue", mid = "pink", high = "red", midpoint = 2500)+
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Healthcare and roadways in Pigg's Peak in Eswitini") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

ggsave("images/health.png")

save(roads_1, file="Rdata/roads_1.RData")
save(roads_2, file="Rdata/roads_2.RData")
save(roads_3, file="Rdata/roads_3.RData")
save(hospital, file="Rdata/hospital.RData")

obj <- ggplot() +
  geom_sf(data = pigg_adm2,
          size = 1,
          linetype = "11",
          color = "white",
          alpha = 0) +
  geom_sf(data = urban_areas,
          size = 0.75,
          color = "purple",
          fill = "pink",
          alpha = 0.5) +
geom_sf(data = roads_1,
        size = 0.6,
        color = "red") +
  geom_sf(data = roads_2,
          size = 0.4,
          color = "red") +
  geom_sf(data = roads_3,
          size = 0.2,
          color = "red") +
  geom_sf(data = hospital,
          size = 1,
          color = "blue") +
  theme_void() + theme(legend.position="none") +
  scale_x_continuous(expand=c(0,0)) +
  scale_y_continuous(expand=c(0,0)) +
  labs(x=NULL, y=NULL, title=NULL) 

png("combined.png", width = 399, height = 275, units = "px", bg = "transparent")
obj
dev.off()






rm(list = ls(all = TRUE))

library(raster)
library(sf)
library(tidyverse)
library(maptools)
library(spatstat)
library(units)

setwd("~/Desktop/data-science/data")

# Get raster information for adm2
swz_pop20 <- raster("world_pop/swz_ppp_2020.tif")

# Get shapefile information for adm2
swz_adm2 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_2.shp")

# We only want the shape information for Pigg's Peak
pigg_adm2 <- swz_adm2 %>%
  filter(NAME_2 == "Pigg's Peak")

# We only want raster data for Pigg's Peak
swz_pop20_adm2 <- crop(swz_pop20, pigg_adm2)
swz_pop20_adm2 <- mask(swz_pop20_adm2, pigg_adm2)

# Get the population of Hhohho and round down for people
pop <- floor(cellStats(swz_pop20_adm2, "sum"))
pop

# Save as a PNG file
png("images/agg_pigg.png", width = 800, height = 800)
plot(swz_pop20_adm2, main = NULL)
plot(st_geometry(pigg_adm2), add = TRUE)
dev.off()

# Write `sf` object as a shapefile so spatstat can bool out
st_write(pigg_adm2, "pigg_adm2.shp", delete_dsn = TRUE)
pigg_adm2_with_mtools <- readShapeSpatial("pigg_adm2.shp")

win <- as(pigg_adm2_with_mtools, "owin")
plot(win, main = NULL)
win

# Use spatial probability distribution to find places to put people
# `as.im` converts raster to pixel image and then distributes random points according
set.seed(5)
pigg_adm2_ppp <- rpoint(pop, f = as.im(swz_pop20_adm2), win = win)

# Save both as a PNG
png("images/pigg_random_people.png", width = 2000, height = 2000)
plot(win, main = NULL)
plot(pigg_adm2_ppp, cex = 0.09, add = TRUE)
dev.off()

# Create spatial probability density function or kernel density estimation is a three dimension version
# bw <- bw.ppl(pigg_adm2_ppp)
# save(bw, file = "bw.RData")
load("Rdata/bw.RData")

pigg_density_image <- density.ppp(pigg_adm2_ppp, sigma = bw)

# Convert density image to spatial grid
Dsg <- as(pigg_density_image, "SpatialGridDataFrame")

# Convert back to image
Dim <- as.image.SpatialGridDataFrame(Dsg)

# Create polygon to contour our image and create initial settlements
Dcl <- contourLines(Dim, levels = 8e5) # Define arbitrarily at first

# Create Spatial Lines Data Frame
SLDF <- ContourLines2SLDF(Dcl, CRS("+proj=longlat +datum=WGS84 +no_defs"))

# Convert back to sf object which we know how to use
sf_multiline_obj <- st_as_sf(SLDF, sf)

# Plot density image and sf objects
png("images/pigg_lines_density_image.png", width = 2000, height = 2000)
plot(pigg_density_image, main = NULL)
plot(sf_multiline_obj, add = TRUE)
dev.off()

# Convert valid polygons on the inside (not touching adm1 boundaries) as polygons
png("images/pigg_inner_polygons.png", width = 2000, height = 2000)
inside_polys <- st_polygonize(sf_multiline_obj)
plot(st_geometry(inside_polys)) # Plot only internal polygons
dev.off()

# Now we want to handle the polygons that do not close
png("images/pigg_outer_polygons.png", width = 2000, height = 2000)
outside_lines <- st_difference(sf_multiline_obj, inside_polys) # get back the polygon lines that are not lines
plot(st_geometry(outside_lines)) # Plot only internal polygons and outer polygon lines
dev.off()

# Let's make our outer polygons by intersecting them with our adm1 and bounding them!
my_outer_polys <- st_buffer(outside_lines, 0.0014) %>%
  st_difference(pigg_adm2, .) %>%
  st_cast(., "POLYGON")

plot(st_geometry(my_outer_polys))

# Remove the polygon that is everything not in the contour line by filtering out the largest closed area
my_outer_polys$area <- as.numeric(st_area(my_outer_polys)) # Find areas of polygons
subpolys <- my_outer_polys %>%
  filter(area < 1e8) # CHANGE THIS NUMBER FOR MY DATA

# Get population of each newly created polygon and store in a new column into
subpolys_extract <- raster::extract(swz_pop20_adm2, subpolys, df = TRUE) # df = TRUE outputs as a data frame
subpolys_totals <- subpolys_extract %>%
  group_by(ID) %>%
  summarize(pop20 = sum(swz_ppp_2020, na.rm = TRUE)) 
subpolys <- subpolys %>%
  add_column(pop20 = subpolys_totals$pop20)

# Plot `subpolys` over the density function to check
png("images/subpolys.png", width = 1200, height = 1200)
plot(pigg_density_image, main = NULL)
plot(st_geometry(subpolys), border="white", add = TRUE)
dev.off()

# Remove places with tiny populations
subpolys_filtered <- subpolys %>%
  filter(pop20 > 10)

# New, population-filtered image
png("images/subpolys_filtered.png", width = 1200, height = 1200)
plot(pigg_density_image, main = NULL)
plot(st_geometry(subpolys_filtered), border="white", add = TRUE)
dev.off()

# Repeat with inner polygons to filter out small population polygons
inside_polys <- st_collection_extract(inside_polys, "POLYGON")

ips_extract <- raster::extract(swz_pop20, inside_polys, df = TRUE)

ips_totals <- ips_extract %>% 
  group_by(ID) %>%
  summarize(pop20 = sum(swz_ppp_2020, na.rm = TRUE))

inside_polys <- inside_polys %>%
  add_column(pop20 = ips_totals$pop20)

inside_polys_filtered <- inside_polys %>%
  filter(pop20 > 10)

# Combine inner and outer polygons
uas <- st_union(inside_polys_filtered, subpolys_filtered)

# Convert to type polygon
urban_areas <- st_cast(uas, "POLYGON")

# Remove columns that we don't need; we only care about geometry
urban_areas[ ,1:19] <- NULL

# Plot urban areas
png("images/urban_areas.png", width = 1200, height = 1200)
plot(pigg_density_image, main = NULL)
plot(st_geometry(urban_areas), border="white", add = TRUE)
dev.off()

# Extract populations for urban_area polygons
uas_extract <- raster::extract(swz_pop20, urban_areas, df = TRUE)

uas_totals <- uas_extract %>%
  group_by(ID) %>%
  summarize(pop20 = sum(swz_ppp_2020, na.rm = TRUE))

# Add data to our sf object for urban areas
urban_areas <- urban_areas %>%
  add_column(pop20 = uas_totals$pop20)

# Only include the unique urban areas
urban_areas <- urban_areas %>% 
  unique()

# Describe each new geometry's density
urban_areas <- urban_areas %>%
  mutate(area = st_area(urban_areas) %>%
           set_units(km^2)) %>%
  mutate(density = as.numeric(pop20 / area))

# Plot urban areas
ggplot() +
  theme_light() +
  geom_sf(data = pigg_adm2,
          size = 0.75,
          color = "gray50",
          fill = "pink",
          alpha = 0.3) +
  geom_sf(data = urban_areas,
          mapping = aes(fill = pop20),
          size = 0.45,
          alpha = 0.5) +
  geom_sf_text(
      data = urban_areas,
      mapping = aes(label = floor(density)),
      nudge_y = -0.001
  ) +
  scale_fill_gradient2(low = "blue", mid = "pink", high = "red", midpoint = 2500)+
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Pigg's Peak with De Facto Settlements") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

ggsave("images/urban_areas_plot.png")







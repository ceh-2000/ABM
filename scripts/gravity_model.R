rm(list = ls(all = TRUE))

library(tidyverse)
library(sf)
library(geosphere)
library(gganimate)
library(rmapshaper)
library(gravity)
library(raster)
library(doParallel)
library(RColorBrewer)
library(maptools)
library(haven)
library(spatstat)

# Set working directory
setwd("~/Desktop/data-science/data")

# Geometry of adm1 and simplify the bounds for easier computation
swz_adm1 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_1.shp") %>% ms_simplify()

# Read in scv file using tidyverse for more flexibility and control
flow_data <- read_csv("flow_data/SWZ_5yrs_InternalMigFlows_2010.csv") 
centroid_data <- read_sf("flow_data/centroid/SWZ_AdminUnit_Centroids.shp")

# Use to match up the numbers ot the names of the adm1's
plot(st_geometry(swz_adm1))
plot(st_geometry(centroid_data), add = TRUE)

# Key: Hhohho = 1, Lubombo = 2, Manzini = 3, Shiselweni = 4

flow_matrix <- flow_data %>% 
            dplyr::select(NODEI, NODEJ, PrdMIG) %>% 
            pivot_wider(names_from = NODEJ, values_from = PrdMIG) %>%
            dplyr::select(`1`, everything(), -NODEI)
save(flow_matrix, file="Rdata/flow_matrix.Rdata")

# Add the distances to the flow data data frame with ... A FOR LOOP
x <- c(1:nrow(flow_data))
distances <- c()
for(val in x) {
  distances <- append(distances, distm(c(flow_data[val, ]$LONFR, flow_data[val, ]$LATFR), c(flow_data[val, ]$LONTO, flow_data[val, ]$LATTO), fun = distHaversine))
}

flow_data <- flow_data %>% add_column(distances)

###############################################################
## Create distance matrix

# Create a distance matrix to go with our flow matrix
distance_matrix <- flow_data %>% 
  dplyr::select(NODEI, NODEJ, distances) %>% 
  pivot_wider(names_from = NODEJ, values_from = distances) %>%
  dplyr::select(`1`, everything(), -NODEI)
save(distance_matrix, file="Rdata/distance_matrix.Rdata")

# Origins and destination flows
origin_flows <- st_as_sf(flow_data, coords = 4:5, crs = st_crs(swz_adm1))
destination_flows <- st_as_sf(flow_data, coords = 6:7, crs = st_crs(swz_adm1))

# Summarize by origin NODEI
origin_sum <- origin_flows %>% 
  group_by(NODEI) %>%
  summarise(migration_out = sum(PrdMIG))

# Summarize by origin NODEJ
destination_sum <- destination_flows %>% 
  group_by(NODEJ) %>%
  summarise(migration_in = sum(PrdMIG))

# Plot the origins with associated scaled number of people at that starting point
ggplot() +
  geom_sf(data = swz_adm1) +
  geom_sf(data = origin_sum, mapping = aes(size = migration_out, color = migration_out))

# Plot the destinations with associated scaled number of people at that ending point
ggplot() +
  geom_sf(data = swz_adm1) +
  geom_sf(data = destination_sum, mapping = aes(size = migration_in, color = migration_in))

adm1_centroids <- st_centroid(swz_adm1) %>% st_geometry()

# 4 adm1's and each maps to 4 adm1s (including itself)
od_combos <- expand.grid(adm1_centroids, adm1_centroids)

# Pull out all destinations from one origin point and make this a new connected geometry object
pt_1 <- st_union(od_combos$Var2[1], od_combos$Var1[2:4])

# Make these into lines connected from single origin to all destination points
ln <- st_cast(pt_1, "LINESTRING") %>% 
  st_as_sf()

# Plots each individually
plot(st_geometry(swz_adm1))
plot(st_geometry(adm1_centroids), add=TRUE)
plot(st_geometry(ln), add=TRUE)


# Include migration data
ln <- ln %>%
  add_column(subset(origin_flows, NODEI == 1) %>%
               st_set_geometry(NULL) %>%
               dplyr::select(PrdMIG))


# Plot flows out of Hhohho
ggplot() +
  theme_light() +
  geom_sf(data = swz_adm1, fill = "white") +
  geom_sf(data = ln) +
  geom_sf(data = ln, mapping = aes(size = PrdMIG, color = PrdMIG), show.legend = FALSE) +
  geom_sf(data = origin_sum, size = 7) +
  xlab("longitude") +
    ylab("latitude") +
    ggtitle("Eswatini", subtitle = "Hhohho as origin with weighted destination paths.") +
    theme(
      plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
      panel.background = element_rect(fill = "azure"),
      panel.border = element_rect(fill = NA),
      panel.grid = element_blank()
    )
ggsave("images/hhohho_origin.png")

p <- st_line_sample(st_transform(ln[1, ], 32736), 20) %>%
  st_cast("POINT") %>%
  st_as_sf() %>%
  st_transform(4979)

# Need to transform these points back so they match back up with the correct coordinate system
plot(st_geometry(swz_adm1))
plot(st_geometry(p), add = TRUE)
plot(st_geometry(adm1_centroids), add = TRUE)

p$time <- seq(from = 0, to = 2, by = 0.5)

# Take out of sf objects so that we can handle animations
p$long <- st_coordinates(p)[,1]
p$lat <- st_coordinates(p)[,2]

# Plot our lines extending from Hhohho ot all destinations and our points that will allow us to animate
# (Points are equally spaced from Hhohho to Lumbombo)
a <- ggplot() +
  theme_light() +
  geom_sf(data = swz_adm1, fill = "white") +
  xlab("longitude") +
  ylab("latitude") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  ) +
  geom_point(data = p, aes(x = long, y = lat), color = "blue") 
  

anim = a +
  transition_reveal(along = time) +
  ease_aes('linear') +
  ggtitle("Time: {frame_along}") 


animate(anim, nframes = 100, fps = 20)

anim_save("images/moving_person.gif")

##########################################
## Now do for many

# Now create all possible vectors for all combinations of origins and destinations
# THE ORDER MATTERS HERE SO WE HAVE TO BE SUPER CAREFUL
start = c(flow_data$LONFR[1], flow_data$LATFR[1])
end = c(flow_data$LONTO[1], flow_data$LATTO[1])
pt_matrix <- rbind(start, end)
new_line1 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[2], flow_data$LATFR[2])
end = c(flow_data$LONTO[2], flow_data$LATTO[2])
pt_matrix <- rbind(start, end)
new_line2 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[3], flow_data$LATFR[3])
end = c(flow_data$LONTO[3], flow_data$LATTO[3])
pt_matrix <- rbind(start, end)
new_line3 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[4], flow_data$LATFR[4])
end = c(flow_data$LONTO[4], flow_data$LATTO[4])
pt_matrix <- rbind(start, end)
new_line4 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[5], flow_data$LATFR[5])
end = c(flow_data$LONTO[5], flow_data$LATTO[5])
pt_matrix <- rbind(start, end)
new_line5 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[6], flow_data$LATFR[6])
end = c(flow_data$LONTO[6], flow_data$LATTO[6])
pt_matrix <- rbind(start, end)
new_line6 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[7], flow_data$LATFR[7])
end = c(flow_data$LONTO[7], flow_data$LATTO[7])
pt_matrix <- rbind(start, end)
new_line7 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[8], flow_data$LATFR[8])
end = c(flow_data$LONTO[8], flow_data$LATTO[8])
pt_matrix <- rbind(start, end)
new_line8 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[9], flow_data$LATFR[9])
end = c(flow_data$LONTO[9], flow_data$LATTO[9])
pt_matrix <- rbind(start, end)
new_line9 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[10], flow_data$LATFR[10])
end = c(flow_data$LONTO[10], flow_data$LATTO[10])
pt_matrix <- rbind(start, end)
new_line10 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[11], flow_data$LATFR[11])
end = c(flow_data$LONTO[11], flow_data$LATTO[11])
pt_matrix <- rbind(start, end)
new_line11 <- st_linestring(pt_matrix)

start = c(flow_data$LONFR[12], flow_data$LATFR[12])
end = c(flow_data$LONTO[12], flow_data$LATTO[12])
pt_matrix <- rbind(start, end)
new_line12 <- st_linestring(pt_matrix)

# We have to create all objects first; no creating a for-loop
lns_all <- st_sfc(new_line1, new_line2, new_line3, new_line4,
                   new_line5, new_line6, new_line7, new_line8,
                   new_line9, new_line10, new_line11, new_line12,
                   crs = st_crs(swz_adm1)) %>% st_as_sf()


# pt_all <- st_union(centroid_data, centroid_data)

# pt_all <- rbind(c(flow_data$LONFR[1], flow_data$LATFR[1], flow_data$LONTO[1], flow_data$LATTO[1])) %>% st_multipoint() #(flow_data, coords = 4:7, crs = st_crs(swz_adm1))

# Now filter out geometries that are a single point because these are conntecting to the same origin
# mpts_all <- pt_all[st_geometry_type(pt_all) != "POINT",]

# Cast all options to line strings
# lns_all <- st_cast(mpts_all, "LINESTRING") %>% 
#   st_as_sf()

# To correlate the size of each moving dot to the number of people moving, create and append a new vector corresponding to the flows

# TODO: Go check that everything matches up correctly
PrdMIG <- c()
for(i in 1:nrow(origin_flows)){
  PrdMIG <- c(PrdMIG, rep(origin_flows$PrdMIG[i], each = 20))
}
PrdMIG

ggplot() +
  geom_sf(data = swz_adm1) +
  geom_sf(data = origin_sum) +
  geom_sf(data = lns_all) +
  geom_point()

# Sample points for all lines (tranform to meters then back to lon/lat)
p_all <- st_line_sample(st_transform(lns_all, 32736), 20) %>%
  st_cast("POINT") %>%
  st_as_sf() %>%
  st_transform(4979)

ggplot() +
  geom_sf(data = swz_adm1) +
  geom_sf(data = p_all) 

# Each point along each line needs to have 20 time points to move along
p_all$id <- rep(1:12, each = 20)
p_all$time <- seq(from = 0, to = 19, by = 1) %>% 
  rep(12)
p_all$size <- PrdMIG / 1000 # We want to sccale to a reasonable size for our model

# Get long and lat for the geometries associated with p_all
p_all$long <- st_coordinates(p_all)[,1]
p_all$lat <- st_coordinates(p_all)[,2]

# Animate with all of our new points
a_all <- ggplot() +
  theme_light() +
  geom_sf(data = swz_adm1, fill = "white") +
  xlab("longitude") +
  ylab("latitude") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  ) +
  geom_sf(data = adm1_centroids) +
  geom_sf(data = lns_all, alpha = 0.1) +
  geom_point(data = p_all, aes(x = long, y = lat, color=as.factor(id), size = size), show.legend = FALSE)

a_all

anim_all <- a_all +
  transition_reveal(along = time)+
  ease_aes()

gganimate::animate(anim_all, nframes = 100, fps = 20)

anim_save("images/all_people_moving_with_sizes.gif", animation = anim_all)

################################################################
## Create the gravity model and get our predicted flows

# There is a gravity package in order to make gravity model creation easier
# https://pacha.dev/gravity/index.html

# Our initial data metrics will be distance and weights of how many people

# Then we will add in nighttime lights, and attempt to transfer our model to the adm2/vornoi polygons

# Let's add an additional data source (eventually nighttime lights; for now just 
# use 1 as a placeholder)
flow_data$var <- 1

# Pull out each necessary variable input for the gravity model
fit <- ppml(
  dependent_variable = "PrdMIG",
  distance = "distances",
  additional_regressors = c("var"),
  robust = TRUE,
  data = flow_data
)

summary(fit)

flow_data$ModelFLOWS <- fitted(fit)

fits <- c()
for(i in 1:nrow(origin_flows)){
  fits <- c(fits, rep(fitted(fit)[i], each = 20))
}
p_all$fit <- fits / 1000

# Now let's compare the actual flow data with our modeled flow data
a_all <- ggplot() +
  theme_light() +
  geom_sf(data = swz_adm1, fill = "white") +
  xlab("longitude") +
  ylab("latitude") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  ) +
  geom_sf(data = adm1_centroids) +
  geom_sf(data = lns_all, alpha = 0.1) +
  geom_point(data = p_all, aes(x = long, y = lat, color=as.factor(id), size = fit), show.legend = FALSE)

a_all

anim_all <- a_all +
  transition_reveal(along = time)+
  ease_aes()

gganimate::animate(anim_all, nframes = 100, fps = 20)

anim_save("images/all_people_moving_with_sizes_model.gif", animation = anim_all)

# This plot is different because flows are now all symmetric
# Look at the flow matrix model to see this
flow_matrix_model <- flow_data %>% 
  dplyr::select(NODEI, NODEJ, ModelFLOWS) %>% 
  pivot_wider(names_from = NODEJ, values_from = ModelFLOWS) %>%
  dplyr::select(`1`, everything(), -NODEI)
save(flow_matrix_model, file="Rdata/flow_matrix_model.Rdata")

####################################################################
## Let's include an additional variable to improve this model; let's begin with nighttime lights

# Use data from 2015 because our migration data was collected over 5 years from 2010 to 2015
night_lights <- raster("world_pop/swz_viirs_100m_2015.tif")

plot(st_geometry(swz_adm1))
plot(night_lights, add = TRUE)

# We want the shape information for each adm1 so we can crop and mask and then determine the 
# Nighttime lights in each region
hhohho <- swz_adm1 %>%
  filter(NAME_1 == "Hhohho")
lubombo <- swz_adm1 %>%
  filter(NAME_1 == "Lubombo")
manzini <- swz_adm1 %>%
  filter(NAME_1 == "Manzini")
shiselweni <- swz_adm1 %>%
  filter(NAME_1 == "Shiselweni")

hhohho_lights <- crop(night_lights, hhohho) %>%
    mask(hhohho) %>%
    cellStats("sum") %>%
    floor()

lubombo_lights <- crop(night_lights, lubombo) %>%
  mask(lubombo) %>%
  cellStats("sum") %>%
  floor()

manzini_lights <- crop(night_lights, manzini) %>%
  mask(manzini) %>%
  cellStats("sum") %>%
  floor()

shiselweni_lights <- crop(night_lights, shiselweni) %>%
  mask(shiselweni) %>%
  cellStats("sum") %>%
  floor()

all_lights <- c(hhohho_lights, lubombo_lights, manzini_lights, shiselweni_lights)
all_lights_expanded <- expand.grid(all_lights, all_lights) %>%
                       filter(Var1 != Var2)


flow_data <- add_column(flow_data, night_lights_ori = all_lights_expanded$Var2) %>%
             add_column(night_lights_des = all_lights_expanded$Var1)

# Let's also add population data (because we can)
# Last time cropping and masking to each adm1 took a while, so let's try something faster

# Get raster information for population
swz_pop20_raster <- raster("world_pop/swz_ppp_2020.tif")

# Use cluster to extract information faster
beginCluster(n = detectCores() - 1)
swz_pop20 <- raster::extract(swz_pop20_raster, swz_adm1, df = TRUE)
endCluster()

# Add up the population at each cell that corresponds to a given 
agg_pop20 <- swz_pop20 %>% 
             group_by(ID) %>%
             summarize(pop20 = sum(swz_ppp_2020, na.rm = TRUE)) 

agg_pop20_expanded <- expand.grid(agg_pop20$pop20, agg_pop20$pop20) %>% 
                      filter(Var1 != Var2)

flow_data <- add_column(flow_data, pop_ori = agg_pop20_expanded$Var2) %>%
            add_column(pop_des = agg_pop20_expanded$Var1)

fit_with_additional_vars <- ppml(
  dependent_variable = "PrdMIG",
  distance = "distances",
  additional_regressors = c("night_lights_ori", "night_lights_des", "pop_ori", "pop_des"),
  robust = TRUE,
  data = flow_data
)

summary(fit_with_additional_vars)
fitted(fit_with_additional_vars)

# We see from the output of fitted that we have more variation between coming and going
# We can plot this like before and compare
# Likely attributed somewhat to noise --> destinations were both statistically significant 
# (look at the stars) but very tiny nonetheless

#########################################################
## Go back down to adm 2 and repeat with Pigg's Peak
# We can apply the model that we trained on the national level to our adm2s

swz_adm2 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_2.shp") %>% filter(NAME_2=="Pigg's Peak")

load("Rdata/urban_areas.RData")
load("Rdata/swz_pns.Rdata")

plot(st_geometry(swz_adm2))
plot(st_geometry(urban_areas), add=TRUE)

swz_pns <- st_as_sf(swz_pns, coords = c("x", "y"), crs = st_crs(swz_adm2))
#plot(st_geometry(swz_pns))

all_individuals <- st_join(swz_pns, swz_adm2, join=st_within)

pigg_individuals <- all_individuals %>% filter(NAME_2 == "Pigg's Peak")

ggplot() +
  geom_sf(data = swz_adm2) +
  geom_sf(data = urban_areas, fill="cyan") +
  geom_sf(data = pigg_individuals, size=0.2)

# Make centroids of urban areas, and split into multiple geometries (CHECK THIS)
urban_centroids <- st_centroid(urban_areas) %>% st_cast("MULTIPOINT")

# Create bounding box and turning into a poly
pigg_bb <- st_bbox(swz_pns) %>% st_as_sfc() 

# st_voronoi needs the union of the centroids as an input
pigg_voronoi <- st_voronoi(st_union(urban_centroids), pigg_bb) %>% #producing voronoi polys
                st_collection_extract("POLYGON")
pigg_voronoi <- pigg_voronoi %>%
                st_intersection(swz_adm2)


# Plot the urban areas, centroids, bounds of my adm2, and vornoi polygons
vornoi_plot <- ggplot() +
  theme_light() +
  geom_sf(data = swz_adm2, fill = "white") +
  xlab("longitude") +
  ylab("latitude") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  ) +
  geom_sf(data = urban_areas, fill="cyan") +
  geom_sf(data = urban_centroids) + 
  geom_sf(data = pigg_voronoi, fill=NA)
# ggsave("images/vornoi.png")

#####################################################################
## Now we want to fit a model to this layer

# Start by finding distances between centroids
all_urban_combos <- expand.grid(urban_centroids$geometry, urban_centroids$geometry)

pigg_flow_data <- tibble(origin = all_urban_combos$Var2, destination = all_urban_combos$Var1)

distance <- st_distance(pigg_flow_data$origin, pigg_flow_data$destination, by_element = TRUE)

pigg_flow_data <- add_column(pigg_flow_data, distance = as.numeric(distance)) 

# Now get population and nighttime lights like before
beginCluster(n = detectCores() - 1)
pigg_pop20 <- raster::extract(swz_pop20_raster, st_as_sf(pigg_voronoi), df = TRUE)
pigg_night_lights <- raster::extract(night_lights, st_as_sf(pigg_voronoi), df = TRUE)
endCluster()

agg_pigg_pop20 <- pigg_pop20 %>%
                  group_by(ID) %>%
                  summarize(pop20_pigg = sum(swz_ppp_2020, na.rm = TRUE))

agg_pigg_night_lights <- pigg_pop20 %>%
  group_by(ID) %>%
  summarize(pop20_pigg = sum(swz_ppp_2020, na.rm = TRUE))


agg_pigg_pop20_expanded <- expand.grid(agg_pigg_pop20$pop20_pigg, agg_pigg_pop20$pop20_pigg) %>%
  filter(Var1 != Var2)

agg_pigg_night_lights_expanded <- expand.grid(agg_pigg_night_lights$pop20_pigg, agg_pigg_night_lights$pop20_pigg) %>%
  filter(Var1 != Var2)

pigg_flow_data <- pigg_flow_data %>%
                  filter(origin != destination) %>%
                  add_column(pop_ori = agg_pigg_pop20_expanded$Var2) %>%
                  add_column(pop_des = agg_pigg_pop20_expanded$Var1) %>%
                  add_column(night_lights_ori = agg_pigg_night_lights_expanded$Var2) %>%
                  add_column(night_lights_des = agg_pigg_night_lights_expanded$Var1)

# We also need the log of the distance in order to make predictions using our national level model
pigg_flow_data <- add_column(pigg_flow_data, dist_log = log(pigg_flow_data$distance))

# Now we have all of the necessary columns. Let's make a prediction.
pigg_fit <- predict(fit_with_additional_vars, pigg_flow_data) %>%
            exp()
pigg_flow_data$model_flows <- pigg_fit

indices <- expand.grid(c(1,2,3,4,5,6), c(1,2,3,4,5,6)) %>% 
          filter(Var1 != Var2)
pigg_flow_data$NODE_FROM <- indices$Var2
pigg_flow_data$NODE_TO <- indices$Var1

pigg_flow_matrix <- pigg_flow_data %>% 
  dplyr::select(NODE_FROM, NODE_TO, model_flows) %>% 
  pivot_wider(names_from = NODE_TO, values_from = model_flows) %>%
  dplyr::select(`1`, everything(), -NODE_FROM)
save(flow_matrix, file="Rdata/pigg_flow_matrix.Rdata")





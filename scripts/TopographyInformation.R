rm(list = ls(all = TRUE))

library(raster)
library(sf)
library(tidyverse)
library(maptools)
library(spatstat)
library(units)
library(rayshader)
library(rayrender)

setwd("~/Desktop/data-science/data")

load("Rdata/urban_areas.RData")
load("Rdata/pigg_adm2.RData")
load("Rdata/roads_1.RData")
load("Rdata/roads_2.RData")
load("Rdata/roads_3.RData")
load("Rdata/hospital.RData")

# Crop topography raster data to Pigg's Peak's bounds
swz_topo <- raster("swz_srtm_topo_100m.tif")
pigg_topo <- crop(swz_topo, pigg_adm2)

# Convert raster into a matrix
pigg_matrix <- raster_to_matrix(pigg_topo)
# Output: [1] "Dimensions of matrix are: 399x275."


overlay_img <- png::readPNG("combined.png")


# 2D plot of Pigg's Peak features
pigg_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(pigg_matrix)) %>%
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  plot_map()


# Make the shadows so we can get a 3D topographic plot
ambientshadows <- ambient_shade(pigg_matrix)

# 3D plot of Pigg's Peak features
pigg_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(pigg_matrix), color = "lightblue") %>%
  add_shadow(ray_shade(pigg_matrix, sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken = 0.5) %>%
  add_shadow(lamb_shade(pigg_matrix, sunaltitude = 3, zscale = 33), max_darken = 0.7) %>%
  add_shadow(ambientshadows, max_darken = 0.1) %>%  
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  plot_3d(pigg_matrix, zscale = 20,windowsize = c(1000,1000), 
          phi = 60, theta = 135, zoom = 1, 
          background = "grey30", shadowcolor = "grey5", 
          soliddepth = -50, shadowdepth = -100)

render_snapshot(title_text = "Pigg's Peak, Hhohho, Eswitini", 
                title_size = 50,
                title_color = "grey90")


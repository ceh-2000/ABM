rm(list = ls(all = TRUE))

library(tidyverse)
library(sf)
library(raster)
library(doParallel)
library(snow)

setwd("~/Desktop/data-science/data")

swaziland_raster_pop20 <- raster("world_pop/swz_ppp_2020_1km_Aggregated.tif")

############################################################################
# adm1 subdivisions

swaziland_sf_adm1 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_1.shp")

plot(swaziland_raster_pop20)
plot(st_geometry(swaziland_sf_adm1), add = TRUE)

# ncores <- detectCores() - 1
# beginCluster(ncores)
# pop_vals_adm1 <- raster::extract(swaziland_raster_pop20, swaziland_sf_adm1, df = TRUE)
# endCluster()
# save(pop_vals_adm1, file = "pop_vals_adm1.RData")

load("pop_vals_adm1.RData")

totals_adm1 <- pop_vals_adm1 %>%
  group_by(ID) %>%
  summarize(swz_ppp_2020 = sum(swz_ppp_2020_1km_Aggregated, na.rm = TRUE))

# Outputs 1,088,881 and actual population is 1,136,000 (pretty good; correct magnitude)
sum(totals_adm1$swz_ppp_2020) 

swaziland_sf_adm1 <- swaziland_sf_adm1 %>%
  add_column(pop20 = totals_adm1$swz_ppp_2020)

ggplot(swaziland_sf_adm1) +
  theme_light() +
  geom_sf(aes(fill = pop20))+
  geom_sf_text(aes(label = NAME_1),
               color="blue",
               size=5)+
  scale_fill_gradient(low="yellow", high="red")+
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Swaziland Populations by First Administrative Boundaries", subtitle = "This shows populations.") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

ggsave("swz_pop20_adm1.png")

############################################################################
# Individual Stretch Goal 1: adm2 subdivisions

swaziland_sf_adm2 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_2.shp")

plot(swaziland_raster_pop20)
plot(st_geometry(swaziland_sf_adm2), add = TRUE)

# ncores <- detectCores() - 1
# beginCluster(ncores)
# pop_vals_adm2 <- raster::extract(swaziland_raster_pop20, swaziland_sf_adm2, df = TRUE)
# endCluster()
# save(pop_vals_adm2, file = "pop_vals_adm2.RData")

load("pop_vals_adm2.RData")

totals_adm1 <- pop_vals_adm2 %>%
  group_by(ID) %>%
  summarize(swz_ppp_2020 = sum(swz_ppp_2020_1km_Aggregated, na.rm = TRUE))

# Outputs 1,088,881 and actual population is 1,136,000 (pretty good; correct magnitude)
sum(totals_adm2$swz_ppp_2020) 

swaziland_sf_adm2 <- swaziland_sf_adm2 %>%
  add_column(pop20 = totals_adm1$swz_ppp_2020)

ggplot(swaziland_sf_adm2) +
  theme_light() +
  geom_sf(aes(fill = pop20))+
  geom_sf_text(aes(label = NAME_2),
               color="blue",
               size=1.5)+
  scale_fill_gradient(low="yellow", high="red")+
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Swaziland Populations by Second Administrative Boundaries", subtitle = "This shows populations.") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

ggsave("swz_pop20_adm2.png")

############################################################################
# Individual Stretch Goal 2

swaziland_sf_adm2 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_2.shp")

plot(swaziland_raster_pop20)
plot(st_geometry(swaziland_sf_adm2), add = TRUE)

# ncores <- detectCores() - 1
# beginCluster(ncores)
# pop_vals_adm2 <- raster::extract(swaziland_raster_pop20, swaziland_sf_adm2, df = TRUE)
# endCluster()
# save(pop_vals_adm2, file = "pop_vals_adm2.RData")

load("pop_vals_adm2.RData")

totals_adm1 <- pop_vals_adm2 %>%
  group_by(ID) %>%
  summarize(swz_ppp_2020 = sum(swz_ppp_2020_1km_Aggregated, na.rm = TRUE))

# Outputs 1,088,881 and actual population is 1,136,000 (pretty good; correct magnitude)
sum(totals_adm2$swz_ppp_2020) 

swaziland_sf_adm2 <- swaziland_sf_adm2 %>%
  add_column(pop20 = totals_adm1$swz_ppp_2020)

ggplot(swaziland_sf_adm2) +
  theme_light() +
  geom_sf(aes(fill = pop20),
          size = 0.2,
          color = "purple",
          )+
  geom_sf_text(
    data = swaziland_sf_adm1,
    aes(label = NAME_1),
    size = 8,
    color = "black",
    alpha = 0.35
  ) +
  geom_sf(
    data = swaziland_sf_adm1,
    size = 2,
    color = "purple",
    alpha = 0
  ) +
  geom_sf_text(aes(label = NAME_2),
               color="blue",
               size=1.5)+
  scale_fill_gradient2(low="blue", mid="yellow", high="orange", midpoint=30000)+
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Swaziland Populations by Second Administrative Boundaries", subtitle = "This shows populations.") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

ggsave("images/swz_pop20_recolored.png")

save(swaziland_sf_adm2, file="swz_adm2.Rdata")
save(pop_vals_adm2, file="pop_vals_adm2.Rdata")


# How to filter:
# less_than_one <- pop_vals_adm1 %>%
#   filter(swz_ppp_2020_1km_Aggregated < 1)

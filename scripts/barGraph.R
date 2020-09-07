rm(list = ls(all = TRUE))

library(tidyverse)
library(sf)
library(raster)
library(doParallel)
library(snow)
library(units)
library(scales)
library(ggpubr)
library(ggrepel)
library(RColorBrewer)

setwd("~/Desktop/data-science/data")

load("swaziland_sf_adm1.RData")

swaziland_sf_adm1 <- swaziland_sf_adm1 %>%
  mutate(area = st_area(swaziland_sf_adm1) %>%
    units::set_units("km^2")) %>%
  mutate(density = pop20 / area)

myBarGraph <- swaziland_sf_adm1 %>%
  mutate(NAME_1 = fct_reorder(NAME_1, pop20)) %>%
  ggplot(aes(x = pop20, y = NAME_1, fill = pop20)) +
  geom_bar(stat = "identity", color = "blue", width = 0.5) +
  xlab("Population") +
  ylab("Region") +
  geom_text(aes(label = percent(pop20 / sum(pop20))),
    position = position_stack(vjust = 0.5),
    color = "black", size = 2.0
  ) +
  scale_fill_gradient(low = "yellow", high = "red") +
  ggtitle("Swaziland Densities of First Administrative Boundaries", subtitle = "This shows densities.")

plot(swaziland_raster_pop20)
plot(st_geometry(swaziland_sf_adm1), add = TRUE)

load("pop_vals_adm1.RData")

totals_adm1 <- pop_vals_adm1 %>%
  group_by(ID) %>%
  summarize(swz_ppp_2020 = sum(swz_ppp_2020_1km_Aggregated, na.rm = TRUE))

# Outputs 1,088,881 and actual population is 1,136,000 (pretty good; correct magnitude)
sum(totals_adm1$swz_ppp_2020)

swaziland_sf_adm1 <- swaziland_sf_adm1 %>%
  add_column(pop20 = totals_adm1$swz_ppp_2020)

myMap <- ggplot(swaziland_sf_adm1) +
  theme_light() +
  geom_sf(aes(fill = pop20)) +
  geom_sf_text(aes(label = NAME_1),
    color = "blue",
    size = 5
  ) +
  geom_sf_text(aes(label = round(density, 2)),
    size = 5, nudge_y = -0.07
  ) +
  scale_fill_gradient(low = "yellow", high = "red") +
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Swaziland Populations by First Administrative Boundaries", subtitle = "This is colored by population and lists population density.") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

swaziland <- ggarrange(myMap, myBarGraph, nrow = 1, widths = c(2.25, 2))

annotate_figure(swaziland, top = text_grob("Swaziland in 2020", color = "black", face = "bold", size = 26))

ggsave("swazilandWithDensity.png", width = 20, height = 10, dpi = 200)

load("swz_adm2.Rdata")

nb.cols <- 55
mycolors <- colorRampPalette(brewer.pal(20, "RdPu"))(nb.cols)

swaziland_sf_adm2 %>%
  ggplot(aes(x = NAME_1, y = pop20, weight = pop20, fill = NAME_2)) +
  scale_fill_manual(values = mycolors) +
  geom_bar(stat = "identity", color = "white", width = 0.75) +
  coord_flip() +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  ) +
  geom_text_repel(aes(label = NAME_2),
    position = position_stack(vjust = 0.5),
    force = 0.0005,
    direction = "y",
    size = 1.35,
    segment.size = 0.2,
    segment.alpha = 0.4
  )

ggsave("images/swz_adm2_barplot.png", width = 20, height = 15, dpi = 300)

################################################################################

swaziland_sf_adm2 <- swaziland_sf_adm2 %>%
  mutate(area = st_area(swaziland_sf_adm2) %>%
           units::set_units("km^2")) %>%
  mutate(density = pop20 / area) %>%
  filter(NAME_1=="Hhohho")

myBarGraph2 <- swaziland_sf_adm2 %>%
  mutate(NAME_2 = fct_reorder(NAME_2, pop20)) %>%
  ggplot(aes(x = pop20, y = NAME_2, fill = pop20)) +
  geom_bar(stat = "identity", color = "white", width = 0.5) +
  xlab("Population") +
  ylab("Tinkhundla") +
  geom_text(aes(label = percent(pop20 / sum(pop20))),
            position = position_stack(vjust = 0.5),
            color = "white", size = 2.0
  ) +
  scale_fill_gradient2(low = "blue", mid="purple", high = "red", midpoint=30000) +
  ggtitle("Hhohho Densities of Second Administrative Boundaries", subtitle = "This shows densities.")

plot(swaziland_raster_pop20)
plot(st_geometry(swaziland_sf_adm2), add = TRUE)

myBarGraph2

load("pop_vals_adm2.RData")

totals_adm2 <- pop_vals_adm2 %>%
  group_by(ID) %>%
  summarize(swz_ppp_2020 = sum(swz_ppp_2020_1km_Aggregated, na.rm = TRUE))

sum(totals_adm2$swz_ppp_2020)

# swaziland_sf_adm2 <- swaziland_sf_adm2 %>%
#   add_column(pop20 = totals_adm2$swz_ppp_2020)

myMap2 <- ggplot(swaziland_sf_adm2) +
  theme_light() +
  geom_sf(aes(fill = pop20)) +
  geom_sf_text(aes(label = NAME_2),
               color = "white",
               size = 2.5
  ) +
  geom_sf_text(aes(label = round(density, 2)),
               color = "white", size = 2, nudge_y = -0.03
  ) +
  scale_fill_gradient2(low = "blue", mid="purple", high = "red", midpoint=30000) +
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Hhohho Populations by Second Administrative Boundaries", subtitle = "This is colored by population and lists population density.") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

swaziland <- ggarrange(myMap2, myBarGraph2, nrow = 1, widths = c(2.25, 2))

annotate_figure(swaziland, top = text_grob("Hhohho in 2020", color = "black", face = "bold", size = 26))

ggsave("images/hhohhoWithDensity.png", width = 20, height = 10, dpi = 200)







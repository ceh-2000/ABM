rm(list = ls(all = TRUE))

library(tidyverse)
library(sf)

setwd("~/Desktop/data-science/data")

swz_int_0 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_0.shp")
swz_int_1 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_1.shp")
swz_int_2 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_2.shp")

### Create Larger Map of Swaziland with Rectangles identifying area of Detailed Maps

plot1 <- ggplot() +
  theme_light() +
  geom_sf(
    data = swz_int_2,
    size = 0.5,
    color = "#ff7539",
    fill = "#654F97",
    alpha = 1
  ) +
  geom_sf(
    data = swz_int_1,
    size = 1,
    color = "#EF486D",
    fill = "#000000",
    alpha = 0.0
  ) +
  geom_sf(
    data = swz_int_0,
    size = 2,
    color = "#4A3175",
    fill = "#654F97",
    alpha = 0.0
  ) +
  geom_rect(
    data = swz_int_1,
    xmin = 30.9, xmax = 31.8, ymin = -25.7, ymax = -26.5,
    fill = NA, color = "green", size = 2
  ) +
  geom_rect(
    data = swz_int_1,
    xmin = 30.85, xmax = 32, ymin = -26.7, ymax = -27.35,
    fill = NA, color = "blue", size = 2
  ) +
  geom_sf_text(
    data = swz_int_2,
    aes(label = NAME_2),
    size = 1,
    color = "#EFE7D9",
    fontface = "bold",
    check_overlap = TRUE
  ) +
  geom_sf_text(
    data = swz_int_1,
    aes(label = NAME_1),
    size = 5,
    color = "#EFE7D9",
    fontface = "bold",
    check_overlap = TRUE
  ) +
  geom_sf_text(
    data = swz_int_0,
    aes(label = NAME_0),
    size = 10,
    color = "#EFE7D9",
    nudge_y = -0.25,
    fontface = "bold",
    check_overlap = TRUE
  ) +
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Swaziland", subtitle = "This is a country") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )


new_sf_obj <- swz_int_1 %>%
  filter(NAME_1 == "Hhohho")

plot2 <- swz_int_2 %>%
  filter(NAME_1 == "Hhohho") %>%
  ggplot() +
  theme_light() +
  geom_sf(
    size = 0.5,
    color = "#ff7539",
    fill = "#654F97",
    alpha = 1
  ) +
  geom_sf_text(
    aes(label = NAME_2),
    size = 2,
    color = "#EFE7D9",
  ) +
  geom_sf(
    data = new_sf_obj,
    size = 1,
    color = "#EF486D",
    fill = "#000000",
    alpha = 0.0
  ) +
  geom_sf_text(
    data = new_sf_obj,
    aes(label = NAME_1),
    size = 3,
    color = "#EFE7D9",
    fontface = "bold"
  ) +
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Hhohho County", subtitle = "A county") +
  xlab("longitude") +
  ylab("latitude") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

new_sf_obj_2 <- swz_int_1 %>%
  filter(NAME_1 == "Shiselweni")

plot3 <- swz_int_2 %>%
  filter(NAME_1 == "Shiselweni") %>%
  ggplot() +
  theme_light() +
  geom_sf(
    size = 0.5,
    color = "#ff7539",
    fill = "#654F97",
    alpha = 1
  ) +
  geom_sf_text(
    aes(label = NAME_2),
    size = 2,
    color = "#EFE7D9",
  ) +
  geom_sf(
    data = new_sf_obj_2,
    size = 1,
    color = "#EF486D",
    fill = "#000000",
    alpha = 0.0
  ) +
  geom_sf_text(
    data = new_sf_obj_2,
    aes(label = NAME_1),
    size = 3,
    color = "#EFE7D9",
    fontface = "bold"
  ) +
  xlab("longitude") +
  ylab("latitude") +
  ggtitle("Shiselweni County", subtitle = "A county") +
  xlab("longitude") +
  ylab("latitude") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "azure"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

ggplot() +
  coord_equal(xlim = c(0, 6.0), ylim = c(0, 4), expand = FALSE) +
  annotation_custom(ggplotGrob(plot1),
    xmin = 0.0, xmax = 4.0, ymin = 0,
    ymax = 4.0
  ) +
  annotation_custom(ggplotGrob(plot3),
    xmin = 4.0, xmax = 6.0, ymin = 0,
    ymax = 2.0
  ) +
  annotation_custom(ggplotGrob(plot2),
    xmin = 4.0, xmax = 6.0, ymin = 2.0,
    ymax = 4.0
  ) +
  theme_void()

ggsave("details.png")

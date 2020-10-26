rm(list = ls(all = TRUE))

library(RColorBrewer)
library(tidyverse)
library(sf)
library(raster)
library(maptools)
library(haven)
library(spatstat)
library(missForest)
library(doParallel)
library(caret)
library(nnet)
library(ggplot2)



setwd("~/Desktop/data-science/data")

# adm1 simple features object
swz_adm1 <- read_sf("gadm36_SWZ_shp/gadm36_SWZ_1.shp")

# Read in household and individual recode data
dhs_household <- read_dta("DHS_data/SZHR51DT/szhr51fl.dta")
dhs_individual <- read_dta("DHS_data/SZIR51DT/szir51fl.dta")

# Read in the raster data
swaziland_raster_pop06 <- raster("world_pop/swz_ppp_2006.tif")
save(swaziland_raster_pop06, file="Rdata/swaziland_raster_pop06.Rdata")
plot(swaziland_raster_pop06)

# cellStats: compute things for cells in raster data
pop <- ceiling(cellStats(swaziland_raster_pop06, "sum"))

# Statistic from online says the average household size is 4.6
swz_avg_household_size = 4.6
houses = ceiling(pop / 4.6)

# Use select to easily subset columns and put in a new, revised data frame 
dhs_vars <- dhs_household %>% dplyr::select(hhid, hv005, hv009, hv024, hv104_01:hv104_34, hv105_01:hv105_34, hv106_01:hv106_34)

gender_pivot_sample <- dhs_vars %>%
  gather(key = "person_number", value = "gender", colnames(dhs_vars)[5:38]) %>%
  dplyr::select(hhid:hv024, person_number, gender)

age_pivot_sample <- dhs_vars %>%
  gather(key = "person_number", value = "age", colnames(dhs_vars)[39:72]) %>%
  dplyr::select(hhid:hv024, person_number, age)

edu_pivot_sample <- dhs_vars %>%
  gather(key = "person_number", value = "education", colnames(dhs_vars)[73:106]) %>%
  dplyr::select(hhid:hv024, person_number, education)

swz_pns_sample <- cbind.data.frame(gender_pivot_sample, age=age_pivot_sample$age, education=edu_pivot_sample$education) %>% filter(!(is.na(gender) & is.na(age) & is.na(education)))

swz_pns_preprocess_sample <- swz_pns_sample %>% 
  dplyr::select(gender, age, education)

# We want to do this using parallel processing to speed it up; we can use a max of 3 cores for our three variables
registerDoParallel(cores=3)

# Now we do the actual imputation here with 20 trees per random forest
swz_pns_impute_sample <- missForest(xmis = as.matrix(swz_pns_preprocess_sample), maxiter = 5, ntree = 20, parallelize = "forests")

# ximp corresponds to our dataframe
swz_pns_complete_sample <- as.data.frame(swz_pns_impute_sample$ximp)

# Put it back together
swz_pns_sample <- swz_pns_sample %>% dplyr::select(-c(gender, age, education)) %>% bind_cols(swz_pns_complete_sample) %>% mutate(education = round(education), age=round(age))
save(swz_pns_sample, file="Rdata/swz_pns_sample.Rdata")

################################################################################
# Rpoint: locating households

# Read in the shape file
swz_mt = readShapeSpatial("gadm36_SWZ_shp/gadm36_SWZ_1.shp")

# Restricts where we put the random points to just swaziland
win <- as(swz_mt, "owin")
win_bad <- as(swz_mt, "owin")

# Randomly distribute houses according to the population distribution
swz_houses <- rpoint(houses, f = as.im(swaziland_raster_pop06), win = win)
swz_houses_bad <- rpoint(houses, f = 1, win = win_bad)

# Save our plot of the randomly distributed houses according to the raster data
png("images/swz_random_points.png", width = 2000, height = 2000)
plot(win, main = NULL)
plot(swz_houses, cex = 0.5, add=TRUE)
dev.off()

# Save our plot of the randomly distributed houses according to the raster data
png("images/swz_random_points_bad.png", width = 2000, height = 2000)
plot(win_bad, main = NULL)
plot(swz_houses_bad, cex = 0.5, add=TRUE)
dev.off()

# Now instead of distributing the entire population, we only want to distribute as
# many household in our dataset by each adm1

# To do this with only our four adm1's, we can subset all observations by hv024
# and then distibute the r points randomly according the the underlying raster 
# distribution. Then we can match up these random points to actual households. 

# Key:
# 1     hhohho
# 2    manzini
# 3 shiselweni
# 4    lubombo

# Step 1: Get the number of households in each region according to the DHS household data
region_counts_of_houses <- dhs_household %>%
  dplyr::select(hv024) %>%
  mutate(hv024 = as_factor(hv024)) %>%
  count(hv024)

# Crop and mask each region to the correct raster
hhohho_region <- crop(swaziland_raster_pop06, swz_adm1 %>% filter(NAME_1=="Hhohho")) %>% mask(swz_adm1 %>% filter(NAME_1=="Hhohho"))
manzini_region <- crop(swaziland_raster_pop06, swz_adm1 %>% filter(NAME_1=="Manzini")) %>% mask(swz_adm1 %>% filter(NAME_1=="Manzini"))
shiselweni_region <- crop(swaziland_raster_pop06, swz_adm1 %>% filter(NAME_1=="Shiselweni")) %>% mask(swz_adm1 %>% filter(NAME_1=="Shiselweni"))
lubombo_region <- crop(swaziland_raster_pop06, swz_adm1 %>% filter(NAME_1=="Lubombo")) %>% mask(swz_adm1 %>% filter(NAME_1=="Lubombo"))

# Write the sf object back to shape files
st_write(filter(swz_adm1, NAME_1=="Hhohho"), "hhohho_region.shp", delete_dsn=TRUE)
st_write(filter(swz_adm1, NAME_1=="Manzini"), "manzini_region.shp", delete_dsn=TRUE)
st_write(filter(swz_adm1, NAME_1=="Shiselweni"), "shiselweni_region.shp", delete_dsn=TRUE)
st_write(filter(swz_adm1, NAME_1=="Lubombo"), "lubombo_region.shp", delete_dsn=TRUE)

# Read in each new shape file as a map tools object
swz_hhohho_mt <- readShapeSpatial("hhohho_region.shp")
swz_manzini_mt <- readShapeSpatial("manzini_region.shp")
swz_shiselweni_mt <- readShapeSpatial("shiselweni_region.shp")
swz_lubombo_mt <- readShapeSpatial("lubombo_region.shp")

win_hhohho <- as(swz_hhohho_mt, "owin")
win_manzini <- as(swz_manzini_mt, "owin")
win_shiselweni <- as(swz_shiselweni_mt, "owin")
win_lubombo <- as(swz_lubombo_mt, "owin")

vector_of_counts <- deframe(region_counts_of_houses)

# Create rpoint distributions for each adm1
hhohho_houses <- rpoint(vector_of_counts["hhohho"] %>% as.numeric(), f = as.im(hhohho_region), win = win_hhohho)
save(hhohho_houses, file="Rdata/hhohho_houses.RData")
manzini_houses <- rpoint(vector_of_counts["manzini"] %>% as.numeric(), f = as.im(manzini_region), win = win_manzini)
save(manzini_houses, file="Rdata/manzini_houses.RData")
shiselweni_houses <- rpoint(vector_of_counts["shiselweni"], f = as.im(shiselweni_region), win = win_shiselweni)
save(shiselweni_houses, file="Rdata/shiselweni_houses.RData")
lubombo_houses <- rpoint(vector_of_counts["lubombo"], f = as.im(lubombo_region), win = win_lubombo)
save(lubombo_houses, file="Rdata/lubombo_houses.RData")

# Make images of all of our rpoint plots
png("images/hhohho_rpoint.png", width = 2000, height = 2000)
plot(win_hhohho, main = NULL)
plot(hhohho_houses, cex = 5, add=TRUE)
dev.off()

png("images/manzini_rpoint.png", width = 2000, height = 2000)
plot(win_manzini, main = NULL)
plot(manzini_houses, cex = 5, add=TRUE)
dev.off()

png("images/shiselweni_rpoint.png", width = 2000, height = 2000)
plot(win_shiselweni, main = NULL)
plot(shiselweni_houses, cex = 5, add=TRUE)
dev.off()

png("images/lubombo_rpoint.png", width = 2000, height = 2000)
plot(win_lubombo, main = NULL)
plot(lubombo_houses, cex = 5, add=TRUE)
dev.off()

# Stack up our new data rows until we make two new, complete latitude longitude values
all_houses <- rbind.data.frame(as.data.frame(hhohho_houses), as.data.frame(manzini_houses), as.data.frame(shiselweni_houses), as.data.frame(lubombo_houses))

# Order them the same way as before when we bind them
dhs_vars <- dhs_vars %>%
  arrange(hv024) %>%
  bind_cols(all_houses)
save(dhs_vars, file="Rdata/dhs_vars.Rdata")

# Next step: convert lat/long to sf
# https://gis.stackexchange.com/questions/222978/lon-lat-to-simple-features-sfg-and-sfc-in-r
houses_sf = st_as_sf(dhs_vars, coords = c("x", "y"), crs = 4326)


png("images/improved_swz_rpoint.png", width = 2000, height = 2000)
plot(st_geometry(swz_adm1))
plot(st_geometry(houses_sf), cex = 0.5, add = TRUE)
dev.off()

plot(st_geometry(swz_adm1))
plot(st_geometry(houses_sf), cex = 0.5, add = TRUE)


nb.cols <- 4
mycolors <- colorRampPalette(brewer.pal(20, "PiYG"))(nb.cols)

households_ggplot <- ggplot() +
  theme_light() +
  geom_sf(
    data = swz_adm1,
    size = 1,
    color = "#4a536b",
    fill = "azure",
    alpha = 1
  ) +
  geom_sf(
    data = houses_sf,
    mapping = aes(color = as_factor(hv024)),
    size = 0.5,
    fill = "azure",
    alpha = 0.3
  ) +
  scale_color_manual(values = mycolors) +
  xlab("longitude") +
  ylab("latitude") +
  labs(color = "Region") +
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "white"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )
households_ggplot

ggsave("images/eswatini_households.png")

#####################
# Expand our survey data for households to the entire population by distributing the number of households
# equal to the number of households in the population (ish) using rpoint and then sample with 
# replacement to generate our shell data

# From the DHS report our average household size is 4.6
swz_avg_household_size <- 4.6
swz_household_n <- floor(cellStats(swaziland_raster_pop06, 'sum') / swz_avg_household_size)
save(swz_household_n, file="Rdata/swz_household_n.RData")

swz_mt = readShapeSpatial("gadm36_SWZ_shp/gadm36_SWZ_0.shp")

# Restricts where we put the random points to just swaziland
win_final <- as(swz_mt, "owin")
save(win_final, file="Rdata/win_final.Rdata")

# Randomly distribute houses according to the population distribution
# Now we are generating all points for the entire population
# Could use a point process model to be more accurate but meh
hhs_pts <- rpoint(swz_household_n, f = as.im(swaziland_raster_pop06), win = win_final)

# Save our plot of the randomly distributed houses
png("images/swz_random_points_entire_population.png", width = 2000, height = 2000)
plot(win, main = NULL)
plot(hhs_pts, cex = 0.5, add=TRUE)
dev.off()


# Make this into a data frame
# Easier to work with sf objects (just use same crs geometry i.e. same reference coordinates)
hhs_locs <- cbind.data.frame(x = hhs_pts$x, y = hhs_pts$y)
hhs_locs_notsf <- cbind.data.frame(x = hhs_pts$x, y = hhs_pts$y)

# Randomly sample from generate households to get to the total number of households for our population
hhs_pop <- slice_sample(dhs_vars, n = swz_household_n, replace = TRUE)

# Check our error by comparing sum of weights to our number of rows
sum(hhs_pop$hv005 / 10e5) # Sum the weights that we have randomly sampled from all households
nrow(hhs_pop) # number of household observations
nrow(hhs_locs)

# Put the households together with the population and their sf object geometries corresponding to location
# We are randomly repeating households --> heterogeneous population but there was a location of the 
# household and threw it all over the country multiple times
swz_hhs_locs <- cbind.data.frame(hhs_pop, hhs_locs)
hhs_locs_notsf <- cbind.data.frame(dplyr::select(hhs_pop, -x, -y), hhs_locs)

# Pivot the data so we have individuals 
# We still know which household they belong to because of their household ids

# dhs_vars <- dhs_household %>% dplyr::select(hhid, hv005, hv009, hv024, hv104_01:hv104_34, hv105_01:hv105_34, hv106_01:hv106_34)

gender_pivot <- hhs_locs_notsf %>%
  gather(key = "person_number", value = "gender", colnames(dhs_vars)[5:38]) %>%
  dplyr::select(hhid:hv024, x, y, person_number, gender)

age_pivot <- hhs_locs_notsf %>% 
  gather(key = "person_number", value = "age", colnames(dhs_vars)[39:72]) %>%
  dplyr::select(hhid:hv024, x, y, person_number, age)

edu_pivot <- hhs_locs_notsf %>%
  gather(key = "person_number", value = "education", colnames(dhs_vars)[73:106]) %>%
  dplyr::select(hhid:hv024, x, y, person_number, education)

# Sort variables for use/validation
swz_pns <- cbind.data.frame(gender_pivot, age=age_pivot$age, education=edu_pivot$education) %>% filter(!(is.na(gender) & is.na(age) & is.na(education)))
save(swz_pns, file="Rdata/swz_pns.Rdata")

nrow(swz_pns)
sum(swz_pns$hv005 / 10e5)

# Error from weights
(1 - (nrow(swz_pns) / sum(swz_pns$hv005 / 10e5) ))*100

cellStats(swaziland_raster_pop06, 'sum')
# Error from underlying population density raster
(1 - (nrow(swz_pns) / cellStats(swaziland_raster_pop06, 'sum')))*100 # compare DHS-based, generated synthetic person total proportion to ML/EO output


################################################################################
# Data imputation

# At this point we have 145 empty cells for age and 6760 empty cells for education

swz_pns_preprocess <- swz_pns %>% 
  dplyr::select(gender, age, education)

# We want to do this using parallel processing to speed it up; we can use a max of 3 cores for our three variables
registerDoParallel(cores=3)

# Now we do the actual imputation here with 20 trees per random forest
swz_pns_impute <- missForest(xmis = as.matrix(swz_pns_preprocess), maxiter = 5, ntree = 20, parallelize = "forests")

# ximp corresponds to our dataframe
swz_pns_complete <- as.data.frame(swz_pns_impute$ximp)

# We can check that we no longer have any null values
is.na(swz_pns_complete) %>% sum()

# Final, preprocessed data
swz_pns <- swz_pns %>% dplyr::select(-c(gender, age, education)) %>% bind_cols(swz_pns_complete)  %>% mutate(education = round(education), age=round(age))

save(swz_pns, file = "Rdata/swz_pns.Rdata")

proportions_sample <- swz_pns_sample %>% dplyr::count(education) %>% mutate(prop=n/sum(n))
proportions_shell <- swz_pns %>% dplyr::count(education) %>% mutate(prop=n/sum(n))
proportions_here <- data.frame(type=c(rep("Sample data", 5), rep("Shell data", 5)), education=c(proportions_sample$prop, proportions_shell$prop), level=rep(proportions_shell$education, 2))

ggplot(data=proportions_here, aes(x=level, y=education, fill=as.factor(type))) +
  theme_light() +
  geom_col(position = "dodge2") +
  labs(x = "Education level", y = "Proportion", fill = "")+
  theme(
    plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
    panel.background = element_rect(fill = "white"),
    panel.border = element_rect(fill = NA),
    panel.grid = element_blank()
  )

ggsave("images/edu_valid.png")

write_csv(swz_pns_sample, "swz_final_sample_data.csv")
write_csv(swz_pns, "swz_final_shell_data.csv")


################################################################################
# Multinomial logistic regression model

# Train test split for education, 70/30 train and test split
index <- as.numeric(createDataPartition(swz_pns_sample$education, p = .70, list = FALSE))
train <- swz_pns_sample[index,]
test <- swz_pns_sample[-index,]

# Import library for our multinomal logistic regression model
# multinom_model <- multinom(education ~ hv009 + gender + age, data = swz_pns_sample)
save(multinom_model, file = "Rdata/multinom_model.RData")
load("Rdata/multinom_model.RData")

# Predicting the values for test dataset
test$eduPredicted <- predict(multinom_model, newdata = test, "class")

((test$eduPredicted == test$education) %>% sum()) / nrow(test)

write_csv(swz_pns_sample, "swz_pns_sample.csv")












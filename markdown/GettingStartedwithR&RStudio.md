# Getting Started with R & RStudio

### Date: 8/24/2020

## Path of the Running Boy
First, I created a path of the running boy by plotting x against y with a negative slope as seen below. 

```
x <- 1:10
y <- 10:1
plot(x, y, type = "b", main = "The Path of a Running Boy", 
     sub = "units of distance = meters", 
     xlab = "longitude", 
     ylab = "latitude",
     lty = 2,
     lwd = .75,
     col = "blue",
     pch = 0,
     cex = 1)
```

![Path of the Running Boy](ABM/images/ThePathOfTheRunningBoy.png)

## A Traveling Salesperson
Next I learned about random samply in R and plotted 10 dwellings, 10 small trees, 10 large trees, and created a labeled path between three houses using a dashed spline.

```
# Initialize x & y
x <- 1:100
y <- 1:100

# Randomy select from x & y and replace result
east <- sample(x, size = 10, replace = TRUE)
north <- sample(y, size = 10, replace = TRUE)

# Repeat length of each square 0.75 ten times or once per square
symbols(east, north, squares = rep(.75,10), inches = FALSE)

# 10 small trees
symbols(sample(x, 10, replace = TRUE), 
        sample(y, 10, replace = TRUE), 
        circles = rep(.75,10), 
        inches = FALSE,
        fg = "green1",
        bg = "beige",
        add = TRUE)

# 10 large trees
symbols(sample(x, 10, replace = TRUE), 
        sample(y, 10, replace = TRUE), 
        circles = rep(1.5,10), 
        inches = FALSE,
        fg = "green4",
        bg = "beige",
        add = TRUE)

# Create a data frame
dwellings <- cbind.data.frame(id = 1:10, east, north)

# Sample 3 dwellings along our path
locs <- sample(1:10, 3, replace = FALSE)

# lines(x = dwellings[locs, 2], # Easterly coordinate
#       y = dwellings[locs, 3], # Northernly coordinate
#       lty = 2,
#       lwd = .75,
#       col = "blue")
# Annotate all houses
# text(x = dwellings$east,
#      y = dwellings$north+3,
#      labels = dwellings$id)

# Only annotate houses we visit
text(x = dwellings[locs, ]$east, 
     y = dwellings[locs, ]$north + 3,
     labels = dwellings[locs, ]$id)

# Make the walking path more realistic
xspline(x = dwellings[locs, 2], # Easterly coordinate
        y = dwellings[locs, 3], # Northernly coordinate
        shape = -1,
        lty = 2)

# Add a title to the plot
title(main="A Traveling Salesperson")
```

![A Traveling Salesperson (Original)](images/ATravelingSalespersonOriginal.png)

## A Traveling Salesperson (Challenge Problem)

Finally, I completed the challenge problem by creating a 1000 by 1000 area and placing 50 dwellings, 40 small trees, 12 large trees, and a dashed spline connecting 7 labeled homes. Additionally, each small tree is about the same width as each dwelling and each large tree is approximately twice as large. 

```
# Create x & y and allow them to attain values between 1 & 1000
x <- 1:1000
y <- 1:1000

# Randomy select from x & y and replace result
east <- sample(x, size = 50, replace = TRUE)
north <- sample(y, size = 50, replace = TRUE)

# Repeat length of each square 15 fifty times or once per square
symbols(east, north, squares = rep(15,50), inches = FALSE)

# 40 small trees
symbols(sample(x, 40, replace = TRUE), 
        sample(y, 40, replace = TRUE), 
        circles = rep(10,40), 
        inches = FALSE,
        fg = "green1",
        bg = "beige",
        add = TRUE)

# 12 large trees
symbols(sample(x, 12, replace = TRUE),
        sample(y, 12, replace = TRUE),
        circles = rep(20,12),
        inches = FALSE,
        fg = "green4",
        bg = "beige",
        add = TRUE)

# Create a data frame
dwellings <- cbind.data.frame(id = 1:10, east, north)

# Sample 7 dwellings along our path
locs <- sample(1:10, 7, replace = FALSE)

# Only annotate houses we visit
text(x = dwellings[locs, ]$east, 
     y = dwellings[locs, ]$north + 40,
     labels = dwellings[locs, ]$id)

# Make the walking path more realistic
xspline(x = dwellings[locs, 2], # Easterly coordinate
        y = dwellings[locs, 3], # Northernly coordinate
        shape = -1,
        lty = 2)

# Add a title to the plot
title(main="A Traveling Salesperson")
```

![A Traveling Salesperson (Challenge)](images/ATravelingSalespersonChallenge.png)

[Link](GettingStartedWithR.R) to complete, downloadable code.

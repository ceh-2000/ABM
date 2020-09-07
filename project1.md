# Population Data for Swaziland

### Date: 8/26/2020

## Assignment
First I zoom in on an adm2, specifically Pigg's Peak, by cropping and masking the image.
![Pigg's Peak Image](images/agg_pigg.png)

Then I use the spatial probablity distribution to find places to put people.
`pigg_adm2_ppp <- rpoint(pop, f = as.im(swz_pop20_adm2), win = win)`
`as.im` converts raster data to a pixel image and then distributes random points according.
![Pigg's Peak Image](images/pigg_random_people.png)


[Here](scripts/DefactoDescriptionSwaziland.R) is the code.


# Creating De Facto Settlements in Pigg's Peak

### Date: 9/7/2020

## Assignment
First, I zoom in on an adm2, specifically Pigg's Peak, by cropping and masking the image.
![Pigg's Peak Image](images/agg_pigg.png)

Then, I use the spatial probablity distribution to find places to put people.

`pigg_adm2_ppp <- rpoint(pop, f = as.im(swz_pop20_adm2), win = win)`

`as.im` converts raster data to a pixel image and then distributes random points according.
![Pigg's Peak Image](images/pigg_random_people.png)

With `bw <- bw.ppl(pigg_adm2_ppp)`, I create a probablity density function or kernel density estimation.

Next, I draw initial settlemtns by contouring my image. Here is the density image updated with lines enclosing areas of high density.
![Pigg's Peak Image](images/pigg_lines_density_image.png)

Now we look at the inner polygons
![Pigg's Peak Image](images/pigg_inner_polygons.png)
and the outer "polygons."
![Pigg's Peak Image](images/pigg_outer_polygons.png)

These outer polygons are not closed because we need to intersect them with Pigg's Peak's border. 

```
my_outer_polys <- st_buffer(outside_lines, 0.0014) %>%
  st_difference(pigg_adm2, .) %>%
  st_cast(., "POLYGON")
 ```
 
Now, we see that the polygons mostly close. There are some issues that can't be mitigating by increasing buffer or reducing the density threshold as we can see my the lines in the middle of the figure that never intersect the border.
![Pigg's Peak Image](images/pigg_outer_polygons_intersecting.png)

Next, I plot these polygons over the original density image.
![Pigg's Peak Image](images/subpolys.png)

Filter out outer polygons that have neglible populations.
![Pigg's Peak Image](images/subpolys_filtered.png)
Repeat and remove inner polygons with negligible populations. 

```
uas <- st_union(inside_polys_filtered, subpolys_filtered)
urban_areas <- st_cast(uas, "POLYGON")
``` 
Then, I want to join the inner-filtered and outer-filtered polygons to create a group of polygons corresponding to urban areas.
![Pigg's Peak Image](images/urban_areas.png)

Finally, I recolor our de factor urban area settlements based on population size and list the density for each settlement.
![Pigg's Peak Image](images/urban_areas_plot.png)

[Here](scripts/DefactoDescriptionSwaziland.R) is the code.


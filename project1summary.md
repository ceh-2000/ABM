# Project 1

For this first project I was looking at population, population density, accessibility, and topography in different subdivisions of Eswatini.

## [Part 1.a.](densitySwaziland.md)  
For part a of the first part, I recolored a map of Eswatini's first level subdivisions based on population and noted the density of each subdivision on the plot. Later, I decided to focus on Hhohho, one of Eswatini's subdivisions. I chose it because it included the capital city and had varying populations and densities in each of its second level subdivisions, so I thought it would be interesting to investigate these differences further.

## [Part 1.b.](project1.md) 
In part b, I first tried to generate de factor settlements for Hhhohho. However, the calculations were computationally expensive and finding the bandwidth argument took over an hour. Therefore, I decided to Pigg's Peak, a secodnary subdivision in Hhohho that we can see from part a as a medium-to-smaller population and smaller density compared to other second-level subdivisions in Hhohho. 

I generated de facto settlements by randomly distributing the population according to raster population data and then generating polygons grouping people into settlements. One problem I had was with the polygons that were supposed to intersect the border. Even when I adjusted different parameters like `buffer`, the lines would not quite interesect the outer bounding polygons, so a may have lost some de facto settlements i.e. the area in the west. 

Finally, I compared the settlement population and rank to see if they conformed to Zipf's law. In general, the power law trend was present, even though my populations dropped off faster than what Zipf's law predicted.  

## [Part 2](project1_part2.md) 
Next, I was interested in looking at accessibility as determined by roads and healthcare. I had the following types of highways in Pigg's Peak: primary, secondary, unclassified, tertiary, residential, track, service, and path. I decided to classify the roads into 3 levels. The first level corresponding the largest roads included primary and secondary roads. The second level included unclassified and tertiary roads. Lastly, the smallest roads included residential and path roads in level three. Examining the plotted road networks, it makes sense that large roads go through larger settlements and connect the de facto settlements. Then smaller roads branch off and connect to the more rural parts.

After examining road data, I turned my attention to healthcare data. There are two hospitals right next to each other in the center of the largest de facto settlement. This makes sense that the hospitals would be placed to reach the most people. What I do not understand is why there are two right next to each other. I predict that these two hospitals are affiliated hence their proximity.  

## [Part 3](project1_part3.md)  
In the last part of the project, I added in topographic data. In higher gradient regions of Pigg's Peak, there were fewer or no de facto settlements. As expected, people are unlikely to live on steep inclines. When we combine this topographic information with accessibility data and de facto settlements, we generate a pretty descriptive view of Eswatini's Pigg's Peak.

####All step for our method:Integrating Street-View Imagery and Points of Interest for Refining Population Spatialization

##Step1:Data preprocessing

#remove bad data
poi_map = poi_in_wuhan
mobile_positioning_point_map = mobile_positioning_point_in_wuhan

#spatial refrence unification to WGS84
poi_map = wgs84(poi_map)
svi_collection_location_map = wgs84(svi_collection_location_map)
mobile_positioning_point_map = wgs84(mobile_positioning_point_map)
wuhan_city_map =  wgs84(wuhan_city_map)
wuhan_street_map =  wgs84(wuhan_street_map)
wuhan_community_map = wgs84(wuhan_community_map)
wuhan_water_map = wgs84(wuhan_water_map)

#map projection to Gauss-Krüger
poi_map = projection(poi_map,Gauss-Krüger)
svi_collection_location_map = projection(svi_collection_location_map,Gauss-Krüger)
mobile_positioning_point_map = projection(mobile_positioning_point_map,Gauss-Krüger)
wuhan_street_map = projection(wuhan_street_map,Gauss-Krüger)
wuhan_community_map = projection(wuhan_community_map,Gauss-Krüger)
wuhan_water_map = projection(wuhan_water_map,Gauss-Krüger)

#create 100m x 100m grid
wuhan_grid_map = CreateFishnet_management(wuhan_city_map,100m,100m)

#get streetId and communityId of every grid
grid_street_map = wuhan_grid_map.spatialjoin(wuhan_street_map)
grid_community_map = wuhan_grid_map.spatialjoin(grid_community_map)

#water of every grid
grid_water_map = wuhan_grid_map.spatialjoin(wuhan_water_map)

##Step2:Feature extraction and selection

#POI feature extraction in different level
#spatial join poi and different level map
poi_grid = poi_map.spatialjoin(wuhan_grid_map)            
poi_community = poi_map.spatialjoin(wuhan_community_map)
poi_street = poi_map.spatialjoin(wuhan_street_map)

#Count the density of POIs of different categories within each cell.
grid_poi_19_density = pivot_table(poi_grid.df, index='grid_Id', columns='categories',aggfunc='size', fill_value=0)

for each communityId:
  community_poi_19_density =   sum(grid_poi_19_density)  /community_grid_count 

for each streetId:
  streetId_poi_19_density =   sum(grid_poi_19_density)  /street_grid_count 

#SVI feature extraction in different level
#calculate image-level SVI feature
SVI_semantic_result = DeeplabV3Plus(image)

#SVI features in grid-level,street-level
grid_SVI = average(SVI_semantic_result in same grid)
street_SVI = average(SVI_semantic_result in same street)

#SVI features in community-level
#create 20-meter buffer in wuhan_community_map
wuhan_community_map_buffer = wuhan_community_map.buffer(20)

#search SVI collection locations with the buffer zone in community
for each communityId:
   get all SVI collection locations with the buffer zone in community
   SVI_com_list = []
   #select SVI in the community through the shooting angle
	for each SVI collection location in the buffer:
		if center_of_gravity_of_community is to the right of the image_collection_direction:
			SVI_com_list.append( SVI_semantic_result shooting_angle = 90 )
		else:
			SVI_com_list.append( SVI_semantic_result shooting_angle = 270 ) 
    for SVI collection location in the community:
	        SVI_com_list.append( SVI_semantic_result shooting_angle = 270 and shooting_angle = 90 ) 

community_SVI = average(SVI_com_list)

#Adjusted grid-level SVI feature construction
adjusted_grid_SVI = alpha * community_SVI + (1-alpha)* grid_SVI

#feature selection CSCM -Algorithm 1 in paper

##Step3:Population modeling and prediction
street_level_features = concat(selected_poi_street,selected_SVI_street)
street_level_pop_density =  street-level_pop/area

grid_level_features = concat(selected_poi_grid,selected_adjusted_grid_SVI)

#train model
random_forest_model = RandomForestRegressor()
random_forest_model.fit(street_level_features,street_level_pop_density)

#predict model
grid_pop_prediction= random_forest_model.predict(grid_level_features)

##Step4:Population allocation with adjusted weights
# water grid has no population
if grid in water_grid_list:
   grid_pop_prediction[grid] = 0

#county population allocation
for every county in wuhan:
	count_county_predict = sum(grid_pop_prediction in county)
	for every grid in county:
	   grid_pop_prediction[grid] = grid_pop_prediction[grid]/count_county_predict * real_pop_county
	   
	   

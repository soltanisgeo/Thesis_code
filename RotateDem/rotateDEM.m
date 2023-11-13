% Parameters
L = 50000; %length of block
r = 55.226684; %angle of rotation
dem_file = 'Deep.tif';

% Add path
addpath(genpath('dem/'));

% Read DEM data
dem_img = geotiffread(dem_file);
dem_info = geotiffinfo(dem_file);

% Create longitude and latitude vectors
lon = dem_info.RefMatrix(3,1):dem_info.RefMatrix(2,1):dem_info.RefMatrix(3,1) + dem_info.RefMatrix(2,1) * (size(dem_img,2) - 1);
lat = dem_info.RefMatrix(3,2):dem_info.RefMatrix(1,2):dem_info.RefMatrix(3,2) + dem_info.RefMatrix(1,2) * (size(dem_img,1) - 1);

% Create meshgrid
[Lon, Lat] = meshgrid(lon, lat);

% Plot DEM
figure;
dem(lon, lat, dem_img, 'Contrast', 0);

% Set reference point
lon0 = 51.00;
lat0 = 35.80;

% Convert reference point to UTM
[X0, Y0, zone] = deg2utm(lat0, lon0);

% Define rectangle coordinates
Rect_coordinate = [X0 Y0; X0+L Y0; X0+L Y0+L; X0 Y0+L; X0 Y0];

% Rotate rectangle
R = [cosd(r) sind(r); -sind(r) cosd(r)];
Rect_rotated = (R * (Rect_coordinate' - [X0; Y0]))' + [X0; Y0];

% Convert rotated coordinates to latitudes and longitudes
[lat_rec, lon_rec] = utm2deg(Rect_rotated(:,1), Rect_rotated(:,2), repmat(zone, [5 1]));

% Plot rotated rectangle
hold on;
line(lon_rec, lat_rec, 'linewidth', 2, 'color', 'r');

% Create mask
mask = inpolygon(Lon, Lat, lon_rec, lat_rec);

% Crop data
Lon_crop = Lon(mask == 1);
Lat_crop = Lat(mask == 1);
Dem_crop = double(dem_img(mask == 1));

% Scatter plot of cropped data
figure;
scatter(Lon_crop, Lat_crop, 10, Dem_crop, '.');

% Convert cropped data to UTM
[X_crop, Y_crop, zone] = deg2utm(Lat_crop, Lon_crop);
XY_r = R' * [X_crop(:) - X0, Y_crop(:) - Y0]';
XY_r(1, :) = XY_r(1, :) + X0;
XY_r(2, :) = XY_r(2, :) + Y0;

% Create a grid and interpolate DEM data
[X_g, Y_g] = meshgrid(min(XY_r(1, :)) + 60:30:max(XY_r(1, :)) - 60, min(XY_r(2, :)) + 60:30:max(XY_r(2, :)) - 60);
dem_g = griddata(XY_r(1, :), XY_r(2, :), Dem_crop, X_g, Y_g);

% Plot interpolated DEM
figure;
imagesc([min(X_g(:)), max(X_g(:))], [min(Y_g(:)), max(Y_g(:))], dem_g);
set(gca, 'YDir', 'normal');

% Save as TIFF and ASCII files
imwrite(flipud(dem_g), 'deep-tiff.tiff', 'tiff');
dlmwrite('FinalBedrockDeepNewwithControlPoint.asc', flipud(dem_g), 'delimiter', ' ', 'precision', '%.6f');

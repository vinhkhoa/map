//  VKMap

#import "MPViewController.h"

#import "MPUserLocationButtonView.h"

@import Mapbox;
@import MapboxDirections;

static double kDefaultZoomLevel = 11;
static int kRouteZoomEdgePadding = 40;
static int kUserLocationButtonSize = 50;
static int kUserLocationMarginBottom = 40;
static int kUserLocationMarginRight = 20;

typedef void (^FindRoutesSuccessBlock)(NSArray<MBRoute *> *routes);
typedef void (^FindRoutesFailureBlock)(NSError *error);

@interface MPViewController() <MGLMapViewDelegate, CLLocationManagerDelegate, MPUserLocationButtonViewDelegate>
@end

@implementation MPViewController
{
	MGLMapView *_mapView;
	UILongPressGestureRecognizer *_longPressGR;
	CLLocationManager *_locationManager;
	BOOL _didZoomToUserLocation;
	NSMutableArray<id<MGLAnnotation>> *_annotations;
	NSMutableArray<MGLSource *> *_mapSources;
	NSMutableArray<MGLStyleLayer *> *_mapLayers;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	_annotations = [NSMutableArray array];
	_mapSources = [NSMutableArray array];
	_mapLayers = [NSMutableArray array];

	// Location manager
	_locationManager = [CLLocationManager new];
	_locationManager.delegate = self;
	const CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
	if (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
			authStatus == kCLAuthorizationStatusAuthorizedAlways) {
		[_locationManager startUpdatingLocation];
	} else {
		[_locationManager requestWhenInUseAuthorization];
	}

	// Map view
	NSURL *const url = [NSURL URLWithString:@"mapbox://styles/mapbox/streets-v10"];
	_mapView = [[MGLMapView alloc] initWithFrame:self.view.bounds styleURL:url];
	_mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_mapView];
	_mapView.delegate = self;

	_longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPressedOnMap:)];
	[_mapView addGestureRecognizer:_longPressGR];

	// User location button
	MPUserLocationButtonView *const userLocationButtonView =
	[[MPUserLocationButtonView alloc]
	 initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - kUserLocationMarginRight - kUserLocationButtonSize,
														CGRectGetHeight(self.view.frame) - kUserLocationMarginBottom - kUserLocationButtonSize,
														kUserLocationButtonSize,
														kUserLocationButtonSize)
	 delegate:self];
	userLocationButtonView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	[self.view addSubview:userLocationButtonView];
}

- (void)dealloc
{
	[_mapView removeGestureRecognizer:_longPressGR];
}

#pragma mark - Map Gesture

- (void)_longPressedOnMap:(UILongPressGestureRecognizer *)longPressGR
{
	if (longPressGR.state == UIGestureRecognizerStateBegan) {
		const CGPoint location = [longPressGR locationInView:longPressGR.view];
		const CLLocationCoordinate2D coordinate = [_mapView convertPoint:location toCoordinateFromView:_mapView];
		[self _addDestinationAtCoordinate:coordinate];
	}
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	const CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
	if (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
			authStatus == kCLAuthorizationStatusAuthorizedAlways) {
		[_locationManager startUpdatingLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
	if (!_didZoomToUserLocation) {
		_didZoomToUserLocation = YES;
		[_mapView setCenterCoordinate:locations.lastObject.coordinate
												zoomLevel:kDefaultZoomLevel
												 animated:YES];
		_mapView.showsUserLocation = YES;
	}
}

#pragma mark - MGLMapViewDelegate

- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id<MGLAnnotation>)annotation
{
	return YES;
}

#pragma mark - MPUserLocationButtonViewDelegate

- (void)userLocationButtonViewDidTap:(MPUserLocationButtonView *)userLocationButtonView
{
	[_mapView setCenterCoordinate:_mapView.userLocation.coordinate
											zoomLevel:kDefaultZoomLevel
											 animated:YES];
}

#pragma mark - Private

- (void)_addDestinationAtCoordinate:(CLLocationCoordinate2D)coordinate
{
	[self _resetMapOverlays];

	MGLPointAnnotation *destination = [[MGLPointAnnotation alloc] init];
	destination.coordinate = coordinate;
	destination.title = @"Destination";
	[_mapView addAnnotation:destination];
	[_annotations addObject:destination];

	__weak typeof(self) weakSelf = self;
	FindRoutes(_mapView.userLocation.coordinate,
						 coordinate,
						 ^(NSArray<MBRoute *> *routes) {
							 [weakSelf _displayRoutes:routes];
						 }, ^(NSError *error) {
							 [weakSelf _showFindRoutesError:error];
						 });
}

- (void)_resetMapOverlays
{
	if (_annotations) {
		[_mapView removeAnnotations:_annotations];
		[_annotations removeAllObjects];
	}

	[_mapLayers enumerateObjectsUsingBlock:^(MGLStyleLayer * _Nonnull layer, NSUInteger idx, BOOL * _Nonnull stop) {
		[_mapView.style removeLayer:layer];
	}];
	[_mapLayers removeAllObjects];

	[_mapSources enumerateObjectsUsingBlock:^(MGLSource * _Nonnull source, NSUInteger idx, BOOL * _Nonnull stop) {
		[_mapView.style removeSource:source];
	}];
	[_mapSources removeAllObjects];
}

- (void)_showFindRoutesError:(NSError *)error
{
	UIAlertController *const alertController = [UIAlertController alertControllerWithTitle:@"Error"
																																					 message:@"Could not find any routes"
																																		preferredStyle:UIAlertControllerStyleAlert];
	__weak typeof(self) weakSelf = self;
	[alertController addAction:[UIAlertAction actionWithTitle:@"OK"
																											style:UIAlertActionStyleDefault
																										handler:^(UIAlertAction * _Nonnull action) {
																											[weakSelf dismissViewControllerAnimated:YES completion:nil];
																										}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Routes

- (void)_displayRoutes:(NSArray<MBRoute *> *)routes
{
	for (NSInteger i = routes.count - 1; i >= 0; i--) {
		[self _displayRoute:routes[i] selected:(i == 0)];
	};
}

- (void)_displayRoute:(MBRoute *)route
						 selected:(BOOL)selected
{
	if (route.coordinateCount) {
		// Add route source and layer to map
		MGLShapeSource *const source = SourceForRoute(route);
		MGLLineStyleLayer *const layer = LineLayerForSource(source, route.legs.firstObject.name, selected);

		[_mapView.style addSource:source];
		[_mapView.style addLayer:layer];
		[_mapSources addObject:source];
		[_mapLayers addObject:layer];

		// Zoom in if selected
		if (selected) {
			[self _zoomToRoute:route];
		}
	}
}

- (void)_zoomToRoute:(MBRoute *)route
{
	CLLocationCoordinate2D *routeCoordinates = malloc(route.coordinateCount * sizeof(CLLocationCoordinate2D));
	[route getCoordinates:routeCoordinates];

	[_mapView setVisibleCoordinates:routeCoordinates
														count:route.coordinateCount
											edgePadding:UIEdgeInsetsMake(kRouteZoomEdgePadding, kRouteZoomEdgePadding, kRouteZoomEdgePadding, kRouteZoomEdgePadding)
												 animated:YES];

	free(routeCoordinates);
}

#pragma mark - Helpers

static void FindRoutes(CLLocationCoordinate2D fromLocation,
											 CLLocationCoordinate2D toLocation,
											 FindRoutesSuccessBlock successBlock,
											 FindRoutesFailureBlock failureBlock)
{
	NSArray<MBWaypoint *> *const waypoints =
	@[
		[[MBWaypoint alloc] initWithCoordinate:fromLocation coordinateAccuracy:-1 name:@"From"],
		[[MBWaypoint alloc] initWithCoordinate:toLocation coordinateAccuracy:-1 name:@"To"],
		];
	MBRouteOptions *const options = [[MBRouteOptions alloc]
																	 initWithWaypoints:waypoints
																	 profileIdentifier:MBDirectionsProfileIdentifierAutomobileAvoidingTraffic];
	options.includesAlternativeRoutes = YES;
	options.includesSteps = YES;

	[[MBDirections sharedDirections]
	 calculateDirectionsWithOptions:options
	 completionHandler:^(NSArray<MBWaypoint *> * _Nullable waypoints,
											 NSArray<MBRoute *> * _Nullable routes,
											 NSError * _Nullable error) {
		 if (error) {
			 if (failureBlock) {
				 failureBlock(error);
			 }
		 } else {
			 if (successBlock) {
				 successBlock(routes);
			 }
		 }
	 }];
}

static MGLShapeSource *SourceForRoute(MBRoute *route)
{
	CLLocationCoordinate2D *routeCoordinates = malloc(route.coordinateCount * sizeof(CLLocationCoordinate2D));
	[route getCoordinates:routeCoordinates];
	MGLPolylineFeature *const line = [MGLPolylineFeature polylineWithCoordinates:routeCoordinates
																																				 count:route.coordinateCount];
	free(routeCoordinates);

	return [[MGLShapeSource alloc] initWithIdentifier:route.legs.firstObject.name
																					 features:@[line]
																						options:nil];
}

static MGLLineStyleLayer *LineLayerForSource(MGLShapeSource *source,
																						 NSString *identifier,
																						 BOOL selected)
{
	MGLLineStyleLayer *const layer = [[MGLLineStyleLayer alloc] initWithIdentifier:identifier
																																					source:source];
	layer.lineWidth = [MGLStyleValue valueWithRawValue:@4];
	layer.lineColor = (selected ?
										 [MGLStyleValue valueWithRawValue:[UIColor blueColor]] :
										 [MGLStyleValue valueWithRawValue:[UIColor grayColor]]);
	return layer;
}



/*static NSString *TravelTimeLabelForRoute(MBRoute *route)
 {
 NSDateComponentsFormatter *const travelTimeFormatter = [[NSDateComponentsFormatter alloc] init];
 travelTimeFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
 return [travelTimeFormatter stringFromTimeInterval:route.expectedTravelTime];
 }

 static NSString *DistanceLabelForLeg(MBRouteLeg *leg)
 {
 NSLengthFormatter *const distanceFormatter = [[NSLengthFormatter alloc] init];
 return [distanceFormatter stringFromMeters:leg.distance];
 }*/

/*
 MBRoute *const route = routes.firstObject;
 MBRouteLeg *const leg = route.legs.firstObject;
 if (leg) {
 NSLog(@"Route via %@:", leg);

 NSString *const formattedTravelTime = TravelTimeLabelForRoute(route);
 NSString *const formattedDistance = DistanceLabelForLeg(leg);

 NSLog(@"Distance: %@; ETA: %@", formattedDistance, formattedTravelTime);

 for (MBRouteStep *step in leg.steps) {
 NSLog(@"%@", step.instructions);
 //NSString *formattedDistance = [distanceFormatter stringFromMeters:step.distance];
 //NSLog(@"— %@ —", formattedDistance);
 }
 }
 */




@end

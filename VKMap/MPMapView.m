//  VKMap

#import "MPMapView.h"
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

@interface MPMapView() <MGLMapViewDelegate, MPUserLocationButtonViewDelegate>
@end

@implementation MPMapView
{
	MGLMapView *_mapView;
	BOOL _didZoomToUserLocation;
	UILongPressGestureRecognizer *_longPressGR;
	NSMutableArray<id<MGLAnnotation>> *_annotations;
	NSMutableArray<MGLSource *> *_mapSources;
	NSMutableArray<MGLStyleLayer *> *_mapLayers;
	id<MPMapViewDelegate> _delegate;
}

- (instancetype)initWithFrame:(CGRect)frame
										 delegate:(id<MPMapViewDelegate>)delegate
{
	if (self = [super initWithFrame:frame]) {
		_delegate = delegate;
		_annotations = [NSMutableArray array];
		_mapSources = [NSMutableArray array];
		_mapLayers = [NSMutableArray array];

		// Map view
		NSURL *const url = [NSURL URLWithString:@"mapbox://styles/mapbox/streets-v10"];
		_mapView = [[MGLMapView alloc] initWithFrame:self.bounds styleURL:url];
		_mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_mapView];
		_mapView.delegate = self;

		_longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPressedOnMap:)];
		[_mapView addGestureRecognizer:_longPressGR];

		// User location button
		MPUserLocationButtonView *const userLocationButtonView =
		[[MPUserLocationButtonView alloc]
		 initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - kUserLocationMarginRight - kUserLocationButtonSize,
															CGRectGetHeight(self.bounds) - kUserLocationMarginBottom - kUserLocationButtonSize,
															kUserLocationButtonSize,
															kUserLocationButtonSize)
		 delegate:self];
		userLocationButtonView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		[self addSubview:userLocationButtonView];
	}
	return self;
}

- (void)dealloc
{
	[_mapView removeGestureRecognizer:_longPressGR];
}

#pragma mark - Public

- (void)setUserLocationCoordinate:(CLLocationCoordinate2D)coordinate
{
	if (!_didZoomToUserLocation) {
		_didZoomToUserLocation = YES;

		[_mapView setCenterCoordinate:coordinate
												zoomLevel:kDefaultZoomLevel
												 animated:YES];
		_mapView.showsUserLocation = YES;
	}
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
	if ([_delegate respondsToSelector:@selector(mapView:didFailToFindRoutesWithError:)]) {
		[_delegate mapView:self didFailToFindRoutesWithError:error];
	}
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

@end

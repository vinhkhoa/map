//  VKMap

#import "ViewController.h"

@import Mapbox;
@import MapboxDirections;

static double kInitialZoomLevel = 11;

@interface ViewController() <MGLMapViewDelegate, CLLocationManagerDelegate>
@end

@implementation ViewController
{
	MGLMapView *_mapView;
	UILongPressGestureRecognizer *_longPressGR;
	MGLPointAnnotation *_destinationAnnotation;
	CLLocationManager *_locationManager;
	BOOL _didZoomToUserLocation;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	_locationManager = [CLLocationManager new];
	_locationManager.delegate = self;
	const CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
	if (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
			authStatus == kCLAuthorizationStatusAuthorizedAlways) {
		[_locationManager startUpdatingLocation];
	} else {
		[_locationManager requestWhenInUseAuthorization];
	}

	NSURL *const url = [NSURL URLWithString:@"mapbox://styles/mapbox/streets-v10"];
	_mapView = [[MGLMapView alloc] initWithFrame:self.view.bounds styleURL:url];
	_mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_mapView];
	_mapView.delegate = self;

	_longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPressedOnMap:)];
	[_mapView addGestureRecognizer:_longPressGR];

	MBDirections *directions = [MBDirections sharedDirections];
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
		[self _addDestinationToCoordinate:coordinate];
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
												zoomLevel:kInitialZoomLevel
												 animated:YES];
		_mapView.showsUserLocation = YES;
	}
}

#pragma mark - MGLMapViewDelegate

- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id<MGLAnnotation>)annotation
{
	return YES;
}

#pragma mark - Private

- (void)_addDestinationToCoordinate:(CLLocationCoordinate2D)coordinate
{
	if (_destinationAnnotation) {
		[_mapView removeAnnotation:_destinationAnnotation];
	}

	_destinationAnnotation = [[MGLPointAnnotation alloc] init];
	_destinationAnnotation.coordinate = coordinate;
	_destinationAnnotation.title = @"Destination";
	[_mapView addAnnotation:_destinationAnnotation];
}

@end

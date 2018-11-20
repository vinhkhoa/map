//  VKMap

#import "MPViewController.h"
#import "MPMapView.h"
#import "MPMapStylesView.h"

@interface MPViewController() <CLLocationManagerDelegate, MPMapViewDelegate>
@end

@implementation MPViewController
{
  CLLocationManager *_locationManager;
  MPMapView *_mapView;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Map view
  _mapView = [[MPMapView alloc] initWithFrame:self.view.bounds 
                                     delegate:self];
  _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:_mapView];

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
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  [_mapView.mapStylesView highlightDefaultMapStyle];
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
  [_mapView setUserLocationCoordinate:locations.lastObject.coordinate];
}

#pragma mark - MPMapViewDelegate

- (void)mapView:(MPMapView *)mapView didFailToFindRoutesWithError:(NSError *)error
{
  UIAlertController *const alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                 message:@"Could not find any routes to the destination"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
  __weak typeof(self) weakSelf = self;
  [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                      [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                                    }]];
  [self presentViewController:alertController animated:YES completion:nil];
}

@end

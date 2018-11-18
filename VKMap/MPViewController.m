//  VKMap

#import "MPViewController.h"
#import "MPMapView.h"

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

//  VKMap

#import "ViewController.h"

@import Mapbox;

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	NSURL *const url = [NSURL URLWithString:@"mapbox://styles/mapbox/streets-v10"];
	MGLMapView *const mapView = [[MGLMapView alloc] initWithFrame:self.view.bounds styleURL:url];
	mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[mapView setCenterCoordinate:CLLocationCoordinate2DMake(59.31, 18.06)
										 zoomLevel:9
											animated:NO];
	[self.view addSubview:mapView];
}

@end

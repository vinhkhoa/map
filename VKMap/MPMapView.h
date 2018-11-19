//  VKMap

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class MPMapView;
@class MPMapStylesView;

@protocol MPMapViewDelegate <NSObject>

- (void)mapView:(MPMapView *)mapView didFailToFindRoutesWithError:(NSError *)error;

@end

@interface MPMapView : UIView

@property (strong, nonatomic, readonly) MPMapStylesView *mapStylesView;

- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<MPMapViewDelegate>)delegate;

- (void)setUserLocationCoordinate:(CLLocationCoordinate2D)coordinate;

@end

//  VKMap

#import <UIKit/UIKit.h>

@class MBRoute;

@interface MPRouteView : UIView

@property (strong, nonatomic) MBRoute *route;
@property (assign, nonatomic) BOOL scrollEnabled;

@end

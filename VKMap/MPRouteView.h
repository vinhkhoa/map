//  VKMap

#import <UIKit/UIKit.h>

@class MBRoute;

extern CGFloat MPRouteViewTableBottomInset;

@interface MPRouteView : UIView

@property (strong, nonatomic) MBRoute *route;
@property (assign, nonatomic) BOOL scrollEnabled;

@end

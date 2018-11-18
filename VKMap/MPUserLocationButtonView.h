//  VKMap

#import <UIKit/UIKit.h>

@class MPUserLocationButtonView;

@protocol MPUserLocationButtonViewDelegate <NSObject>

- (void)userLocationButtonViewDidTap:(MPUserLocationButtonView *)userLocationButtonView;

@end

@interface MPUserLocationButtonView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<MPUserLocationButtonViewDelegate>)delegate;

@end

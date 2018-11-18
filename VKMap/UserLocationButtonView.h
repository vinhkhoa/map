//  VKMap

#import <UIKit/UIKit.h>

@class UserLocationButtonView;

@protocol UserLocationButtonViewDelegate <NSObject>

- (void)userLocationButtonViewDidTap:(UserLocationButtonView *)userLocationButtonView;

@end

@interface UserLocationButtonView : UIView

- (instancetype)initWithFrame:(CGRect)frame
										 delegate:(id<UserLocationButtonViewDelegate>)delegate;

@end

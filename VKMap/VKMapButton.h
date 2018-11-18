//  VKMap

#import <UIKit/UIKit.h>

@class MPMapButton;

@protocol MPMapButtonDelegate <NSObject>

- (void)userLocationButtonViewDidTap:(MPMapButton *)userLocationButtonView;

@end

@interface MPMapButton : UIView

- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<MPMapButtonDelegate>)delegate;

@end

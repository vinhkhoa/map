//  VKMap

#import <UIKit/UIKit.h>

@class MPMapButton;

@protocol MPMapButtonDelegate <NSObject>

- (void)mapButtonDidTap:(MPMapButton *)mapButton;

@end

@interface MPMapButton : UIView

- (instancetype)initWithFrame:(CGRect)frame
                    imageName:(NSString *)imageName
                     delegate:(id<MPMapButtonDelegate>)delegate;

@end

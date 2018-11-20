//  VKMap

#import <UIKit/UIKit.h>
#import "MPMapStyleIdentifiers.h"

extern NSString *MPDefaultMapStyleURL(void);

@class MPMapStylesView;

@protocol MPMapStylesViewDelegate<NSObject>

- (void)mapStylesView:(MPMapStylesView *)mapStylesView didSelectMapStyleURL:(NSString *)mapStyleURL;

@end

@interface MPMapStylesView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<MPMapStylesViewDelegate>)delegate;
- (void)highlightDefaultMapStyle;

@end

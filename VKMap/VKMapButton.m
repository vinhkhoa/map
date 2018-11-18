//  VKMap

#import "MPMapButton.h"

@implementation MPMapButton
{
  id<MPMapButtonDelegate> _delegate;
  UITapGestureRecognizer *_tapGR;
}

- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<MPMapButtonDelegate>)delegate
{
  if (self = [super initWithFrame:frame]) {
    _delegate = delegate;

    const CGFloat size = CGRectGetWidth(frame);
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = size / 2;
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 0.2;

    UIImageView *const imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"crosshair"]];
    imageView.frame = CGRectMake(size/4, size/4, size/2, size/2);
    [self addSubview:imageView];

    _tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapped:)];
    [self addGestureRecognizer:_tapGR];
  }
  return self;
}

- (void)dealloc
{
  [self removeGestureRecognizer:_tapGR];
}

- (void)_tapped:(id)sender
{
  if ([_delegate respondsToSelector:@selector(userLocationButtonViewDidTap:)]) {
    [_delegate userLocationButtonViewDidTap:self];
  }
}

@end

//  VKMap

#import "MPRouteHeaderView.h"

static const CGFloat kPadding = 15;

@implementation MPRouteHeaderView
{
  UILabel *_etaLabel;
  UILabel *_distanceLabel;
  BOOL _didSetupConstraints;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _etaLabel = [UILabel new];
    _etaLabel.font = [UIFont boldSystemFontOfSize:20];
    [self addSubview:_etaLabel];

    _distanceLabel = [UILabel new];
    _distanceLabel.font = [UIFont boldSystemFontOfSize:20];
    [self addSubview:_distanceLabel];
  }
  return self;
}

- (void)setupWithETA:(NSString *)eta distance:(NSString *)distance
{
  _etaLabel.text = eta;
  _distanceLabel.text = distance;
  [self setNeedsUpdateConstraints];
}

- (void)updateConstraints
{
  if (!_didSetupConstraints) {
    // == ETA
    _etaLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // Right align
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_etaLabel
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:-kPadding]];

    // Center vertically
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_etaLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];

    // == Distance
    _distanceLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // Left align
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_distanceLabel
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1
                                                      constant:kPadding]];

    // Center vertically
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_distanceLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];

    _didSetupConstraints = YES;
  }
  [super updateConstraints];
}

@end

//  VKMap

#import "MPRouteHeaderTableViewCell.h"

static const CGFloat kPadding = 15;

@implementation MPRouteHeaderTableViewCell
{
  UILabel *_etaLabel;
  UILabel *_distanceLabel;
  BOOL _didSetupConstraints;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    _etaLabel = [UILabel new];
    _etaLabel.font = [UIFont boldSystemFontOfSize:20];
    [self.contentView addSubview:_etaLabel];

    _distanceLabel = [UILabel new];
    _distanceLabel.font = [UIFont boldSystemFontOfSize:20];
    [self.contentView addSubview:_distanceLabel];
  }
  return self;
}

- (void)setupWithETA:(NSString *)eta distance:(NSString *)distance
{
  _etaLabel.text = eta;
  _distanceLabel.text = distance;
  [self.contentView setNeedsUpdateConstraints];
}

- (void)updateConstraints
{
  if (!_didSetupConstraints) {
    // == ETA
    _etaLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // Right align
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_etaLabel
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1
                                                                  constant:-kPadding]];

    // Center vertically
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_etaLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];

    // == Distance
    _distanceLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // Left align
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_distanceLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1
                                                                  constant:kPadding]];

    // Center vertically
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_distanceLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];

    _didSetupConstraints = YES;
  }
  [super updateConstraints];
}

@end

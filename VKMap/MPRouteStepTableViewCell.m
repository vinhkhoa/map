//  VKMap

#import "MPRouteStepTableViewCell.h"

static const CGFloat kPadding = 15;

@implementation MPRouteStepTableViewCell
{
  UILabel *_instructionsLabel;
  UILabel *_distanceLabel;
  BOOL _didSetupConstraints;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    _distanceLabel = [UILabel new];
    _distanceLabel.font = [UIFont systemFontOfSize:15];
    [self.contentView addSubview:_distanceLabel];

    _instructionsLabel = [UILabel new];
    _instructionsLabel.font = [UIFont systemFontOfSize:15];
    [self.contentView addSubview:_instructionsLabel];
  }
  return self;
}

- (void)setupWithInstructions:(NSString *)instructions distance:(NSString *)distance
{
  _instructionsLabel.text = instructions;
  _distanceLabel.text = distance;
  [self.contentView setNeedsUpdateConstraints];
}

- (void)updateConstraints
{
  if (!_didSetupConstraints) {
    // == Distance
    _distanceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_distanceLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                    forAxis:UILayoutConstraintAxisHorizontal];

    // Right align
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_distanceLabel
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1
                                                                  constant:-kPadding]];

    // Center vertically
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_distanceLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];

    // == Instructions
    _instructionsLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // Left align
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_instructionsLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1
                                                                  constant:kPadding]];

    // Center vertically
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_instructionsLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];

    // Margin right to distance label
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_instructionsLabel
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:_distanceLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1
                                                                  constant:-kPadding]];

    _didSetupConstraints = YES;
  }
  [super updateConstraints];
}

@end

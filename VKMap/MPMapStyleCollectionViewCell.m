//  VKMap

#import "MPMapStyleCollectionViewCell.h"
#import "MPMapStyleSelection.h"

static const CGFloat kImageRatio = 0.625; // = 5/8

@implementation MPMapStyleCollectionViewCell
{
  UIImageView *_imageView;
  UILabel *_nameLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _imageView = [[UIImageView alloc] initWithImage:nil];
    _imageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds) * kImageRatio);
    _imageView.layer.borderWidth = 2;
    _imageView.layer.borderColor = [UIColor clearColor].CGColor;
    [self.contentView addSubview:_imageView];

    _nameLabel = [UILabel new];
    _nameLabel.font = [UIFont systemFontOfSize:14];
    _nameLabel.textColor = [UIColor blackColor];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.frame = CGRectMake(0, CGRectGetWidth(self.bounds) * kImageRatio, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds) * (1 - kImageRatio));
    [self.contentView addSubview:_nameLabel];
  }
  return self;
}

- (void)setMapStyleSelection:(MPMapStyleSelection *)mapStyleSelection
{
  _imageView.image = [UIImage imageNamed:mapStyleSelection.imageName];
  _nameLabel.text = mapStyleSelection.name;
}

- (void)setSelected:(BOOL)selected
{
  _imageView.layer.borderColor = (selected ? [UIColor blueColor].CGColor : [UIColor clearColor].CGColor);
}

@end

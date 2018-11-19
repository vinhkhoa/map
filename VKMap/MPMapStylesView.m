//  VKMap

#import "MPMapStylesView.h"
#import "MPMapStyleCellCollectionViewCell.h"
#import "MPMapStyleSelection.h"

static const CGSize kMapStyleCellSize = {80, 70};
static const int kMapStyleCellSpacing = 20;
static const int kColumnCount = 3;
static const int kPaddingV = 20;
static NSString *const kCellID = @"CellID";
static const MPMapStyleIdentifier DefaultMapStyleIdentifier = MPMapStyleIdentifierStreets;

static NSArray<MPMapStyleSelection *> *MapStyleSelections()
{
  static NSArray<MPMapStyleSelection *> *selections;
  if (!selections) {
    selections = @[
                   [[MPMapStyleSelection alloc] initWithIdentifier:MPMapStyleIdentifierBasic name:@"Basic" styleURL:@"mapbox://styles/mapbox/basic-v9" imageName:@"mapstyle-basic"],
                   [[MPMapStyleSelection alloc] initWithIdentifier:MPMapStyleIdentifierStreets name:@"Streets" styleURL:@"mapbox://styles/mapbox/streets-v9" imageName:@"mapstyle-streets"],
                   [[MPMapStyleSelection alloc] initWithIdentifier:MPMapStyleIdentifierBright name:@"Bright" styleURL:@"mapbox://styles/mapbox/bright-v9" imageName:@"mapstyle-bright"],
                   [[MPMapStyleSelection alloc] initWithIdentifier:MPMapStyleIdentifierLight name:@"Light" styleURL:@"mapbox://styles/mapbox/light-v9" imageName:@"mapstyle-light"],
                   [[MPMapStyleSelection alloc] initWithIdentifier:MPMapStyleIdentifierDark name:@"Dark" styleURL:@"mapbox://styles/mapbox/dark-v9" imageName:@"mapstyle-dark"],
                   [[MPMapStyleSelection alloc] initWithIdentifier:MPMapStyleIdentifierSatellite name:@"Satellite" styleURL:@"mapbox://styles/mapbox/satellite-v9" imageName:@"mapstyle-satellite"]
                   ];
  }
  return selections;
}

static NSUInteger DefaultMapStyleIndex(void)
{
  return [MapStyleSelections() indexOfObjectPassingTest:^BOOL(MPMapStyleSelection * _Nonnull selection, NSUInteger idx, BOOL * _Nonnull stop) {
    return selection.identifier == DefaultMapStyleIdentifier;
  }];
}

NSString *MPDefaultMapStyleURL(void)
{
  return [MapStyleSelections() objectAtIndex:DefaultMapStyleIndex()].styleURL;
}

@interface MPMapStylesView() <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@end

@implementation MPMapStylesView
{
  UICollectionView *_collectionView;
  UICollectionViewFlowLayout *_collectionViewLayout;
  id<MPMapStylesViewDelegate> _delegate;
}

- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<MPMapStylesViewDelegate>)delegate
{
  if (self = [super initWithFrame:frame]) {
    _delegate = delegate;

    self.backgroundColor = [UIColor whiteColor];
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 0.2;

    _collectionViewLayout = [UICollectionViewFlowLayout new];
    _collectionViewLayout.itemSize = kMapStyleCellSize;
    _collectionViewLayout.minimumInteritemSpacing = kMapStyleCellSpacing;
    _collectionViewLayout.minimumLineSpacing = kMapStyleCellSpacing;

    _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:_collectionViewLayout];
    _collectionView.backgroundColor = [UIColor whiteColor];
    [_collectionView registerClass:[MPMapStyleCellCollectionViewCell class] forCellWithReuseIdentifier:kCellID];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [self addSubview:_collectionView];

    //if (selection.identifier == DefaultMapStyleIdentifier) {
    //}
  }
  return self;
}

- (void)invalidateLayout
{
  [_collectionViewLayout invalidateLayout];
}

- (void)highlightDefaultMapStyle
{
  NSIndexPath *const defaultIndexPath = [NSIndexPath indexPathForItem:DefaultMapStyleIndex() inSection:0];
  [_collectionView selectItemAtIndexPath:defaultIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return MapStyleSelections().count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  MPMapStyleSelection *const selection = [MapStyleSelections() objectAtIndex:indexPath.item];
  MPMapStyleCellCollectionViewCell *const cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
  cell.mapStyleSelection = selection;
  return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
  // Force contents to be centered
  const CGFloat contentWidth = (kMapStyleCellSize.width*kColumnCount + kMapStyleCellSpacing*(kColumnCount - 1));
  const CGFloat insetH = floorf((CGRectGetWidth(collectionView.bounds) - contentWidth) / 2);
  return UIEdgeInsetsMake(kPaddingV, insetH, kPaddingV, insetH);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if ([_delegate respondsToSelector:@selector(mapStylesView:didSelectMapStyleURL:)]) {
    [_delegate mapStylesView:self didSelectMapStyleURL:[MapStyleSelections() objectAtIndex:indexPath.item].styleURL];
  }
}

@end

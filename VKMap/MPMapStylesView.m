//  VKMap

#import "MPMapStylesView.h"
#import "MPMapStyleCollectionViewCell.h"
#import "MPMapStyleSelection.h"

static const CGSize kMapStyleCellSize = {80, 70};
static const int kMapStyleCellSpacing = 20;
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
  __weak id<MPMapStylesViewDelegate> _delegate;
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
    _collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionViewLayout.sectionInset = UIEdgeInsetsMake(kMapStyleCellSpacing, kMapStyleCellSpacing, kMapStyleCellSpacing, kMapStyleCellSpacing);

    _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:_collectionViewLayout];
    [_collectionView registerClass:[MPMapStyleCollectionViewCell class] forCellWithReuseIdentifier:kCellID];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.alwaysBounceHorizontal = YES;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [self addSubview:_collectionView];
  }
  return self;
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
  MPMapStyleCollectionViewCell *const cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
  cell.mapStyleSelection = selection;
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if ([_delegate respondsToSelector:@selector(mapStylesView:didSelectMapStyleURL:)]) {
    [_delegate mapStylesView:self didSelectMapStyleURL:[MapStyleSelections() objectAtIndex:indexPath.item].styleURL];
  }
}

@end

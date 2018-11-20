//  VKMap

#import "MPRouteView.h"
#import "MPRouteStepTableViewCell.h"
#import "MPRouteHeaderView.h"

CGFloat MPRouteViewTableBottomInset = 150;

static NSString *const kCellIDStep = @"cellIDStep";

static const int kHeaderViewHeight = 60;
static const int kCellHeightStep = 40;

@import MapboxDirections;

@interface MPRouteView() <UITableViewDataSource, UITableViewDelegate>
@end

@implementation MPRouteView
{
  MBRoute *_route;
  UITableView *_tableView;
  NSLengthFormatter *_distanceFormatter;
  NSDateComponentsFormatter *_travelTimeFormatter;
  BOOL _isDragging;
  MPRouteHeaderView *_headerView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.backgroundColor = [UIColor whiteColor];
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 0.2;

    _headerView = [[MPRouteHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), kHeaderViewHeight)];
    _headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:_headerView];

    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kHeaderViewHeight, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - kHeaderViewHeight) style:UITableViewStylePlain];
    [_tableView registerClass:[MPRouteStepTableViewCell class] forCellReuseIdentifier:kCellIDStep];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.rowHeight = kCellHeightStep;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, MPRouteViewTableBottomInset, 0);
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self addSubview:_tableView];

    NSNumberFormatter *const distanceNumberFormatter = [NSNumberFormatter new];
    distanceNumberFormatter.maximumFractionDigits = 2;

    _distanceFormatter = [NSLengthFormatter new];
    _distanceFormatter.unitStyle = NSFormattingUnitStyleShort;
    _distanceFormatter.numberFormatter = distanceNumberFormatter;

    _travelTimeFormatter = [[NSDateComponentsFormatter alloc] init];
    _travelTimeFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
  }
  return self;
}

- (void)setRoute:(MBRoute *)route
{
  _route = route;
  [_headerView setupWithETA:[_travelTimeFormatter stringFromTimeInterval:_route.expectedTravelTime]
                   distance:[_distanceFormatter stringFromMeters:_route.distance]];
  [_tableView reloadData];
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
  _tableView.scrollEnabled = scrollEnabled;
}

- (BOOL)scrollEnabled
{
  return _tableView.scrollEnabled;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return _route.legs.firstObject.steps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  MBRouteStep *const step = _route.legs.firstObject.steps[indexPath.row];
  MPRouteStepTableViewCell *const cell = [tableView dequeueReusableCellWithIdentifier:kCellIDStep forIndexPath:indexPath];
  [cell setupWithInstructions:step.instructions
                     distance:(step.distance > 0 ? [_distanceFormatter stringFromMeters:step.distance] : nil)];
  return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  return NO;
}

@end

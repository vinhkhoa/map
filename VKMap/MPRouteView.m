//  VKMap

#import "MPRouteView.h"
#import "MPRouteStepTableViewCell.h"
#import "MPRouteHeaderTableViewCell.h"

static const int kHeaderRowIndex = 0;
static NSString *const kCellIDHeader = @"cellIDHeader";
static NSString *const kCellIDStep = @"cellIDStep";

static const int kCellHeightHeader = 60;
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
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 0.2;

    _tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    [_tableView registerClass:[MPRouteHeaderTableViewCell class] forCellReuseIdentifier:kCellIDHeader];
    [_tableView registerClass:[MPRouteStepTableViewCell class] forCellReuseIdentifier:kCellIDStep];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
  [_tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (_route.legs.firstObject.steps.count) {
    return _route.legs.firstObject.steps.count + 1;
  } else {
    return 0;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == kHeaderRowIndex) {
    MPRouteHeaderTableViewCell *const cell = [tableView dequeueReusableCellWithIdentifier:kCellIDHeader forIndexPath:indexPath];
    [cell setupWithETA:[_travelTimeFormatter stringFromTimeInterval:_route.expectedTravelTime]
              distance:[_distanceFormatter stringFromMeters:_route.distance]];
    return cell;
  } else {
    MBRouteStep *const step = _route.legs.firstObject.steps[indexPath.row - 1];
    MPRouteStepTableViewCell *const cell = [tableView dequeueReusableCellWithIdentifier:kCellIDStep forIndexPath:indexPath];
    [cell setupWithInstructions:step.instructions
                       distance:[_distanceFormatter stringFromMeters:step.distance]];
    return cell;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return (indexPath.row == kHeaderRowIndex ? kCellHeightHeader : kCellHeightStep);
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  return NO;
}

@end

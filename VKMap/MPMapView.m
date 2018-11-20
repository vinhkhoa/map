//  VKMap

#import "MPMapView.h"
#import "MPMapButton.h"
#import "MPMapStylesView.h"
#import "MPRouteView.h"

@import Mapbox;
@import MapboxDirections;

static const double kDefaultZoomLevel = 11;

static const int kRouteZoomEdgePaddingTop = 60;
static const int kRouteZoomEdgePaddingLeft = 40;
static const int kRouteZoomEdgePaddingBottom = 60;
static const int kRouteZoomEdgePaddingRight = 40;

static const int kMapButtonSize = 50;
static const int kUserLocationMarginBottom = 40;
static const int kUserLocationMarginRight = 20;
static const int kSettingsButtonMarginTop = 60;
static const int kSettingsButtonMarginRight = 20;

static NSString *const kAttributeKeyIsRoute = @"is_route";
static NSString *const kAttributeKeyIsSelectedRoute = @"is_selected_route";

static const int kMapStylesViewHeight = 110;

static const int kRouteViewHeight = 200;

typedef void (^FindRoutesSuccessBlock)(NSArray<MBRoute *> *routes);
typedef void (^FindRoutesFailureBlock)(NSError *error);

typedef NS_ENUM (NSInteger, PolylineTapResult) {
  PolylineTapResultNotARoute,
  PolylineTapResultSelectedRoute,
  PolylineTapResultAlternativeRoute
};

@interface MPMapView() <MGLMapViewDelegate, MPMapButtonDelegate, MPMapStylesViewDelegate>
@end

@implementation MPMapView
{
  MGLMapView *_mapView;
  BOOL _didZoomToUserLocation;
  UILongPressGestureRecognizer *_longPressGR;
  UITapGestureRecognizer *_tapGR;
  NSMutableArray<id<MGLAnnotation>> *_annotations;
  NSMutableArray<MGLSource *> *_mapSources;
  NSMutableArray<MGLStyleLayer *> *_mapLayers;
  id<MPMapViewDelegate> _delegate;
  NSString *_selectedRouteIdentifier;
  NSArray<MBRoute *> *_routes;
  MPMapButton *_userLocationButton, *_settingsButton;
  MPRouteView *_routeView;
}

@synthesize mapStylesView = _mapStylesView;

- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<MPMapViewDelegate>)delegate
{
  if (self = [super initWithFrame:frame]) {
    _delegate = delegate;
    _annotations = [NSMutableArray array];
    _mapSources = [NSMutableArray array];
    _mapLayers = [NSMutableArray array];

    // Map view
    _mapView = [[MGLMapView alloc] initWithFrame:self.bounds styleURL:[NSURL URLWithString:MPDefaultMapStyleURL()]];
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_mapView];
    _mapView.delegate = self;

    // Long press
    _longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPressedOnMap:)];
    [_mapView addGestureRecognizer:_longPressGR];

    // Tap
    _tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tappedOnMap:)];
    for (UIGestureRecognizer *recognizer in _mapView.gestureRecognizers) {
      if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        [_tapGR requireGestureRecognizerToFail:recognizer];
      }
    }
    [_mapView addGestureRecognizer:_tapGR];

    // User location button
    _userLocationButton = [[MPMapButton alloc]
                           initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - kUserLocationMarginRight - kMapButtonSize,
                                                    CGRectGetHeight(self.bounds) - kUserLocationMarginBottom - kMapButtonSize,
                                                    kMapButtonSize,
                                                    kMapButtonSize)
                           imageName:@"crosshair"
                           delegate:self];
    _userLocationButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:_userLocationButton];

    // Settings button
    _settingsButton = [[MPMapButton alloc]
                       initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - kSettingsButtonMarginRight - kMapButtonSize,
                                                kSettingsButtonMarginTop,
                                                kMapButtonSize,
                                                kMapButtonSize)
                       imageName:@"settings"
                       delegate:self];
    _settingsButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:_settingsButton];

    // Map Styles Change
    _mapStylesView = [[MPMapStylesView alloc]
                      initWithFrame:CGRectMake(0,
                                               CGRectGetHeight(self.bounds) - kMapStylesViewHeight,
                                               CGRectGetWidth(self.bounds),
                                               kMapStylesViewHeight)
                      delegate:self];
    _mapStylesView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_mapStylesView];
    [_mapStylesView setHidden:YES];

    // Route details
    _routeView = [[MPRouteView alloc]
                  initWithFrame:CGRectMake(0,
                                           CGRectGetHeight(self.bounds) - kRouteViewHeight,
                                           CGRectGetWidth(self.bounds),
                                           kRouteViewHeight)];
    _routeView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_routeView];
    //[_routeView setHidden:YES];
  }
  return self;
}

- (void)dealloc
{
  [_mapView removeGestureRecognizer:_longPressGR];
  [_mapView removeGestureRecognizer:_tapGR];
}

#pragma mark - Public

- (void)setUserLocationCoordinate:(CLLocationCoordinate2D)coordinate
{
  if (!_didZoomToUserLocation) {
    _didZoomToUserLocation = YES;

    [_mapView setCenterCoordinate:coordinate
                        zoomLevel:kDefaultZoomLevel
                         animated:YES];
    _mapView.showsUserLocation = YES;
  }
}

#pragma mark - Map Gesture

static PolylineTapResult PolylineTapResultWhenTappingOnPolylineFeature(MGLPolylineFeature *feature)
{
  const BOOL isRoute = [[feature.attributes objectForKey:kAttributeKeyIsRoute] boolValue];
  const BOOL isSelectedRoute = [[feature.attributes objectForKey:kAttributeKeyIsSelectedRoute] boolValue];

  if (isRoute && isSelectedRoute) {
    return PolylineTapResultSelectedRoute;
  } else if (isRoute && !isSelectedRoute) {
    return PolylineTapResultAlternativeRoute;
  } else {
    return PolylineTapResultNotARoute;
  }
}

- (void)_longPressedOnMap:(UILongPressGestureRecognizer *)longPressGR
{
  if (longPressGR.state == UIGestureRecognizerStateBegan) {
    const CGPoint location = [longPressGR locationInView:longPressGR.view];
    const CLLocationCoordinate2D coordinate = [_mapView convertPoint:location toCoordinateFromView:_mapView];
    [self _addDestinationAtCoordinate:coordinate];
  }
}

- (void)_tappedOnMap:(UITapGestureRecognizer *)tapGR
{
  if (tapGR.state == UIGestureRecognizerStateEnded) {
    const CGPoint point = [tapGR locationInView:tapGR.view];

    BOOL didTapOnRoute;

    // Check if user exactly tapped on a route
    for (id<MGLFeature> feature in [_mapView visibleFeaturesAtPoint:point]) {
      if ([feature isKindOfClass:[MGLPolylineFeature class]]) {
        didTapOnRoute = [self _handleTapOnPolylineFeatureIfThisIsARoute:(MGLPolylineFeature *)feature];
        if (didTapOnRoute) {
          return;
        }
      }
    }

    // Check if user roughly tapped on a route
    const CGRect pointRect = {point, CGSizeZero};
    const CGRect touchRect = CGRectInset(pointRect, -5.0, -5.0);
    for (id<MGLFeature> feature in [_mapView visibleFeaturesInRect:touchRect]) {
      if ([feature isKindOfClass:[MGLPolylineFeature class]]) {
        didTapOnRoute = [self _handleTapOnPolylineFeatureIfThisIsARoute:(MGLPolylineFeature *)feature];
        if (didTapOnRoute) {
          return;
        }
      }
    }

    // If no routes were tapped on, deselect the selected annotation, if any.
    [_mapView deselectAnnotation:_mapView.selectedAnnotations.firstObject animated:YES];
  }
}

- (BOOL)_handleTapOnPolylineFeatureIfThisIsARoute:(MGLPolylineFeature *)feature
{
  const PolylineTapResult tapResult = PolylineTapResultWhenTappingOnPolylineFeature((MGLPolylineFeature *)feature);
  switch (tapResult) {
    case PolylineTapResultAlternativeRoute:
      [self _handleTapOnPolylineFeatureOfAlternativeRoute:feature];
      return YES;
    case PolylineTapResultSelectedRoute:
      return YES;
    case PolylineTapResultNotARoute:
      return NO;
  }
}

- (void)_handleTapOnPolylineFeatureOfAlternativeRoute:(MGLPolylineFeature *)feature
{
  [self _removeRoutesOnMap];
  _selectedRouteIdentifier = feature.identifier;
  [self _displayCurrentRoutes];
}

#pragma mark - MGLMapViewDelegate

- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id<MGLAnnotation>)annotation
{
  return YES;
}

#pragma mark - MPMapButtonDelegate

- (void)mapButtonDidTap:(MPMapButton *)mapButton
{
  if (mapButton == _userLocationButton) {
    [_mapView setCenterCoordinate:_mapView.userLocation.coordinate
                        zoomLevel:_mapView.zoomLevel
                         animated:YES];
  } else if (mapButton == _settingsButton) {
    if (_mapStylesView.hidden) {
      [self _showMapStylesViewAnimated:YES];
    } else {
      [self _hideMapStylesViewAnimated:YES];
    }
  }
}

#pragma mark - MPMapStylesViewDelegate

- (void)mapStylesView:(MPMapStylesView *)mapStylesView didSelectMapStyleURL:(NSString *)mapStyleURL
{
  if (![_mapView.styleURL.absoluteString isEqualToString:mapStyleURL]) {
    _mapView.styleURL = [NSURL URLWithString:mapStyleURL];

    // WHENEVER WE CHANGE THE MAP STYLEURL, ALL THE ROUTES WILL BE CLEARED
    // SO THIS IS A HACK TO SHOW THEM AGAIN.
    // IDEALLY WE SHOULD HOOK THIS "RE-SHOW ROUTES" INTO THE CALLBACK AFTER STYLEURL HAS BEEN UPDATED
    // BUT NOT SURE HOW TO DO THAT OR WHETHER THAT API EVEN EXISTS
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [self _removeRoutesOnMap];
      [self _displayCurrentRoutes];
    });
  }
}

#pragma mark - Private

- (void)_addDestinationAtCoordinate:(CLLocationCoordinate2D)coordinate
{
  [self _removeAnnotationsOnMap];
  [self _removeRoutesOnMap];

  MGLPointAnnotation *destination = [[MGLPointAnnotation alloc] init];
  destination.coordinate = coordinate;
  destination.title = @"Destination";
  [_mapView addAnnotation:destination];
  [_annotations addObject:destination];

  __weak typeof(self) weakSelf = self;
  FindRoutes(_mapView.userLocation.coordinate,
             coordinate,
             ^(NSArray<MBRoute *> *routes) {
               [weakSelf _handleFoundRoutes:routes];
             }, ^(NSError *error) {
               [weakSelf _showFindRoutesError:error];
             });
}

- (void)_removeAnnotationsOnMap
{
  if (_annotations) {
    [_mapView removeAnnotations:_annotations];
    [_annotations removeAllObjects];
  }
}

#pragma mark - Routes

static NSArray<MBRoute *> *SortedRoutesToPutSelectedRouteFirst(NSArray<MBRoute *> *routes, NSString *selectedRouteIdentifier)
{
  return
  [routes sortedArrayUsingComparator:^NSComparisonResult(MBRoute *_Nonnull route1, MBRoute *_Nonnull route2) {
    if ([route1.legs.firstObject.name isEqualToString:selectedRouteIdentifier]) {
      return NSOrderedAscending;
    } else if ([route2.legs.firstObject.name isEqualToString:selectedRouteIdentifier]) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

- (void)_handleFoundRoutes:(NSArray<MBRoute *> *)routes
{
  _routes = routes;
  [self _displayCurrentRoutes];
}

- (void)_displayCurrentRoutes
{
  // Sort array so that the selected route is the first on the list
  NSArray<MBRoute *> *const sortedRoutes = (_selectedRouteIdentifier ?
                                            SortedRoutesToPutSelectedRouteFirst(_routes, _selectedRouteIdentifier)
                                            : _routes);

  for (NSInteger i = sortedRoutes.count - 1; i >= 0; i--) {
    [self _displayRoute:sortedRoutes[i] selected:(i == 0)];
  };
}

- (void)_displayRoute:(MBRoute *)route
             selected:(BOOL)selected
{
  if (route.coordinateCount) {
    // Add route source and layer to map
    MGLShapeSource *const source = SourceForRoute(route, selected);
    MGLLineStyleLayer *const layer = LineStyleLayerForSource(source, route.legs.firstObject.name, selected);

    [_mapView.style addSource:source];
    [_mapView.style addLayer:layer];
    [_mapSources addObject:source];
    [_mapLayers addObject:layer];

    // Zoom in if selected
    if (selected) {
      [self _zoomToRoute:route];
      _routeView.route = route;
    }
  }
}

- (void)_zoomToRoute:(MBRoute *)route
{
  CLLocationCoordinate2D *routeCoordinates = malloc(route.coordinateCount * sizeof(CLLocationCoordinate2D));
  [route getCoordinates:routeCoordinates];

  [_mapView setVisibleCoordinates:routeCoordinates
                            count:route.coordinateCount
                      edgePadding:UIEdgeInsetsMake(kRouteZoomEdgePaddingTop, kRouteZoomEdgePaddingLeft, kRouteZoomEdgePaddingBottom, kRouteZoomEdgePaddingRight)
                         animated:YES];

  free(routeCoordinates);
}

- (void)_removeRoutesOnMap
{
  [_mapLayers enumerateObjectsUsingBlock:^(MGLStyleLayer * _Nonnull layer, NSUInteger idx, BOOL * _Nonnull stop) {
    [_mapView.style removeLayer:layer];
  }];
  [_mapLayers removeAllObjects];

  [_mapSources enumerateObjectsUsingBlock:^(MGLSource * _Nonnull source, NSUInteger idx, BOOL * _Nonnull stop) {
    [_mapView.style removeSource:source];
  }];
  [_mapSources removeAllObjects];
}

- (void)_showFindRoutesError:(NSError *)error
{
  if ([_delegate respondsToSelector:@selector(mapView:didFailToFindRoutesWithError:)]) {
    [_delegate mapView:self didFailToFindRoutesWithError:error];
  }
}

#pragma mark - Map Styles

- (void)_showMapStylesViewAnimated:(BOOL)animated
{
  const CGRect startFrame = CGRectMake(0,
                                       CGRectGetHeight(self.bounds) + kMapStylesViewHeight,
                                       CGRectGetWidth(self.bounds),
                                       kMapStylesViewHeight);
  const CGRect endFrame = CGRectMake(0,
                                     CGRectGetHeight(self.bounds) - kMapStylesViewHeight,
                                     CGRectGetWidth(self.bounds),
                                     kMapStylesViewHeight);
  _mapStylesView.frame = startFrame;
  _mapStylesView.hidden = NO;

  if (animated) {
    [UIView
     animateWithDuration:0.4
     delay:0
     usingSpringWithDamping:0.87
     initialSpringVelocity:0
     options:UIViewAnimationOptionCurveEaseInOut
     animations:^{
       _mapStylesView.frame = endFrame;
     }
     completion:nil];
  } else {
    _mapStylesView.frame = endFrame;
  }
}

- (void)_hideMapStylesViewAnimated:(BOOL)animated
{
  const CGRect endFrame = CGRectMake(0,
                                     CGRectGetHeight(self.bounds) + kMapStylesViewHeight,
                                     CGRectGetWidth(self.bounds),
                                     kMapStylesViewHeight);
  if (animated) {
    [UIView
     animateWithDuration:0.3
     delay:0
     options:UIViewAnimationOptionCurveEaseOut
     animations:^{
       _mapStylesView.frame = endFrame;
     }
     completion:^(BOOL finished) {
       _mapStylesView.hidden = YES;
     }];
  } else {
    _mapStylesView.frame = endFrame;
  }
}

#pragma mark - Helpers

static void FindRoutes(CLLocationCoordinate2D fromLocation,
                       CLLocationCoordinate2D toLocation,
                       FindRoutesSuccessBlock successBlock,
                       FindRoutesFailureBlock failureBlock)
{
  NSArray<MBWaypoint *> *const waypoints =
  @[
    [[MBWaypoint alloc] initWithCoordinate:fromLocation coordinateAccuracy:-1 name:@"Start"],
    [[MBWaypoint alloc] initWithCoordinate:toLocation coordinateAccuracy:-1 name:@"Destination"],
    ];
  MBRouteOptions *const options = [[MBRouteOptions alloc]
                                   initWithWaypoints:waypoints
                                   profileIdentifier:MBDirectionsProfileIdentifierAutomobileAvoidingTraffic];
  options.includesAlternativeRoutes = YES;
  options.includesSteps = YES;

  [[MBDirections sharedDirections]
   calculateDirectionsWithOptions:options
   completionHandler:^(NSArray<MBWaypoint *> * _Nullable waypoints,
                       NSArray<MBRoute *> * _Nullable routes,
                       NSError * _Nullable error) {
     if (error) {
       if (failureBlock) {
         failureBlock(error);
       }
     } else {
       if (successBlock) {
         successBlock(routes);
       }
     }
   }];
}

static MGLShapeSource *SourceForRoute(MBRoute *route, BOOL selected)
{
  // Get coordinates
  CLLocationCoordinate2D *routeCoordinates = malloc(route.coordinateCount * sizeof(CLLocationCoordinate2D));
  [route getCoordinates:routeCoordinates];

  // Create line
  MGLPolylineFeature *const line = [MGLPolylineFeature polylineWithCoordinates:routeCoordinates
                                                                         count:route.coordinateCount];
  line.identifier = route.legs.firstObject.name;
  line.attributes = @{
                      kAttributeKeyIsRoute: @(YES),
                      kAttributeKeyIsSelectedRoute: @(selected)
                      };
  free(routeCoordinates);

  // Create source
  return [[MGLShapeSource alloc] initWithIdentifier:route.legs.firstObject.name
                                           features:@[line]
                                            options:nil];
}

static MGLLineStyleLayer *LineStyleLayerForSource(MGLShapeSource *source,
                                                  NSString *identifier,
                                                  BOOL selected)
{
  MGLLineStyleLayer *const layer = [[MGLLineStyleLayer alloc] initWithIdentifier:identifier
                                                                          source:source];
  layer.lineWidth = [MGLStyleValue valueWithRawValue:@4];
  layer.lineColor = (selected ?
                     [MGLStyleValue valueWithRawValue:[UIColor blueColor]] :
                     [MGLStyleValue valueWithRawValue:[UIColor grayColor]]);
  return layer;
}

@end

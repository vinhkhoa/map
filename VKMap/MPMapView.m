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
static const int kMapButtonVerticalMargin = 10;
static const int kSettingsButtonMarginTop = 90;
static const int kMapButtonMarginRight = 20;

static NSString *const kAttributeKeyIsRoute = @"is_route";
static NSString *const kAttributeKeyIsSelectedRoute = @"is_selected_route";

static const int kMapStylesViewHeight = 110;

static const int kRouteViewCollapsedHeight = 130;
static const int kRouteViewHighestTopMargin = 160;
static const CGFloat kSwipeVelocityThredshold = 500;
static CGFloat const kExceedingThredsholdRatio = 3;
static const NSTimeInterval kDurationToShow = 0.5;
static const NSTimeInterval kDurationToHide = 0.4;

typedef void (^FindRoutesSuccessBlock)(NSArray<MBRoute *> *routes);
typedef void (^FindRoutesFailureBlock)(NSError *error);

typedef NS_ENUM (NSInteger, PolylineTapResult) {
  PolylineTapResultNotARoute,
  PolylineTapResultSelectedRoute,
  PolylineTapResultAlternativeRoute
};

@interface MPMapView() <MGLMapViewDelegate, MPMapButtonDelegate, MPMapStylesViewDelegate, UIGestureRecognizerDelegate>
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
  __weak id<MPMapViewDelegate> _delegate;
  NSString *_selectedRouteIdentifier;
  NSArray<MBRoute *> *_routes;
  MPMapButton *_userLocationButton, *_settingsButton;
  MPRouteView *_routeView;
  UIPanGestureRecognizer *_routeViewPanGR;
  CGFloat _routeViewLastTranslatedY;
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

    const CGFloat mapButtonX = CGRectGetWidth(self.bounds) - kMapButtonMarginRight - kMapButtonSize;

    // Settings button
    _settingsButton = [[MPMapButton alloc]
                       initWithFrame:CGRectMake(mapButtonX,
                                                kSettingsButtonMarginTop,
                                                kMapButtonSize,
                                                kMapButtonSize)
                       imageName:@"settings"
                       delegate:self];
    _settingsButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:_settingsButton];

    // User location button
    _userLocationButton = [[MPMapButton alloc]
                           initWithFrame:CGRectMake(mapButtonX,
                                                    kSettingsButtonMarginTop + kMapButtonSize + kMapButtonVerticalMargin,
                                                    kMapButtonSize,
                                                    kMapButtonSize)
                           imageName:@"crosshair"
                           delegate:self];
    _userLocationButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:_userLocationButton];

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
                                           CGRectGetHeight(self.bounds),
                                           CGRectGetWidth(self.bounds),
                                           CGRectGetHeight(self.bounds) - kRouteViewHighestTopMargin + MPRouteViewTableBottomInset)];
    _routeView.hidden = YES;
    _routeView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    _routeViewPanGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panRouteView:)];
    _routeViewPanGR.delegate = self;
    [_routeView addGestureRecognizer:_routeViewPanGR];
    [self addSubview:_routeView];
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

    // Check if user exactly tapped on a route
    for (id<MGLFeature> feature in [_mapView visibleFeaturesAtPoint:point]) {
      if ([feature isKindOfClass:[MGLPolylineFeature class]]) {
        const BOOL didTapOnRoute = [self _handleTapOnPolylineFeatureIfThisIsARoute:(MGLPolylineFeature *)feature];
        if (didTapOnRoute) {
          return;
        }
      }
    }

    // Check if user roughly tapped on a route
    const CGRect pointRect = {point, CGSizeZero};
    const CGRect touchRect = CGRectInset(pointRect, -10.0, -10.0);
    for (id<MGLFeature> feature in [_mapView visibleFeaturesInRect:touchRect]) {
      if ([feature isKindOfClass:[MGLPolylineFeature class]]) {
        const BOOL didTapOnRoute = [self _handleTapOnPolylineFeatureIfThisIsARoute:(MGLPolylineFeature *)feature];
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
  /*
    It would be nice if we can just "switch" route instead of removing and adding them again
    as this causes the routes to "flash"
   */
  [self _removeRoutesOnMap];
  _selectedRouteIdentifier = feature.identifier;
  [self _displayCurrentRoutes];
}

#pragma mark - Route view Translation

- (void)_panRouteView:(UIPanGestureRecognizer *)recognizer
{
  if (recognizer.state == UIGestureRecognizerStateEnded ||
      recognizer.state == UIGestureRecognizerStateCancelled ||
      recognizer.state == UIGestureRecognizerStateFailed) {
    if ([self _shouldBounceRouteViewDownForPanGestureRecognizer:recognizer]) {
      [self _translateRouteViewToCollapsedState];
    } else {
      [self _translateRouteViewToExpandedState];
    }
  } else {
    const CGFloat thisTranslatedY = [recognizer translationInView:recognizer.view.superview].y;
    const CGFloat combinedTranslatedY = thisTranslatedY + _routeViewLastTranslatedY;
    const CGFloat finalTranslatedY = [self _finalTranslatedYFromCombinedTranslatedY:combinedTranslatedY];
    [self _translateRouteViewToY:finalTranslatedY animated:NO duration:0 completion:nil];
  }
}

- (BOOL)_shouldBounceRouteViewDownForPanGestureRecognizer:(UIPanGestureRecognizer *)recognizer
{
  const CGFloat thisTranslatedY = [recognizer translationInView:recognizer.view.superview].y;
  const CGFloat combinedTranslatedY = thisTranslatedY + _routeViewLastTranslatedY;

  // Calculate whether user is swiping based on velocity
  const CGFloat translatedYDecidingPoint = -(CGRectGetHeight(self.bounds) - kRouteViewHighestTopMargin) / 2;
  const CGPoint velocity = [recognizer velocityInView:recognizer.view];
  const BOOL swipeUp = velocity.y < -kSwipeVelocityThredshold;
  const BOOL swipeDown = velocity.y > kSwipeVelocityThredshold;
  const BOOL noSwipe = !swipeDown && !swipeUp;
  const BOOL bounceDown = noSwipe && combinedTranslatedY >= translatedYDecidingPoint;

  return (swipeDown || bounceDown);
}

- (CGFloat)_finalTranslatedYFromCombinedTranslatedY:(CGFloat)combinedTranslatedY
{
  const CGFloat highestTranslatedY = [self _routeViewTranslatedYAtExpandedState];
  if (combinedTranslatedY < highestTranslatedY) {
    // Add 'stickines' when user drags past the upper limit
    return (highestTranslatedY - (highestTranslatedY - combinedTranslatedY) / kExceedingThredsholdRatio);
  } else if (combinedTranslatedY > 0) {
    // Do not allow user to drag down from its lowest point
    return 0;
  } else {
    return combinedTranslatedY;
  }
}

- (int)_routeViewTranslatedYAtExpandedState
{
  return -(CGRectGetHeight(self.bounds) - kRouteViewHighestTopMargin);
}

- (void)_translateRouteViewToY:(CGFloat)y animated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void(^)(void))completion
{
  if (animated) {
    [UIView
     animateWithDuration:duration
     delay:0
     usingSpringWithDamping:0.8
     initialSpringVelocity:0
     options:UIViewAnimationOptionCurveEaseOut
     animations:^{
      _routeView.transform = CGAffineTransformMakeTranslation(0, y);
    } completion:^(BOOL finished) {
      if (completion) completion();
    }];
  } else {
    _routeView.transform = CGAffineTransformMakeTranslation(0, y);
    if (completion) completion();
  }
}

- (void)_translateRouteViewToHiddenState
{
  _routeViewLastTranslatedY = 0;
  [self _translateRouteViewToY:_routeViewLastTranslatedY
                      animated:YES
                      duration:kDurationToHide
                    completion:^{
                      _routeView.hidden = YES;
                    }];
}

- (void)_translateRouteViewToCollapsedState
{
  _routeView.hidden = NO;
  _routeViewLastTranslatedY = -kRouteViewCollapsedHeight;
  [self _translateRouteViewToY:_routeViewLastTranslatedY
                      animated:YES
                      duration:kDurationToShow
                    completion:^{
                      _routeView.scrollEnabled = NO;
                    }];
}

- (void)_translateRouteViewToExpandedState
{
  _routeViewLastTranslatedY = [self _routeViewTranslatedYAtExpandedState];
  [self _translateRouteViewToY:_routeViewLastTranslatedY
                      animated:YES
                      duration:kDurationToShow
                    completion:^{
                      _routeView.scrollEnabled = YES;
                    }];
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
    // Show map styles if hidden. Hide otherwise.
    if (_mapStylesView.hidden) {
      [self _showMapStylesViewAnimated:YES];

      // Hide route view if visible
      if (!_routeView.hidden) {
        [self _translateRouteViewToHiddenState];
      }
    } else {
      [self _hideMapStylesViewAnimated:YES];

      // Show route view if routes available
      if (_routes.count) {
        [self _translateRouteViewToCollapsedState];
      }
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

  MGLPointAnnotation *const destination = [[MGLPointAnnotation alloc] init];
  destination.coordinate = coordinate;
  destination.title = @"Destination";
  [_mapView addAnnotation:destination];
  [_annotations addObject:destination];

  // Kick start finding routes whenever user changes destination
  __weak typeof(self) weakSelf = self;
  FindRoutes(_mapView.userLocation.coordinate,
             coordinate,
             ^(NSArray<MBRoute *> *routes) {
               [weakSelf _handleFoundRoutes:routes];
             }, ^(NSError *error) {
               [weakSelf _failedToFindRoutesWithError:error];
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
  // Sort array so that selected route is the first on the list
  NSArray<MBRoute *> *const sortedRoutes = (_selectedRouteIdentifier ?
                                            SortedRoutesToPutSelectedRouteFirst(_routes, _selectedRouteIdentifier)
                                            : _routes);

  // Display selected route last so that it's highest on the map
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

    if (selected) {
      // Zoom in
      [self _zoomToRoute:route];

      // Display route view
      _routeView.route = route;
      [self _translateRouteViewToCollapsedState];

      // Hide map styles
      if (!_mapStylesView.hidden) {
        [self _hideMapStylesViewAnimated:YES];
      }
    }
  }
}

- (void)_zoomToRoute:(MBRoute *)route
{
  CLLocationCoordinate2D *const routeCoordinates = malloc(route.coordinateCount * sizeof(CLLocationCoordinate2D));
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

- (void)_failedToFindRoutesWithError:(NSError *)error
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
     animateWithDuration:kDurationToShow
     delay:0
     usingSpringWithDamping:0.8
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
     animateWithDuration:kDurationToHide
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
  return [[MGLShapeSource alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]
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

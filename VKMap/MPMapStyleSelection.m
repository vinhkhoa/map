/**
 * This file is generated using the remodel generation script.
 * The name of the input file is MPMapStyleSelection.value
 */

#if  ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MPMapStyleSelection.h"

@implementation MPMapStyleSelection

- (instancetype)initWithIdentifier:(MPMapStyleIdentifier)identifier name:(NSString *)name styleURL:(NSString *)styleURL imageName:(NSString *)imageName
{
  if ((self = [super init])) {
    _identifier = identifier;
    _name = [name copy];
    _styleURL = [styleURL copy];
    _imageName = [imageName copy];
  }

  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ - \n\t identifier: %zd; \n\t name: %@; \n\t styleURL: %@; \n\t imageName: %@; \n", [super description], _identifier, _name, _styleURL, _imageName];
}

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {ABS(_identifier), [_name hash], [_styleURL hash], [_imageName hash]};
  NSUInteger result = subhashes[0];
  for (int ii = 1; ii < 4; ++ii) {
    unsigned long long base = (((unsigned long long)result) << 32 | subhashes[ii]);
    base = (~base) + (base << 18);
    base ^= (base >> 31);
    base *=  21;
    base ^= (base >> 11);
    base += (base << 6);
    base ^= (base >> 22);
    result = base;
  }
  return result;
}

- (BOOL)isEqual:(MPMapStyleSelection *)object
{
  if (self == object) {
    return YES;
  } else if (self == nil || object == nil || ![object isKindOfClass:[self class]]) {
    return NO;
  }
  return
    _identifier == object->_identifier &&
    (_name == object->_name ? YES : [_name isEqual:object->_name]) &&
    (_styleURL == object->_styleURL ? YES : [_styleURL isEqual:object->_styleURL]) &&
    (_imageName == object->_imageName ? YES : [_imageName isEqual:object->_imageName]);
}

@end


/**
 * This file is generated using the remodel generation script.
 * The name of the input file is MPMapStyleSelection.value
 */

#import <Foundation/Foundation.h>
#import "MPMapStyleIdentifiers.h"

@interface MPMapStyleSelection : NSObject <NSCopying>

@property (nonatomic, readonly) MPMapStyleIdentifier identifier;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *styleURL;
@property (nonatomic, readonly, copy) NSString *imageName;

- (instancetype)initWithIdentifier:(MPMapStyleIdentifier)identifier name:(NSString *)name styleURL:(NSString *)styleURL imageName:(NSString *)imageName;

@end


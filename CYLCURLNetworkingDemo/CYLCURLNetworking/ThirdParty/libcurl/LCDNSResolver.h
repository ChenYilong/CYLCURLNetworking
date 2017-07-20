//
//  LCDNSResolver.h
//  ALFOS
//
//  Created by Elon Chan on 10/10/15.
//  Copyright © 2017 Elon Chan Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALNConstants.h"

@interface LCDNSResolver : NSObject

+ (LCDNSResolver *)resolverForHost:(NSString *)host;

+ (NSArray *)resolveIPsForHost:(NSString *)host;
+ (NSArray *)resolveIPsForHost:(NSString *)host withError:(NSError **)error;
+ (void)resolveIPsForHost:(NSString *)host inBackgroundWithBlock:(ALNArrayResultBlock)block;

+ (NSArray *)cachedIPsForHost:(NSString *)host;

- (NSArray *)resolveIPsForHost:(NSString *)host;
- (NSArray *)resolveIPsForHost:(NSString *)host withError:(NSError **)error;
- (void)resolveIPsForHost:(NSString *)host inBackgroundWithBlock:(ALNArrayResultBlock)block;

@end

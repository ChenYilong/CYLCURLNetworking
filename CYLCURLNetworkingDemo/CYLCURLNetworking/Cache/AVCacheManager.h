//
//  AVCacheManager.h
//  CYLCURLNetworking
//
//  Created by Elon Chan on 13-3-19.
//  Copyright (c) 2017年 Elon Chan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALNConstants.h"

@interface AVCacheManager : NSObject

+ (AVCacheManager *)sharedInstance;

// cache
- (void)getWithKey:(NSString *)key maxCacheAge:(NSTimeInterval)maxCacheAge block:(ALNIdResultBlock)block;
- (void)saveJSON:(id)JSON forKey:(NSString *)key;

- (BOOL)hasCacheForKey:(NSString *)key;
- (BOOL)hasCacheForMD5Key:(NSString *)key;

// clear
+ (BOOL)clearAllCache;
+ (BOOL)clearCacheMoreThanOneDay;
+ (BOOL)clearCacheMoreThanDays:(NSInteger)numberOfDays;
- (void)clearCacheForKey:(NSString *)key;
- (void)clearCacheForMD5Key:(NSString *)key;

@end

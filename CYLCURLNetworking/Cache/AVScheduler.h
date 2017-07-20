//
//  AVScheduler.h
//  paas
//
//  Created by Elon Chan on 13-8-22.
//  Copyright (c) 2017年 Elon Chan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVScheduler : NSObject

@property (nonatomic, assign) NSInteger queryCacheExpiredDays;
@property (nonatomic, assign) NSInteger fileCacheExpiredDays;

+ (AVScheduler *)sharedInstance;

@end

//
//  LCCurlScheduler.h
//  ALFNetworking
//
//  Created by Elon Chan on 9/16/15.
//  Copyright (c) 2017 Elon Chan Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCurlObject.h"

@class LCCurlOperation;

@interface LCCurlScheduler : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;

- (void)enqueueOperation:(LCCurlOperation *)operation;
- (void)enqueueOperation:(LCCurlOperation *)operation waitUntilFinished:(BOOL)wait;

- (void)cancelAllOperationsForURL:(NSString *)URL method:(LCCurlHTTPMethod)method;

@end

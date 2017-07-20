//
//  LCCurlScheduler.m
//  
//
//  Created by Elon Chan on 9/16/15.
//  Copyright (c) 2017 Elon Chan Inc. All rights reserved.
//

#import "LCCurlScheduler.h"
#import "LCCurlOperation.h"
#import "ALNLogger.h"

#define LC_REST_REQUEST_LOG_FORMAT \
    @"\n\n" \
    @"------ BEGIN REST Request ----------------\n" \
    @"path: %@\n" \
    @"curl: %@\n" \
    @"------ END -------------------------------\n" \
    @"\n"

#define LCCURL_MAX_CONCURRENT_OPERATION_COUNT 20

@interface LCCurlScheduler () {
    NSOperationQueue *_operationQueue;
}

- (NSOperationQueue *)operationQueue;

@end

@implementation LCCurlScheduler

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LCCurlScheduler *instance;

    dispatch_once(&onceToken, ^{
        instance = [[LCCurlScheduler alloc] init];
        instance.maxConcurrentOperationCount = LCCURL_MAX_CONCURRENT_OPERATION_COUNT;
    });

    return instance;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
    _maxConcurrentOperationCount = maxConcurrentOperationCount;
    [self operationQueue].maxConcurrentOperationCount = maxConcurrentOperationCount;
}

- (void)enqueueOperation:(LCCurlOperation *)operation {
    [self enqueueOperation:operation waitUntilFinished:NO];
}

- (void)enqueueOperation:(LCCurlOperation *)operation waitUntilFinished:(BOOL)wait {
    [self logCurlOperation:operation];

    if (wait) {
        [[self operationQueue] addOperations:@[operation] waitUntilFinished:wait];
    } else {
        [[self operationQueue] addOperation:operation];
    }
}

- (void)cancelAllOperationsForURL:(NSString *)URL method:(LCCurlHTTPMethod)method {
    NSArray *operations = [[self operationQueue] operations];

    for (LCCurlOperation *operation in operations) {
        LCCurlObject *curlObject = operation.curlObject;
        if ([curlObject.url isEqualToString:URL] && curlObject.method == method) {
            [operation cancel];
            break;
        }
    }
}

- (void)logCurlOperation:(LCCurlOperation *)operation {
    if ([ALNLogger levelEnabled:ALNLoggerLevelDebug] &&
        [ALNLogger containDomain:ALNLoggerDomainCURL]) {
        NSString *path = [[NSURL URLWithString:operation.curlObject.url] path];
        ALNLoggerDebug(ALNLoggerDomainCURL, LC_REST_REQUEST_LOG_FORMAT, path, [operation.curlObject cURLCommand]);
    }
}

- (NSOperationQueue *)operationQueue {
    @synchronized (self) {
        if (!_operationQueue) {
            _operationQueue = [[NSOperationQueue alloc] init];
        }
    }

    return _operationQueue;
}

@end

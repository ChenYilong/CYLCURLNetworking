//
//  LCDNSResolver.m
//  ALNNetworking
//
//  Created by Elon Chan on 10/10/15.
//  Copyright © 2017 Elon Chan Inc. All rights reserved.
//

#import "LCDNSResolver.h"
#import "lchttp.h"
#import "LCCurlOperation.h"

#define LCDNS_MAX_CACHE_AGE (1 * 60 * 60) /* An hour */

static NSMutableDictionary *LCDNSResolverTable = nil;

@interface LCDNSResolver ()

@property (nonatomic, copy)   NSString         *host;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) id                cachedResult;
@property (nonatomic, assign) NSTimeInterval    cachedAt;

- (NSArray *)cachedIPArray;

@end

@implementation LCDNSResolver

+ (void)initialize {
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        LCDNSResolverTable = [NSMutableDictionary dictionary];
    });
}

+ (LCDNSResolver *)resolverForHost:(NSString *)host {
    if (!host) return nil;

    LCDNSResolver *resolver = nil;

    @synchronized (LCDNSResolverTable) {
        resolver = LCDNSResolverTable[host];

        if (!resolver) {
            resolver = [[LCDNSResolver alloc] initWithHost:host];
            LCDNSResolverTable[host] = resolver;
        }
    }

    return resolver;
}

+ (NSArray *)resolveIPsForHost:(NSString *)host {
    return [self resolveIPsForHost:host withError:NULL];
}

+ (NSArray *)resolveIPsForHost:(NSString *)host withError:(NSError **)error {
    return [[self resolverForHost:host] resolveIPsForHost:host withError:error];
}

+ (void)resolveIPsForHost:(NSString *)host inBackgroundWithBlock:(ALNArrayResultBlock)block {
    [[self resolverForHost:host] resolveIPsForHost:host inBackgroundWithBlock:block];
}

+ (NSArray *)cachedIPsForHost:(NSString *)host {
    LCDNSResolver *resolver = [self resolverForHost:host];

    if (resolver) {
        return [resolver cachedIPArray];
    } else {
        return @[];
    }
}

- (void)doInitialize {
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
}

- (instancetype)initWithHost:(NSString *)host {
    self = [super init];

    if (self) {
        _host = [host copy];
        [self doInitialize];
    }

    return self;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        [self doInitialize];
    }

    return self;
}

- (NSString *)URLStringForHost:(NSString *)host {
    return [NSString stringWithFormat:@"https://203.107.1.1/191863/d?host=%@", host];
}

- (CURL *)createCURLWithHost:(NSString *)host {
    CURL *curl = curl_easy_init();
    NSString *url = [self URLStringForHost:host];

    curl_easy_setopt(curl, CURLOPT_URL, url.UTF8String);

    return curl;
}

- (NSArray *)IPsFromString:(NSString *)string {
    if ([string length]) {
        return [string componentsSeparatedByString:@","];
    } else {
        return @[];
    }
}

- (BOOL)cacheAlive {
    if (self.cachedAt) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        return now > self.cachedAt && now < self.cachedAt + LCDNS_MAX_CACHE_AGE;
    }

    return NO;
}

- (NSString *)cachedIPString {
    if (_cachedResult && [self cacheAlive]) {
        return _cachedResult;
    } else {
        _cachedResult = nil;
        return nil;
    }
}

- (void)cacheResult:(NSString *)result {
    self.cachedResult = result;
    self.cachedAt = [[NSDate date] timeIntervalSince1970];
}

- (NSError *)errorWithCode:(CURLcode)code httpError:(lchttp_error_t *)error {
    NSDictionary *userInfo = nil;

    if (error && error->message) {
        NSString *message = [NSString stringWithCString:error->message encoding:NSUTF8StringEncoding];
        userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    }

    return [NSError errorWithDomain:CYLCURLNetworkingErrorDomain code:code userInfo:userInfo];
}

- (NSArray *)resolveIPsForHost:(NSString *)host {
    return [self resolveIPsForHost:host withError:NULL];
}

- (NSArray *)resolveIPsForHost:(NSString *)host withError:(NSError **)error {
    if (!host)
        return @[];

    __block NSString *IPString = nil;
    __block NSError *error_ = nil;
    __weak typeof(self) weakSelf = self;

    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        IPString = [weakSelf cachedIPString];

        if (IPString) return;

        CURL *curl = [self createCURLWithHost:host];
        lchttp_response_t *res = lchttp_response_init();
        lchttp_error_t *err = error ? lchttp_error_init() : NULL;

        CURLcode code = lchttp_perform(curl, res, err);

        if (code == CURLE_OK) {
            if (res->text != NULL) {
                IPString = [NSString stringWithCString:res->text encoding:NSUTF8StringEncoding];
                [weakSelf cacheResult:IPString];
            }
        } else if (error) {
            error_ = [self errorWithCode:code httpError:err];
        }

        lchttp_response_destroy(res);
        lchttp_error_destroy(err);
        curl_easy_cleanup(curl);
    }];

    [self.operationQueue addOperations:@[operation] waitUntilFinished:YES];

    if (error) {
        *error = error_;
    }

    return [self IPsFromString:IPString];
}

- (void)resolveIPsForHost:(NSString *)host inBackgroundWithBlock:(ALNArrayResultBlock)block {
    if (block) {
        [self.operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            NSError *error = nil;
            NSArray *IPs = [self resolveIPsForHost:host withError:&error];

            block(IPs, error);
        }]];
    }
}

- (NSArray *)cachedIPArray {
    return [self IPsFromString:[self cachedIPString]];
}

@end

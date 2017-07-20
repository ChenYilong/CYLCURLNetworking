//
//  LCCurlOperation.m
//  ALFNetworking
//
//  Created by Elon Chan on 9/16/15.
//  Copyright (c) 2017 Elon Chan Inc. All rights reserved.
//

#import "LCCurlOperation.h"
#import "LCDNSResolver.h"
//#import "ALFNetworkingCloud_Internal.h"
#import "lchttp.h"
#import "ALNConstants.h"
#import <AlicloudHttpDNS/AlicloudHttpDNS.h>

NSString * const CYLCURLNetworkingErrorDomain = @"CYLCURLNetworkingErrorDomain";

@interface NSURL (LCCurlOperation)

- (BOOL)lc_isLCHTTPSRESTAPI;

@end

@implementation NSURL (LCCurlOperation)

- (NSString *)lc_rootDomain {
    NSString *domain = [self host];
    NSArray *components = [domain componentsSeparatedByString:@"."];
    
    if ([components count] > 2) {
        NSArray *lastTwoComponents = [components subarrayWithRange:NSMakeRange(components.count - 2, 2)];
        domain = [lastTwoComponents componentsJoinedByString:@"."];
    }

    return domain;
}

- (BOOL)lc_isLCHTTPSRESTAPI {
    //TODO:change to ali
//    return [self.scheme.lowercaseString isEqualToString:@"https"] && [[self lc_rootDomain].lowercaseString isEqualToString:LCRootDomain];
    return YES;
}

@end

typedef NS_ENUM(NSInteger, LCCurlOperationState) {
    LCCurlOperationStatePaused    = -1,
    LCCurlOperationStateReady     = 1,
    LCCurlOperationStateExecuting = 2,
    LCCurlOperationStateFinished  = 3,
};

NS_INLINE
BOOL LCCurlStateTransitionIsValid(LCCurlOperationState fromState, LCCurlOperationState toState, BOOL isCancelled) {
    switch (fromState) {
    case LCCurlOperationStateReady:
        switch (toState) {
        case LCCurlOperationStatePaused:
        case LCCurlOperationStateExecuting:
            return YES;
        case LCCurlOperationStateFinished:
            return isCancelled;
        default:
            return NO;
        }
    case LCCurlOperationStateExecuting:
        switch (toState) {
        case LCCurlOperationStatePaused:
        case LCCurlOperationStateFinished:
            return YES;
        default:
            return NO;
        }
    case LCCurlOperationStateFinished:
        return NO;
    case LCCurlOperationStatePaused:
        return toState == LCCurlOperationStateReady;
    default:
        return YES;
    }
}

NS_INLINE
NSString *LCCurlKeyPathFromOperationState(LCCurlOperationState state) {
    switch (state) {
    case LCCurlOperationStateReady:
        return @"isReady";
    case LCCurlOperationStateExecuting:
        return @"isExecuting";
    case LCCurlOperationStateFinished:
        return @"isFinished";
    case LCCurlOperationStatePaused:
        return @"isPaused";
    default:
        return @"state";
    }
}

typedef signed short AVOperationState;

@interface LCCurlOperation ()

@property (nonatomic, strong) LCCurlObject *curlObject;
@property (nonatomic, assign) LCCurlOperationState state;
@property (nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (nonatomic, strong) NSRecursiveLock *lock;

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy) NSString *responseText;
@property (nonatomic, strong) NSDictionary *responseObject;
@property (nonatomic, strong) NSError *responseJsonError;

@property (nonatomic, assign) BOOL hostResolved;

@end

@implementation LCCurlOperation

@synthesize cancelled = _cancelled;

- (instancetype)initWithCurlObject:(LCCurlObject *)curlObject {
    self = [super init];

    if (self) {
        _curlObject = curlObject;
        _lock = [[NSRecursiveLock alloc] init];
        self.state = LCCurlOperationStateReady;
    }

    return self;
}

- (void)setState:(LCCurlOperationState)state {
    [self.lock lock];
    if (LCCurlStateTransitionIsValid(self.state, state, [self isCancelled])) {
        NSString *oldStateKey = LCCurlKeyPathFromOperationState(self.state);
        NSString *newStateKey = LCCurlKeyPathFromOperationState(state);

        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
    }
    [self.lock unlock];
}

#pragma mark - NSOperation

- (void)start {
    [self.lock lock];
    if ([self isReady]) {
        self.state = LCCurlOperationStateExecuting;
        [self operationDidStart];
    }
    [self.lock unlock];
}

- (void)pinSSLIfNeeded {
    if ([[self URL] lc_isLCHTTPSRESTAPI]) {
        //TODO:change to 
//        curl_easy_setopt(self.curlObject.curl, CURLOPT_PINNEDPUBLICKEY, [LCRootCertificate UTF8String]);
    }
}

- (void)operationDidStart {
    [self.lock lock];
    if ([self isCancelled]) {
        [self finish];
    } else {
        [self pinSSLIfNeeded];
        [self performRequest];
    }
    [self.lock unlock];
}

- (void)performRequest {
    lchttp_error_t *error = lchttp_error_init();
    lchttp_response_t *response = lchttp_response_init();

    CURLcode code = lchttp_perform(self.curlObject.curl, response, error);

    if (code == CURLE_OK) {
        [self handleResponse:response];
        [self finish];
    } else if (code == CURLE_COULDNT_RESOLVE_HOST && !self.hostResolved && [self resolveHost]) {
        [self performRequest];
    } else {
        [self handleError:error];
        [self finish];
    }

    lchttp_response_destroy(response);
    lchttp_error_destroy(error);
}

- (NSURL *)URL {
    return [NSURL URLWithString:self.curlObject.url];
}

- (BOOL)resolveHost {
    self.hostResolved = YES;

    NSString *host = [self URL].host;
    
    NSArray  *IPs = [[HttpDnsService sharedInstance] getIpsByHostAsync:host];
//    NSArray  *IPs  = [LCDNSResolver resolveIPsForHost:host];

    if ([IPs count]) {
        self.curlObject.IPs = IPs;
//        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), self.curlObject.IPs);
        return YES;
    }

    return NO;
}

- (NSString *)headerFieldNameFromString:(NSString *)string {
    NSRange range = [string rangeOfString:@":"];

    if (range.location != NSNotFound) {
        return [[string substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    return nil;
}

- (NSString *)headerFieldValueFromString:(NSString *)string {
    NSRange range = [string rangeOfString:@":"];

    if (range.location != NSNotFound) {
        return [[string substringFromIndex:range.location + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    return nil;
}

- (NSDictionary *)dictionaryFromHeaderString:(NSString *)headerString {
    if (!headerString) return nil;

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray *headerLines = [headerString componentsSeparatedByString:@"\r\n"];

    for (NSString *eachHeaderLine in headerLines) {
        NSString *key = [self headerFieldNameFromString:eachHeaderLine];
        NSString *value = [self headerFieldValueFromString:eachHeaderLine];

        if (key && value) {
            dictionary[key] = value;
        }
    }

    return dictionary;
}

- (void)handleResponse:(lchttp_response_t *)response {
    self.statusCode = (NSInteger)response->code;

    if (response->header) {
        NSString *headerString = [NSString stringWithCString:response->header encoding:NSUTF8StringEncoding];
        self.header = [self dictionaryFromHeaderString:headerString];
    }

    if (response->text && strlen(response->text) > 0) {
        self.responseText = [NSString stringWithCString:response->text encoding:NSUTF8StringEncoding];
    }

    NSError *statusError = [self statusError];

    if (statusError) {
        if (self.failureBlock) {
            self.failureBlock(self, statusError);
        }
    } else {
        if (self.successBlock) {
            self.successBlock(self);
        }
    }
}

- (void)handleError:(lchttp_error_t *)lchttp_error {
    CURLcode code = lchttp_error->code;
    char *message = lchttp_error->message;

    NSDictionary *userInfo = nil;

    if (message) {
        NSString *detail = [NSString stringWithCString:message encoding:NSUTF8StringEncoding];
        userInfo = [NSDictionary dictionaryWithObject:detail forKey:NSLocalizedDescriptionKey];
    }

    NSError *error = [NSError errorWithDomain:CYLCURLNetworkingErrorDomain code:code userInfo:userInfo];

    if (self.failureBlock) {
        self.failureBlock(self, error);
    }
}

- (id)JSONObjectWithError:(NSError *__autoreleasing *)error {
    id responseObject = nil;

    if (self.responseText) {
        NSData *JSONData = [self.responseText dataUsingEncoding:NSUTF8StringEncoding];
        responseObject = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:error];
    }

    return responseObject;
}

- (BOOL)hasValidStatusCode {
    return self.statusCode >= 200 && self.statusCode <= 203;
}

- (NSString *)validStatusCodeRangeString {
    return @"200 ~ 203";
}

- (NSError *)statusError {
    NSError *error = nil;

    if (![self hasValidStatusCode]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

        [userInfo setValue:self.responseText forKey:NSLocalizedRecoverySuggestionErrorKey];
        [userInfo setValue:self.curlObject.url forKey:NSURLErrorFailingURLErrorKey];
        [userInfo setValue:[NSString stringWithFormat:@"Expected status code in (%@), got %d", [self validStatusCodeRangeString], (int)self.statusCode] forKey:NSLocalizedDescriptionKey];

        error = [[NSError alloc] initWithDomain:CYLCURLNetworkingErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
    }

    return error;
}

- (void)cancel {
    if (![self isFinished] && ![self isCancelled]) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = YES;
        [super cancel];
        [self didChangeValueForKey:@"isCancelled"];

        [self operationDidCancel];
    }
}

- (void)operationDidCancel {
    NSDictionary *userInfo = nil;

    if (self.curlObject.url) {
        userInfo = [NSDictionary dictionaryWithObject:self.curlObject.url forKey:NSURLErrorFailingURLErrorKey];
    }

    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];

    if (self.failureBlock) {
        self.failureBlock(self, error);
    }
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isReady {
    return self.state == LCCurlOperationStateReady && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == LCCurlOperationStateExecuting;
}

- (BOOL)isFinished {
    return self.state == LCCurlOperationStateFinished;
}

- (void)finish {
    self.state = LCCurlOperationStateFinished;
}

@end

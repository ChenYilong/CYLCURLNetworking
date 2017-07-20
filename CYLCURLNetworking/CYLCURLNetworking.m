//
//  CYLCURLNetworking.m
//  CYLCURLNetworking
//
//  Created by Elon Chan on 2017/3/21.
//  Copyright © 2017年 Elon Chan. All rights reserved.
//

#import "CYLCURLNetworking.h"
#import "LCDNSResolver.h"
#import "AVNetworking.h"
#import "ALNLogger.h"
#import "NSString+ALNExtension.h"
#import "AVCacheManager.h"
#import "LCCurlScheduler.h"
#import "AVErrorUtils.h"

@interface CYLCURLNetworking()

@property (nonatomic, readwrite, strong) AVHTTPClient *clientImpl;
@property (nonatomic, readwrite, strong) NSMutableDictionary *subclassTable;
@property (atomic, strong) NSMutableDictionary *lastModify;

@end

#define ALN_REST_RESPONSE_LOG_FORMAT                 \
    @"\n\n"                                          \
    @"------ BEGIN CYLCURLNetworking REST Response ------\n" \
    @"path: %@\n"                                    \
    @"cost: %.3fs\n"                                 \
    @"response: %@\n"                                \
    @"------ END --------------------------------\n" \
    @"\n"

@implementation CYLCURLNetworking

+ (void)initialize {
    HttpDnsService *httpdns = [HttpDnsService sharedInstance];
    [httpdns setLogEnabled:YES];
    [httpdns setAccountID:139450];
}

+(CYLCURLNetworking *)sharedInstance {
    static dispatch_once_t once;
    static CYLCURLNetworking * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
//        sharedInstance.apiVersion = API_VERSION;
//        sharedInstance.productionMode = YES;
        sharedInstance.timeoutInterval = kALNDefaultNetworkTimeoutInterval;
        
//        sharedInstance.applicationIdField = LCHeaderFieldNameId;
//        sharedInstance.applicationKeyField = LCHeaderFieldNameKey;
//        sharedInstance.sessionTokenField = LCHeaderFieldNameSession;
        
//        sharedInstance.runningArchivedRequests=[[NSMutableSet alloc] init];
        
//        [AVScheduler sharedInstance];
    });
    return sharedInstance;
}

- (NSURL *)RESTBaseURL {
    return [NSURL URLWithString:@"https://maps.google.com"];
    
//    if (self.baseURL && self.apiVersion) {
//        return [[NSURL URLWithString:self.baseURL] URLByAppendingPathComponent:self.apiVersion];
//    } else {
//        return [AliCloud RESTBaseURL];
//    }
    return nil;
}

- (AVHTTPClient *)clientImpl {
    if (!_clientImpl) {
        NSURL *url = [self RESTBaseURL];
        _clientImpl = [AVHTTPClient clientWithBaseURL:url];
        
        //最大并发请求数 4
        _clientImpl.operationQueue.maxConcurrentOperationCount=4;
        
        [_clientImpl registerHTTPOperationClass:[AVJSONRequestOperation class]];
        [_clientImpl setParameterEncoding:AVJSONParameterEncoding];
   
        //TODO:handleAllArchivedCurlObject
//#if !TARGET_OS_WATCH
//        //revert the offline request
//        __weak id wealSelf=self;
//        [_clientImpl setReachabilityStatusChangeBlock:^(ALNNetworkReachabilityStatus status) {
//            ALNLoggerI(@"network status change :%d",status);
//            
//            if (status > AVNetworkReachabilityStatusNotReachable) {
//                [wealSelf handleAllArchivedCurlObject];
//            }
//        }];
//#endif
    }
    
    return _clientImpl;
}


#pragma mark -
#pragma mark - core http method Method

- (void)getObject:(NSString *)path
   withParameters:(NSDictionary *)parameters
            block:(ALNIdResultBlock)block {
    [self getObjectFromNetworkWithPath:path withParameters:parameters policy:kALNCachePolicyIgnoreCache block:block];
}

- (void)getObjectFromNetworkWithPath:(NSString *)path
                     withParameters:(NSDictionary *)parameters
                             policy:(ALNCachePolicy)policy
                              block:(ALNIdResultBlock)block {
    NSString *url = [self absoluteStringFromPath:path parameters:parameters];
    LCCurlObject *curl = [self curlObjectWithURL:url method:LCCurlHTTPMethodGet];
    
    [self performCurl:curl saveResult:(policy != kALNCachePolicyIgnoreCache) block:block];
}

- (void)getObject:(NSString *)path withParameters:(NSDictionary *)parameters policy:(ALNCachePolicy)policy maxCacheAge:(NSTimeInterval)maxCacheAge block:(ALNIdResultBlock)block {
    
    NSString *key = [self absoluteStringFromPath:path parameters:parameters];
    
    switch (policy) {
        case kALNCachePolicyIgnoreCache:
        {
            [self getObjectFromNetworkWithPath:path withParameters:parameters policy:policy block:block];
        }
            break;
        case kALNCachePolicyCacheOnly:
        {
            [[AVCacheManager sharedInstance] getWithKey:key maxCacheAge:maxCacheAge block:block];
        }
            break;
        case kALNCachePolicyNetworkOnly:
        {
            [self getObjectFromNetworkWithPath:path withParameters:parameters policy:policy block:^(id object, NSError *error) {
                block(object, error);
            }];
        }
            break;
        case kALNCachePolicyCacheElseNetwork:
        {
            [[AVCacheManager sharedInstance] getWithKey:key maxCacheAge:maxCacheAge block:^(id object, NSError *error) {
                if (error) {
                    [self getObjectFromNetworkWithPath:path withParameters:parameters policy:policy block:block];
                } else {
                    block(object, error);
                }
            }];
        }
            break;
        case kALNCachePolicyNetworkElseCache:
        {
            [self getObjectFromNetworkWithPath:path withParameters:parameters policy:policy block:^(id object, NSError *error) {
                if (error) {
                    [[AVCacheManager sharedInstance] getWithKey:key maxCacheAge:maxCacheAge block:block];
                } else {
                    block(object, error);
                }
            }];
        }
            break;
        case kALNCachePolicyCacheThenNetwork:
        {
            [[AVCacheManager sharedInstance] getWithKey:key maxCacheAge:maxCacheAge block:^(id object, NSError *error) {
                block(object, error);
                [self getObjectFromNetworkWithPath:path withParameters:parameters policy:policy block:block];
            }];
        }
            break;
        default:
        {
            abort();
        }
            break;
    }
}

- (void)putObject:(NSString *)path
  withParameters:(NSDictionary *)parameters
    sessionToken:(NSString *)sessionToken
           block:(ALNIdResultBlock)block {
    NSString *url = [self absoluteStringFromPath:path parameters:nil];
    LCCurlObject *curl = [self curlObjectWithURL:url method:LCCurlHTTPMethodPut];
    
    if (parameters) {
        NSString *payload = [self JSONStringFromDictionary:parameters];
        curl.payload = payload;
    }
    
    [self performCurl:curl saveResult:NO block:block];
}

- (void)postObject:(NSString *)path
   withParameters:(NSDictionary *)parameters
            block:(ALNIdResultBlock)block {
    
    NSString *url = [self absoluteStringFromPath:path parameters:nil];
    LCCurlObject *curl = [self curlObjectWithURL:url method:LCCurlHTTPMethodPost];
    
    curl.payload = [self JSONStringFromDictionary:parameters];
    
    
    [self performCurl:curl saveResult:NO block:block];
    
}

- (void)deleteObject:(NSString *)path
     withParameters:(NSDictionary *)parameters
              block:(ALNIdResultBlock)block {
    NSString *url = [self absoluteStringFromPath:path parameters:parameters];
    LCCurlObject *curl = [self curlObjectWithURL:url method:LCCurlHTTPMethodDelete];
    [self performCurl:curl saveResult:NO block:block];
}

- (void)cancelQueryWithPath:(NSString *)path parameters:(NSDictionary *)parameters {
    NSString *absolutePath = [self absoluteStringFromPath:path parameters:parameters];
    [[LCCurlScheduler sharedInstance] cancelAllOperationsForURL:absolutePath method:LCCurlHTTPMethodGet];
}

#pragma mark - The final method for network

- (void)performCurl:(LCCurlObject *)curl saveResult:(BOOL)saveResult block:(ALNIdResultBlock)block {
    [self performCurl:curl saveResult:saveResult block:block retryTimes:0];
}

/**
 *  统一的网络请求方法
 *
 *  @dicusssion 批量操作中，有一个操作为 Error，block 都将带上 Error
 */
- (void)performCurl:(LCCurlObject *)curl saveResult:(BOOL)saveResult block:(ALNIdResultBlock)block retryTimes:(NSInteger)retryTimes {
    NSString *url = [curl url];
    NSString *path = [[NSURL URLWithString:url] path];
    
    if (self.isLastModifyEnabled && curl.method == LCCurlHTTPMethodGet) {
        NSString *lmd = self.lastModify[[url aln_MD5String]];
        if (lmd && [[AVCacheManager sharedInstance] hasCacheForKey:url]) {
            [curl setCustomHeaderValue:lmd forFieldName:@"If-Modified-Since"];
        }
    }
    
    __weak typeof(self) ws=self;
    NSDate *operationEnqueueDate = [NSDate date];
    
    [self performCurl:curl
              success:^(LCCurlOperation *operation)
     {
         NSInteger statusCode = operation.statusCode;
         NSTimeInterval costTime = -[operationEnqueueDate timeIntervalSinceNow];
         
         ALNLoggerDebug(ALNLoggerDomainNetwork, ALN_REST_RESPONSE_LOG_FORMAT, path, costTime, operation.responseText);
         
         id responseObject = [operation JSONObjectWithError:NULL];
         
         if (ws.isLastModifyEnabled && curl.method == LCCurlHTTPMethodGet) {
             NSDictionary *headers = operation.header;
             NSString *lmd = [headers objectForKey:@"Last-Modified"];
             if (lmd && ![ws.lastModify[[url aln_MD5String]] isEqualToString:lmd]) {
                 [[AVCacheManager sharedInstance] saveJSON:responseObject forKey:url];
                 [ws.lastModify setObject:lmd forKey:[url aln_MD5String]];
             }
         } else if (saveResult) {
             [[AVCacheManager sharedInstance] saveJSON:responseObject forKey:url];
         }
         
         if (block && ![operation isCancelled]) {
             // AVLogIn(@"\nOK (%1.3fs)\n%@", costTime, responseObject);
             
             block(responseObject, [AVErrorUtils errorFromJSON:responseObject]);
         }
         
         // Doing network statistics
         //TODO:delete
//         if ([self shouldStatisticsUrl:url]) {
//             LCNetworkStatistics *statistician = [LCNetworkStatistics sharedInstance];
//             
//             [statistician addIncrementalAttribute:1 forKey:@"total"];
//             [statistician addIncrementalAttribute:1 forKey:[NSString stringWithFormat:@"%ld", statusCode]];
//             
//             if ((NSInteger)(statusCode / 100) == 2) {
//                 [statistician addAverageAttribute:costTime forKey:@"avg"];
//             }
//         }
     }
              failure:^(LCCurlOperation *operation, NSError *error)
     {
         if ([operation isCancelled]) return;
         
         NSInteger statusCode = operation.statusCode;
         NSTimeInterval costTime = -[operationEnqueueDate timeIntervalSinceNow];
         
         ALNLoggerDebug(ALNLoggerDomainNetwork, ALN_REST_RESPONSE_LOG_FORMAT, path, costTime, error);
         
         // Doing network statistics
         //TODO:delete
//         if ([self shouldStatisticsUrl:url]) {
//             LCNetworkStatistics *statistician = [LCNetworkStatistics sharedInstance];
//             
//             [statistician addIncrementalAttribute:1 forKey:@"total"];
//             
//             if (error.code == CURLE_OPERATION_TIMEDOUT) {
//                 [statistician addIncrementalAttribute:1 forKey:@"timeout"];
//             } else {
//                 [statistician addIncrementalAttribute:1 forKey:[NSString stringWithFormat:@"%ld", statusCode]];
//                 
//                 if ((NSInteger)(statusCode / 100) == 2) {
//                     [statistician addAverageAttribute:costTime forKey:@"avg"];
//                 }
//             }
//         }
         
         if (statusCode == 304) {
             // 304 is not error
             [[AVCacheManager sharedInstance] getWithKey:curl.url maxCacheAge:3600*24*30 block:^(id object, NSError *error) {
                 if (error) {
                     if (retryTimes < 3) {
                         [ws.lastModify removeObjectForKey:[url aln_MD5String]];
                         [[AVCacheManager sharedInstance] clearCacheForKey:url];
                         [curl setCustomHeaderValue:@"" forFieldName:@"If-Modified-Since"];
                         [ws performCurl:curl saveResult:saveResult block:block retryTimes:retryTimes + 1];
                     } else {
                         block(object, error);
                     }
                 } else {
                     block(object, error);
                 }
             }];
         } else {
             NSError *JSONError = nil;
             id JSONObject = [operation JSONObjectWithError:&JSONError];
             
             if (JSONObject && !JSONError) {
                 NSError *businessError = [AVErrorUtils errorFromJSON:JSONObject];
                 if (businessError) {
                     error = businessError;
                 }
             }
             
             block(nil, error);
         }
     }];
}

- (void)performCurl:(LCCurlObject *)curl
            success:(void (^)(LCCurlOperation *operation))successBlock
            failure:(void (^)(LCCurlOperation *operation, NSError *error))failureBlock
               wait:(BOOL)wait {
    LCCurlOperation *operation = [[LCCurlOperation alloc] initWithCurlObject:curl];
    
    operation.successBlock = successBlock;
    operation.failureBlock = failureBlock;
    
    [[LCCurlScheduler sharedInstance] enqueueOperation:operation waitUntilFinished:wait];
}

- (void)performCurl:(LCCurlObject *)curl
            success:(void (^)(LCCurlOperation *))successBlock
            failure:(void (^)(LCCurlOperation *, NSError *))failureBlock {
    [self performCurl:curl success:successBlock failure:failureBlock wait:NO];
}

- (BOOL)shouldStatisticsUrl:(NSString *)url {
    NSArray *exclusiveApis = @[
                               @"appHosts",
                               @"stats/collect",
                               @"sendPolicy"
                               ];
    
    for (NSString *api in exclusiveApis) {
        if ([url hasSuffix:api]) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Network Utils

- (LCCurlObject *)curlWithPath:(NSString *)path
                    parameters:(NSDictionary *)parameters
                        method:(LCCurlHTTPMethod)method {
    NSString *url = nil;
    LCCurlObject *curl = nil;
    
    switch (method) {
        case LCCurlHTTPMethodGet:
        case LCCurlHTTPMethodDelete:
            url = [self absoluteStringFromPath:path parameters:parameters];
            curl = [self curlObjectWithURL:url method:method];
            break;
        case LCCurlHTTPMethodPut:
        case LCCurlHTTPMethodPost:
            url = [self absoluteStringFromPath:path parameters:nil];
            curl = [self curlObjectWithURL:url method:method];
            if (parameters) {
                curl.payload = [self JSONStringFromDictionary:parameters];
            }
            break;
    }
    
    return curl;
}

- (LCCurlObject *)curlObjectWithURL:(NSString *)URL method:(LCCurlHTTPMethod)method {
    LCCurlObject *curl = [[LCCurlObject alloc] init];
    
    curl.url = URL;
    curl.method = method;
    curl.appId = self.applicationId;
    //TODO:delete signature
//    curl.signature = [self signatureHeaderFieldValue];
//    curl.sessionToken = self.currentUser.sessionToken;
    curl.timeout = self.timeoutInterval * 1000;
//    curl.production = self.productionMode;
    
    /* Apply resolved IPs if resolver has cached result. */
    if (curl) {
        NSString *host = [NSURL URLWithString:curl.url].host;
            NSArray  *IPs = [[HttpDnsService sharedInstance] getIpsByHostAsync:host];

//        NSArray  *IPs  = [LCDNSResolver cachedIPsForHost:host];
        
        if (IPs) {
            curl.IPs = IPs;
            //NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), IPs);
        }
    }
    
    return curl;
}

#pragma mark - Util method for client

- (NSString *)JSONStringFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary) { return nil; }
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
    
}

- (NSString *)absoluteStringFromPath:(NSString *)path parameters:(NSDictionary *)parameters {
    return [[[self.clientImpl requestWithMethod:@"GET" path:path parameters:parameters] URL] absoluteString];
}

- (BOOL)addSubclassMapEntry:(NSString *)parseClassName
               classObject:(Class)object {
    if (self.subclassTable == nil) {
        _subclassTable = [[NSMutableDictionary alloc] init];
    }
    
    if (parseClassName == nil) { return NO; }
    
    if ([self.subclassTable objectForKey:parseClassName]) {
        ALNLoggerI(@"Warnning: Register duplicate with %@, %@ will be replaced by %@",
                  parseClassName, [self.subclassTable objectForKey:parseClassName], object);
    }
    
    [self.subclassTable setObject:object forKey:parseClassName];
    return YES;
}

- (Class)classFor:(NSString *)parseClassName {
    return [self.subclassTable objectForKey:parseClassName];
}

- (void)setIsLastModifyEnabled:(BOOL)isLastModifyEnabled{
    if (_isLastModifyEnabled==isLastModifyEnabled) {
        return;
    }
    _isLastModifyEnabled=isLastModifyEnabled;
    if (_isLastModifyEnabled) {
        //FIXME: 永久化
        self.lastModify=[[NSMutableDictionary alloc] init];
        
    } else {
        self.lastModify=nil;
    }
}

- (void)clearLastModifyCache{
    if (self.lastModify.count) {
        for (NSString *key in self.lastModify) {
            [[AVCacheManager sharedInstance] clearCacheForMD5Key:key];
        }
        
        [self.lastModify removeAllObjects];
    }
}


@end

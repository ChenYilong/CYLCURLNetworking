//
//  CYLCURLNetworking.h
//  CYLCURLNetworking
//
//  Created by Elon Chan on 2017/3/21.
//  Copyright © 2017年 Elon Chan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCurlObject.h"
#import "LCCurlOperation.h"
#import "ALNConstants.h"
#import <AlicloudHttpDNS/AlicloudHttpDNS.h>

@class AVHTTPClient;

@interface CYLCURLNetworking : NSObject

@property (nonatomic, readonly, strong) AVHTTPClient * clientImpl;

@property (nonatomic, readwrite, copy) NSString * applicationId;
@property (nonatomic, readwrite, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) BOOL isLastModifyEnabled;

- (void)getObject:(NSString *)path
   withParameters:(NSDictionary *)parameters
            block:(ALNIdResultBlock)block;

- (void)getObject:(NSString *)path
   withParameters:(NSDictionary *)parameters
           policy:(ALNCachePolicy)policy
      maxCacheAge:(NSTimeInterval)maxCacheAge
            block:(ALNIdResultBlock)block;

-(void)putObject:(NSString *)path
  withParameters:(NSDictionary *)parameters
    sessionToken:(NSString *)sessionToken
           block:(ALNIdResultBlock)block;

-(void)postObject:(NSString *)path
   withParameters:(NSDictionary *)parameters
            block:(ALNIdResultBlock)block;

-(void)deleteObject:(NSString *)path
     withParameters:(NSDictionary *)parameters
              block:(ALNIdResultBlock)block;

//- (void)cancelQueryWithPath:(NSString *)path parameters:(NSDictionary *)parameters;
//
//- (NSString *)absoluteStringFromPath:(NSString *)path parameters:(NSDictionary *)parameters;

#pragma mark - Network Utils

/*!
 * Get signature header field value.
 */
//TODO:delete gignature
//- (NSString *)signatureHeaderFieldValue;

- (LCCurlObject *)curlWithPath:(NSString *)path
                    parameters:(NSDictionary *)parameters
                        method:(LCCurlHTTPMethod)method;

- (void)performCurl:(LCCurlObject *)curl
            success:(void(^)(LCCurlOperation *operation))successBlock
            failure:(void(^)(LCCurlOperation *operation, NSError *error))failureBlock;

- (void)performCurl:(LCCurlObject *)curl
            success:(void(^)(LCCurlOperation *operation))successBlock
            failure:(void(^)(LCCurlOperation *operation, NSError *error))failureBlock
               wait:(BOOL)wait;

@end

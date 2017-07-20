//
//  LCCurlOperation.h
//  ALFNetworking
//
//  Created by Elon Chan on 9/16/15.
//  Copyright (c) 2017 Elon Chan Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCurlObject.h"

extern NSString *const CYLCURLNetworkingErrorDomain;

@interface LCCurlOperation : NSOperation

@property (nonatomic, strong) NSDictionary *header;

@property (nonatomic, readonly, strong) LCCurlObject *curlObject;
@property (nonatomic, readonly, assign) NSInteger statusCode;
@property (nonatomic, readonly, copy) NSString *responseText;

@property (nonatomic, copy) void(^successBlock)(LCCurlOperation *operation);
@property (nonatomic, copy) void(^failureBlock)(LCCurlOperation *operation, NSError *error);

- (instancetype)initWithCurlObject:(LCCurlObject *)curlObject;

- (id)JSONObjectWithError:(NSError **)error;

@end

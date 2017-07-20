//
//  LCCurlObject.h
//  ALFNetworking
//
//  Created by Elon Chan on 9/16/15.
//  Copyright (c) 2017 Elon Chan Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "curl.h"

typedef NS_ENUM(NSInteger, LCCurlHTTPMethod) {
    LCCurlHTTPMethodGet,
    LCCurlHTTPMethodPost,
    LCCurlHTTPMethodPut,
    LCCurlHTTPMethodDelete
};

@interface LCCurlObject : NSObject <NSCoding>

@property (nonatomic, copy)   NSString         *url;
@property (nonatomic, copy)   NSString         *appId;
@property (nonatomic, assign) BOOL              production;
@property (nonatomic, copy)   NSString         *signature;
@property (nonatomic, assign) LCCurlHTTPMethod  method;
@property (nonatomic, copy)   NSString         *payload;
@property (nonatomic, copy)   NSString         *sessionToken;
@property (nonatomic, assign) long              timeout; // Timeout in milliseconds
@property (nonatomic, assign) BOOL              verbose;
@property (nonatomic, strong) NSArray          *IPs;

@property (nonatomic, assign, readonly) CURL   *curl;

- (void)setCustomHeaderValue:(NSString *)headerValue forFieldName:(NSString *)fieldName;

- (NSString *)cURLCommand;

@end

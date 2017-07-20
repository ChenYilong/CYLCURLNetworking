//
//  CYLCURLNetworkingDemoTests.m
//  CYLCURLNetworkingDemoTests
//
//  Created by chenyilong on 2017/7/20.
//  Copyright © 2017年 Elon Chan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CYLCURLNetworking.h"
#import "TestBase.h"

@interface CYLCURLNetworkingDemoTests : XCTestCase

@end

@implementation CYLCURLNetworkingDemoTests

+ (void)initialize {
    HttpDnsService *httpdns = [HttpDnsService sharedInstance];
    [httpdns setLogEnabled:YES];
    [httpdns setAccountID:139450];
    
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    NSString *hostString = @"dou.bz";
    [[HttpDnsService sharedInstance] setPreResolveHosts:@[hostString]];
    sleep(15);
    
    //    [LCDNSResolver resolveIPsForHost:hostString inBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    //        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), objects);
    //        NOTIFY
    //    }];
    //    WAIT
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    //    NSString *host = @"https://dou.bz/23o8PS";
    NSString *host = @"https://dou.bz/23o8PS";
    [[CYLCURLNetworking new] getObject:host withParameters:nil block:^(id object, NSError *error) {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@===>error:%@", @(__PRETTY_FUNCTION__), @(__LINE__), object, error);
        XCTAssertNotNil(object);
        NOTIFY
    }];
    
    WAIT
    
    sleep(10);
    host = @"https://dou.bz/23o8PS";
    [[CYLCURLNetworking new] getObject:host withParameters:nil block:^(id object, NSError *error) {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@===>error:%@", @(__PRETTY_FUNCTION__), @(__LINE__), object, error);
        XCTAssertNotNil(object);
        NOTIFY
    }];
    
    WAIT
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

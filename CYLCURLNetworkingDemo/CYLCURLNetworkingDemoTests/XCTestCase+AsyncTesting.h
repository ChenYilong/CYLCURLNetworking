//
//  TestBase.h
//  
//
//  Created by chenyilong on 2017/4/14.
//  Copyright © 2017年 ElonChan. All rights reserved.
//

#import <XCTest/XCTest.h>


enum {
    XCTAsyncTestCaseStatusUnknown = 0,
    XCTAsyncTestCaseStatusWaiting,
    XCTAsyncTestCaseStatusSucceeded,
    XCTAsyncTestCaseStatusFailed,
    XCTAsyncTestCaseStatusCancelled,
};
typedef NSUInteger XCTAsyncTestCaseStatus;


@interface XCTestCase (AsyncTesting)

- (void)waitForStatus:(XCTAsyncTestCaseStatus)status timeout:(NSTimeInterval)timeout;
- (void)waitForTimeout:(NSTimeInterval)timeout;
- (void)notify:(XCTAsyncTestCaseStatus)status;

@end

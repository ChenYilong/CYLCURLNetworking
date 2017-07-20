//
//  AlicloudReport.h
//  AlicloudUtils
//
//  Created by ryan on 3/6/2016.
//  Copyright © 2016 Ali. All rights reserved.
//

#ifndef AlicloudReport_h
#define AlicloudReport_h

// SDK标识
typedef NS_ENUM(NSInteger, AMSService) {
    AMSMAN  = 0,
    AMSHTTPDNS,
    AMSMPUSH,
    AMSMAC,
    AMSAPI
};

// 上报状态
typedef NS_ENUM(NSInteger, AMSReportStatus) {
    AMS_UNREPORTED_STATUS,
    AMS_REPORTED_STATUS
};

@interface AlicloudReport : NSObject

/**
 *  异步上报活跃设备统计
 *
 @param tag SDK标识
 */
+ (void)statAsync:(AMSService)tag;

/**
 * 获取指定SDK标识上报状态
 *
 @param tag SDK标识
 @return 返回上报状态
 */
+ (AMSReportStatus)getReportStatus:(AMSService)tag;

/**
 * 获取上报状态（兼容老版本接口）
 *
 @param tag SDK标识
 @return YES：已经上报 NO：没有上报
 */
+ (BOOL)isDeviceReported:(AMSService)tag;

@end

#endif /* AlicloudReport_h */

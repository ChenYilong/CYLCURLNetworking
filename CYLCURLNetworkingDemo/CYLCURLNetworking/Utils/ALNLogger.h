//
//  ALNLogger.h
//  
//
//  Created by Elon Chan on 9/9/14.
//
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    ALNLoggerLevelNone = 0,
    ALNLoggerLevelInfo = 1,
    ALNLoggerLevelDebug = 1 << 1,
    ALNLoggerLevelError = 1 << 2,
    ALNLoggerLevelAll = ALNLoggerLevelInfo | ALNLoggerLevelDebug | ALNLoggerLevelError,
} ALNLoggerLevel;

extern NSString *const ALNLoggerDomainCURL;
extern NSString *const ALNLoggerDomainNetwork;
extern NSString *const ALNLoggerDomainIM;
extern NSString *const ALNLoggerDomainStorage;
extern NSString *const ALNLoggerDomainDefault;

@interface ALNLogger : NSObject
+ (void)setAllLogsEnabled:(BOOL)enabled;
+ (void)setLoggerLevelMask:(NSUInteger)levelMask;
+ (void)addLoggerDomain:(NSString *)domain;
+ (void)removeLoggerDomain:(NSString *)domain;
+ (void)logFunc:(const char *)func line:(const int)line domain:(NSString *)domain level:(ALNLoggerLevel)level message:(NSString *)fmt, ... NS_FORMAT_FUNCTION(5, 6);
+ (BOOL)levelEnabled:(ALNLoggerLevel)level;
+ (BOOL)containDomain:(NSString *)domain;
@end

#define _ALNLoggerInfo(_domain, ...) [ALNLogger logFunc:__func__ line:__LINE__ domain:_domain level:ALNLoggerLevelInfo message:__VA_ARGS__]
#define _ALNLoggerDebug(_domain, ...) [ALNLogger logFunc:__func__ line:__LINE__ domain:_domain level:ALNLoggerLevelDebug message:__VA_ARGS__]
#define _ALNLoggerError(_domain, ...) [ALNLogger logFunc:__func__ line:__LINE__ domain:_domain level:ALNLoggerLevelError message:__VA_ARGS__]

#define ALNLoggerInfo(domain, ...) _ALNLoggerInfo(domain, __VA_ARGS__)
#define ALNLoggerDebug(domain, ...) _ALNLoggerDebug(domain, __VA_ARGS__)
#define ALNLoggerError(domain, ...) _ALNLoggerError(domain, __VA_ARGS__)

#define ALNLoggerI(...)  ALNLoggerInfo(ALNLoggerDomainDefault, __VA_ARGS__)
#define ALNLoggerD(...) ALNLoggerDebug(ALNLoggerDomainDefault, __VA_ARGS__)
#define ALNLoggerE(...) ALNLoggerError(ALNLoggerDomainDefault, __VA_ARGS__)

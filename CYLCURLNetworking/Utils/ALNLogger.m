//
//  ALNLogger.m
//  
//
//  Created by Elon Chan on 9/9/14.
//
//

#import "ALNLogger.h"

NSString *const ALNLoggerDomainCURL = @"LOG_CURL";
NSString *const ALNLoggerDomainNetwork = @"LOG_NETWORK";
NSString *const ALNLoggerDomainStorage = @"LOG_STORAGE";
NSString *const ALNLoggerDomainIM = @"LOG_IM";
NSString *const ALNLoggerDomainDefault = @"LOG_DEFAULT";

static NSMutableSet *loggerDomain = nil;
static NSUInteger loggerLevelMask = ALNLoggerLevelNone;
static NSArray *loggerDomains = nil;;

@implementation ALNLogger

+ (void)load {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        loggerDomains = @[
                          ALNLoggerDomainCURL,
                          ALNLoggerDomainNetwork,
                          ALNLoggerDomainIM,
                          ALNLoggerDomainStorage,
                          ALNLoggerDomainDefault
                          ];
    });
#ifdef DEBUG
    [self setAllLogsEnabled:YES];
#else
    [self setAllLogsEnabled:NO];
#endif
}

+ (void)setAllLogsEnabled:(BOOL)enabled {
    if (enabled) {
        for (NSString *loggerDomain in loggerDomains) {
            [ALNLogger addLoggerDomain:loggerDomain];
        }
        [ALNLogger setLoggerLevelMask:ALNLoggerLevelAll];
    } else {
        for (NSString *loggerDomain in loggerDomains) {
            [ALNLogger removeLoggerDomain:loggerDomain];
        }
        [ALNLogger setLoggerLevelMask:ALNLoggerLevelNone];
    }

    [self setCertificateInspectionEnabled:enabled];
}

+ (void)setCertificateInspectionEnabled:(BOOL)enabled {
    if (enabled) {
        setenv("CURL_INSPECT_CERT", "YES", 1);
    } else {
        unsetenv("CURL_INSPECT_CERT");
    }
}

+ (void)setLoggerLevelMask:(NSUInteger)levelMask {
    loggerLevelMask = levelMask;
}

+ (void)addLoggerDomain:(NSString *)domain {
    if (!loggerDomain) {
        loggerDomain = [[NSMutableSet alloc] init];
    }
    [loggerDomain addObject:domain];
}

+ (void)removeLoggerDomain:(NSString *)domain {
    [loggerDomain removeObject:domain];
}

+ (BOOL)levelEnabled:(ALNLoggerLevel)level {
    return loggerLevelMask & level;
}

+ (BOOL)containDomain:(NSString *)domain {
    return [loggerDomain containsObject:domain];
}

+ (void)logFunc:(const char *)func line:(int)line domain:(NSString *)domain level:(ALNLoggerLevel)level message:(NSString *)fmt, ... {
    if (!domain || [loggerDomain containsObject:domain]) {
        if (level & loggerLevelMask) {
            NSString *levelString = nil;
            switch (level) {
                case ALNLoggerLevelInfo:
                    levelString = @"INFO";
                    break;
                case ALNLoggerLevelDebug:
                    levelString = @"DEBUG";
                    break;
                case ALNLoggerLevelError:
                    levelString = @"ERROR";
                    break;
                    
                default:
                    levelString = @"UNKNOW";
                    break;
            }
            va_list args;
            va_start(args, fmt);
            NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
            va_end(args);
            NSLog(@"[%@] %s [Line %d] %@", levelString, func, line, message);
        }
    }
}

@end

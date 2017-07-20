/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import "AVPersistenceUtils.h"
//#import "HttpdnsServiceProvider.h"

#define HttpDnsRootDirName @"CYLCURLNetworking"

@implementation AVPersistenceUtils

#pragma mark - Base Path

/// Base path, all paths depend it
+ (NSString *)homeDirectoryPath {
#if TARGET_OS_IPHONE
    return NSHomeDirectory();
#else
    return [self osxBaseDirectoryPath];
#endif
}

/// ~/Library/Application Support/HTTPDNS/accountID
+ (NSString *)osxBaseDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths firstObject];
    directoryPath = [directoryPath stringByAppendingPathComponent:HttpDnsRootDirName];
    //TODO: accountID
//    int accountID = [HttpDnsService sharedInstance].accountID;
    NSString *accountIDString ;//= [NSString stringWithFormat:@"%@", @(accountID)];
    directoryPath = [directoryPath stringByAppendingPathComponent:accountIDString];
    [self createDirectoryIfNeeded:directoryPath];
    return directoryPath;
}

#pragma mark - ~/Documents

// ~/Documents
+ (NSString *)appDocumentPath {
    static NSString *path = nil;
    
    if (!path) {
        path = [[self homeDirectoryPath] stringByAppendingPathComponent:@"Documents"];
    }
    
    return path;
}

// ~/Documents/HTTPDNS
+ (NSString *)HttpDnsDocumentPath {
    NSString *path = [self appDocumentPath];
    
    path = [path stringByAppendingPathComponent:HttpDnsRootDirName];
    
    [self createDirectoryIfNeeded:path];
    
    return path;
}

#pragma mark - ~/Library/Caches

// ~/Library/Caches
+ (NSString *)appCachePath {
    static NSString *path = nil;
    
    if (!path) {
        path = [[self homeDirectoryPath] stringByAppendingPathComponent:@"Library"];
        path = [path stringByAppendingPathComponent:@"Caches"];
    }
    
    return path;
}

#pragma mark - ~/Libraray/Private Documents

// ~/Library
+ (NSString *)libraryDirectory {
    static NSString *path = nil;
    if (!path) {
        path = [[self homeDirectoryPath] stringByAppendingPathComponent:@"Library"];
    }
    return path;
}

// ~/Library/Caches/AVPaasCache, for AVCacheManager
+ (NSString *)avCacheDirectory {
    NSString *ret = [[self appCachePath] stringByAppendingPathComponent:@"AVPaasCache"];
    [self createDirectoryIfNeeded:ret];
    return ret;
}
#pragma mark - File Utils

+ (BOOL)saveJSON:(id)JSON toPath:(NSString *)path {
    if ([JSON isKindOfClass:[NSDictionary class]] || [JSON isKindOfClass:[NSArray class]]) {
        return [NSKeyedArchiver archiveRootObject:JSON toFile:path];
    }
    
    return NO;
}

+ (id)getJSONFromPath:(NSString *)path {
    id JSON = nil;
    @try {
        JSON = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        
        if ([JSON isMemberOfClass:[NSDictionary class]] || [JSON isMemberOfClass:[NSArray class]]) {
            return JSON;
        }
    }
    @catch (NSException *exception) {
        //deal with the previous file version
        if ([[exception name] isEqualToString:NSInvalidArgumentException]) {
            JSON = [NSMutableDictionary dictionaryWithContentsOfFile:path];
            
            if (!JSON) {
                JSON = [NSMutableArray arrayWithContentsOfFile:path];
            }
        }
    }
    
    return JSON;
}

+ (BOOL)removeFile:(NSString *)path {
    NSError * error = nil;
    BOOL ret = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    return ret;
}

+ (BOOL)fileExist:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)createFile:(NSString *)path {
    BOOL ret = [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil];
    return ret;
}

+ (void)createDirectoryIfNeeded:(NSString *)path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
}

+ (BOOL)deleteFilesInDirectory:(NSString *)dirPath moreThanDays:(NSInteger)numberOfDays {
    BOOL success = NO;
    
    NSDate *nowDate = [NSDate date];
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:dirPath error:&error];
    if (error == nil) {
        for (NSString *path in directoryContents) {
            NSString *fullPath = [dirPath stringByAppendingPathComponent:path];
            NSDate *lastModified = [self lastModified:fullPath];
            if ([nowDate timeIntervalSinceDate:lastModified] < numberOfDays * 24 * 3600)
                continue;
            
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                // NSLog(@"remove error happened");
                success = NO;
            }
        }
    } else {
        // NSLog(@"remove error happened");
        success = NO;
    }
    
    return success;
}

// assume the file is exist
+ (NSDate *)lastModified:(NSString *)fullPath {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
    return [fileAttributes fileModificationDate];
}

#pragma mark -  Private Documents Concrete Path

// ~/Library/Private Documents/HTTPDNS
+ (NSString *)privateDocumentsDirectory {
    NSString *ret = [[self libraryDirectory] stringByAppendingPathComponent:@"Private Documents/HTTPDNS"];
    [self createDirectoryIfNeeded:ret];
    return ret;
}

+ (NSString *)disableStatusPath {
    NSString *ret = [[self privateDocumentsDirectory] stringByAppendingPathComponent:@"disableStatus"];
    [self createDirectoryIfNeeded:ret];
    return ret;
}

//// ~/Documents/HTTPDNS/disableStatus
//+ (NSString *)disableStatusPath {
//    return [[self HttpDnsDocumentPath] stringByAppendingPathComponent:@"disableStatus"];
//}

@end

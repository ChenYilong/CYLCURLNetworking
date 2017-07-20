//
//  NSMutableString+ALNExtension.m
//  CYLCURLNetworking
//
//  Created by Elon Chan on 2017/3/21.
//  Copyright © 2017年 Elon Chan. All rights reserved.
//

#import "NSMutableString+ALNExtension.h"

@implementation NSMutableString (ALNExtension)

- (void)aln_appendCommandLineArgument:(NSString *)arg {
    [self appendFormat:@" %@", [arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
}

@end

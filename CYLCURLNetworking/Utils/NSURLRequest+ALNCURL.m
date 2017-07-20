//
//  NSURLRequest+ALNCURL.m
//  CYLCURLNetworking
//
//  Created by Elon Chan on 2017/3/21.
//  Copyright © 2017年 Elon Chan. All rights reserved.
//

#import "NSURLRequest+ALNCURL.h"
#import "NSMutableString+ALNExtension.h"

@implementation NSURLRequest (ALNCURL)

- (NSString *)aln_cURLCommand {
    NSMutableString *command = [NSMutableString stringWithString:@"curl -i -k"];
    
    [command aln_appendCommandLineArgument:[NSString stringWithFormat:@"-X %@", [self HTTPMethod]]];
    NSData *data = [self HTTPBody];
    if ([data length] > 0) {
        NSString *HTTPBodyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [command aln_appendCommandLineArgument:[NSString stringWithFormat:@"-d '%@'", HTTPBodyString]];
    }
    
    NSString *acceptEncodingHeader = [[self allHTTPHeaderFields] valueForKey:@"Accept-Encoding"];
    if ([acceptEncodingHeader rangeOfString:@"gzip"].location != NSNotFound) {
        [command aln_appendCommandLineArgument:@"--compressed"];
    }
    
    if ([self URL]) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self URL]];
        for (NSHTTPCookie *cookie in cookies) {
            [command aln_appendCommandLineArgument:[NSString stringWithFormat:@"--cookie \"%@=%@\"", [cookie name], [cookie value]]];
        }
    }
    
    for (id field in [self allHTTPHeaderFields]) {
        [command aln_appendCommandLineArgument:[NSString stringWithFormat:@"-H %@", [NSString stringWithFormat:@"'%@: %@'", field, [[self valueForHTTPHeaderField:field] stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"]]]];
    }
    if ([self URL].query.length > 0) {
        // where={}&redirectClassNameForKey=child
        NSString *query = [self URL].query;
        NSArray *components = [query componentsSeparatedByString:@"&"];
        for (NSString *component in components) {
            [command aln_appendCommandLineArgument:[NSString stringWithFormat:@"--data-urlencode \'%@\'", [component stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        }
    }
    
    NSString *basicUrl;
    NSString *absoluteString = [[self URL] absoluteString];
    NSRange range = [absoluteString rangeOfString:@"?"];
    if (range.location != NSNotFound) {
        basicUrl = [absoluteString substringToIndex:range.location];
    } else {
        basicUrl = absoluteString;
    }
    
    [command aln_appendCommandLineArgument:[NSString stringWithFormat:@"\"%@\"", basicUrl]];
    
    return [NSString stringWithString:command];
}

@end

//
//  LCCurlObject.m
//
//
//  Created by Elon Chan on 9/16/15.
//  Copyright (c) 2017 Elon Chan Inc. All rights reserved.
//

#import "LCCurlObject.h"
#import "ALNLogger.h"

@implementation NSMutableString (LCCurlObject)

- (void)lc_appendTrimedString:(NSString *)string {
    [self appendFormat:@" %@", [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

@end

@interface LCCurlObject ()

@property (nonatomic, assign) CURL *curl;
@property (nonatomic, assign) struct curl_slist *headers;
@property (nonatomic, assign) struct curl_slist *hosts_list;
@property (nonatomic, strong) NSMutableDictionary *customHeaders;
@property (nonatomic, assign) char *postBuffer;

@end

#define ALICLOUD_HTTPDNS_LC_SEL_STR(sel) (NSStringFromSelector(@selector(sel)))

@implementation LCCurlObject

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        [self doInitialization];

        self.url          = [aDecoder decodeObjectForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(url)];
        self.appId        = [aDecoder decodeObjectForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(appId)];
        self.production   = [aDecoder decodeBoolForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(production)];
        self.signature    = [aDecoder decodeObjectForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(signature)];
        self.method       = (LCCurlHTTPMethod)[aDecoder decodeIntegerForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(method)];
        self.payload      = [aDecoder decodeObjectForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(payload)];
        self.sessionToken = [aDecoder decodeObjectForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(sessionToken)];
        self.timeout      = (long)[aDecoder decodeInt64ForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(timeout)];
        self.verbose      = [aDecoder decodeBoolForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(verbose)];
        self.IPs          = [aDecoder decodeObjectForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(IPs)];

        NSDictionary *customHeaders = [aDecoder decodeObjectForKey:ALICLOUD_HTTPDNS_LC_SEL_STR(customHeaders)];

        if (customHeaders) {
            self.customHeaders = [customHeaders mutableCopy];

            for (NSString *fieldName in customHeaders) {
                [self setHeaderValue:customHeaders[fieldName] forFieldName:fieldName];
            }
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.url           forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(url)];
    [aCoder encodeObject:self.appId         forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(appId)];
    [aCoder encodeBool:self.production      forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(production)];
    [aCoder encodeObject:self.signature     forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(signature)];
    [aCoder encodeInteger:self.method       forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(method)];
    [aCoder encodeObject:self.payload       forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(payload)];
    [aCoder encodeObject:self.sessionToken  forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(sessionToken)];
    [aCoder encodeInt64:self.timeout        forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(timeout)];
    [aCoder encodeObject:self.customHeaders forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(customHeaders)];
    [aCoder encodeBool:self.verbose         forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(verbose)];
    [aCoder encodeObject:self.IPs           forKey:ALICLOUD_HTTPDNS_LC_SEL_STR(IPs)];
}

- (instancetype)init {
    self = [super init];

    if (self) {
        [self doInitialization];
    }

    return self;
}

- (void)doInitialization {
    _curl = curl_easy_init();

    if (!_curl) {
        ALNLoggerError(ALNLoggerDomainNetwork, @"Request initialization failed.");
        return;
    }

    curl_easy_setopt(_curl, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(_curl, CURLOPT_FOLLOWLOCATION, 1L);
    // curl_easy_setopt(_curl, CURLOPT_PROXY, "http://127.0.0.1:8888");
    // curl_easy_setopt(_curl, CURLOPT_SSL_VERIFYPEER, 0);

    // Default headers for REST API
    //TODO:change user agent
//    [self setHeaderValue:USER_AGENT forFieldName:@"User-Agent"];
    [self setHeaderValue:@"application/json; charset=utf-8" forFieldName:@"Content-Type"];
    [self setHeaderValue:@"application/json" forFieldName:@"Accept"];

    curl_easy_setopt(_curl, CURLOPT_HTTPHEADER, _headers);
}

- (void)removeHeaderForFieldName:(NSString *)fieldName_ {
    if (!fieldName_) return;

    struct curl_slist *header = _headers, *prev_header = NULL;

    while (header) {
        if (header->data) {
            NSString *string = [NSString stringWithCString:header->data encoding:NSUTF8StringEncoding];
            NSRange range = [string rangeOfString:@":"];

            if (range.location != NSNotFound) {
                NSString *fieldName = [[string substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                if ([fieldName isEqualToString:fieldName_]) {
                    struct curl_slist *next_header = header->next;

                    if (prev_header) {
                        prev_header->next = next_header;
                    } else {
                        _headers = next_header;
                    }

                    free(header->data);
                    free(header);

                    break;
                }
            }
        }

        prev_header = header;
        header = header->next;
    }
}

- (void)setHeaderValue:(NSString *)headerValue forFieldName:(NSString *)fieldName {
    [self removeHeaderForFieldName:fieldName];

    if (headerValue && fieldName) {
        _headers = curl_slist_append(_headers, [NSString stringWithFormat:@"%@: %@", fieldName, headerValue].UTF8String);
    }
}

- (void)setCustomHeaderValue:(NSString *)headerValue forFieldName:(NSString *)fieldName {
    if (headerValue && fieldName) {
        self.customHeaders[fieldName] = headerValue;
        [self setHeaderValue:headerValue forFieldName:fieldName];
    }
}

- (void)setUrl:(NSString *)url {
    _url = [url copy];
    curl_easy_setopt(_curl, CURLOPT_URL, _url.UTF8String);
}

//TODO:AppId ==》 AccountId
- (void)setAppId:(NSString *)appId {
//    _appId = [appId copy];
//    [self setHeaderValue:_appId forFieldName:LCHeaderFieldNameId];
}

- (void)setSignature:(NSString *)signature {
//    _signature = [signature copy];
//    [self setHeaderValue:_signature forFieldName:LCHeaderFieldNameSign];
}

- (void)setProduction:(BOOL)production {
//    _production = production;
//    [self setHeaderValue:production ? @"1" : @"0" forFieldName:LCHeaderFieldNameProduction];
}

- (void)setMethod:(LCCurlHTTPMethod)method {
    _method = method;

    switch (method) {
    case LCCurlHTTPMethodGet:
        curl_easy_setopt(_curl, CURLOPT_HTTPGET, 1L);
        break;
    case LCCurlHTTPMethodPost:
        curl_easy_setopt(_curl, CURLOPT_HTTPPOST, 1L);
        break;
    case LCCurlHTTPMethodPut:
        curl_easy_setopt(_curl, CURLOPT_CUSTOMREQUEST, "PUT");
        break;
    case LCCurlHTTPMethodDelete:
        curl_easy_setopt(_curl, CURLOPT_CUSTOMREQUEST, "DELETE");
        break;
    default:
        break;
    }
}

- (NSString *)HTTPMethod {
    NSString *methodString = nil;

    switch (self.method) {
    case LCCurlHTTPMethodGet:
        methodString = @"GET";
        break;
    case LCCurlHTTPMethodPost:
        methodString = @"POST";
        break;
    case LCCurlHTTPMethodPut:
        methodString = @"PUT";
        break;
    case LCCurlHTTPMethodDelete:
        methodString = @"DELETE";
        break;
    default:
        methodString = @"UNKNOWN";
        break;
    }

    return methodString;
}

- (void)setPayload:(NSString *)payload {
    if (_postBuffer) {
        free(_postBuffer);
        _postBuffer = NULL;
    }

    _payload = [payload copy];

    if (_payload) {
        _postBuffer = strdup([_payload UTF8String]);
        curl_easy_setopt(_curl, CURLOPT_POSTFIELDS, _postBuffer);
    } else {
        curl_easy_setopt(_curl, CURLOPT_POSTFIELDS, "");
    }
}

//TODO:Delete
- (void)setSessionToken:(NSString *)sessionToken {
//    _sessionToken = [sessionToken copy];
//    [self setHeaderValue:_sessionToken forFieldName:LCHeaderFieldNameSession];
}

- (void)setTimeout:(long)timeout {
    _timeout = timeout;
    curl_easy_setopt(_curl, CURLOPT_TIMEOUT_MS, timeout);
}

- (void)setVerbose:(BOOL)verbose {
    _verbose = verbose;
    curl_easy_setopt(_curl, CURLOPT_VERBOSE, verbose);
}

- (void)setIPs:(NSArray *)IPs {
    _IPs = IPs;

    [self cleanHosts];

    for (NSString *IP in IPs) {
        [self addIP:IP];
    }
}

- (NSNumber *)portOfURL:(NSURL *)URL {
    return URL.port ?: @([self.url hasPrefix:@"https://"] ? 443 : 80);
}

//dou.bz:443:118.144.67.10
- (NSString *)curlHostWithIP:(NSString *)IP {
    NSURL *URL = [NSURL URLWithString:self.url];
    NSMutableString *host = [NSMutableString string];

    [host appendString:URL.host];
    [host appendString:[NSString stringWithFormat:@":%@", [self portOfURL:URL]]];
    [host appendString:[NSString stringWithFormat:@":%@", IP]];
NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), host);
    return host;
}

- (void)addIP:(NSString *)IP {
    //curlHost 形如：dou.bz:443:118.144.67.10
//{HTTPS域名}:443:{IP地址}
    NSString *curlHost = [self curlHostWithIP:IP];
    _hosts_list = curl_slist_append(_hosts_list, curlHost.UTF8String);
    curl_easy_setopt(_curl, CURLOPT_RESOLVE, _hosts_list);
}

- (void)cleanHosts {
    if (_hosts_list) {
        curl_slist_free_all(_hosts_list);
        _hosts_list = NULL;
    }
}

#pragma mark - Curl command

- (NSString *)cURLCommand {
    NSMutableString *command = [NSMutableString stringWithString:@"curl -i -k"];

    [command lc_appendTrimedString:@"--compressed"];
    [command lc_appendTrimedString:[NSString stringWithFormat:@"-X %@", [self HTTPMethod]]];

    if (self.method == LCCurlHTTPMethodGet) {
        [command lc_appendTrimedString:@"-G"];
    }

    /* HTTP header */
    struct curl_slist *header = _headers;

    while (header) {
        char *data = header->data;
        if (data) {
            NSString *value = [NSString stringWithCString:data encoding:NSUTF8StringEncoding];
            NSString *headerOption = [NSString stringWithFormat:@"-H %@", [NSString stringWithFormat:@"'%@'", [value stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"]]];
            [command lc_appendTrimedString:headerOption];
        }
        header = header->next;
    }

    /* HTTP post data */
    if ([self.payload length]) {
        [command lc_appendTrimedString:[NSString stringWithFormat:@"-d '%@'", self.payload]];
    }

    /* HTTP query string */
    NSURL *URL = [NSURL URLWithString:self.url];

    if (URL.query.length) {
        NSString *query = URL.query;
        NSArray *components = [query componentsSeparatedByString:@"&"];
        for (NSString *component in components) {
            [command lc_appendTrimedString:[NSString stringWithFormat:@"--data-urlencode \'%@\'", [component stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        }
    }

    NSString *basicUrl;
    NSString *absoluteString = [URL absoluteString];

    NSRange range = [absoluteString rangeOfString:@"?"];
    if (range.location != NSNotFound) {
        basicUrl = [absoluteString substringToIndex:range.location];
    } else {
        basicUrl = absoluteString;
    }

    [command lc_appendTrimedString:[NSString stringWithFormat:@"\"%@\"", basicUrl]];

    return [NSString stringWithString:command];
}

#pragma mark - Lazy loading

- (NSMutableDictionary *)customHeaders {
    return _customHeaders ?: (_customHeaders = [NSMutableDictionary dictionary]);
}

#pragma mark -

- (void)dealloc {
    if (_headers)
        curl_slist_free_all(_headers);

    if (_hosts_list)
        curl_slist_free_all(_hosts_list);

    if (_curl)
        curl_easy_cleanup(_curl);

    if (_postBuffer)
        free(_postBuffer);
}

@end

//
//  YCLogConfig.m
//  YCLog
//
//  Created by wz on 2023/10/17.
//

#import "YCLogConfig.h"
NSString * const kRestfulLoggerId = @"YCLog";

@implementation YCLogConfig

- (instancetype)init
{
    if (self = [super init]) {
        _timeout = 20;
        _logBonjourId = [self.class logId];
        _supportBonjour = [self.class supportBonjour];
        _queue = dispatch_queue_create([kRestfulLoggerId UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (NSString *)logId
{
    return [NSString stringWithFormat:@"_%@._tcp.",kRestfulLoggerId];
}

+ (BOOL)supportBonjour
{
    if (@available(iOS 14.0, *)) {
        NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
        NSArray *services = dict[@"NSBonjourServices"];
        NSString *localNetworkUsageDesc = dict[@"NSLocalNetworkUsageDescription"];
        return [services containsObject:[self logId]] && localNetworkUsageDesc.length > 0;
    }
    return true;
}

@end

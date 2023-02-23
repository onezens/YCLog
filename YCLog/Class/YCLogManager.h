//
//  YCLogManager.h
//  YCLog
//
//  Created by wz on 2019/3/21.
//  Copyright © 2019 wz. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, YCLogFlag) {
    /**0...0001*/
    YCLogFlagError = 1 << 0,
    /**0...0010*/
    YCLogFlagWarn = 1 << 1,
    /**0...0100*/
    YCLogFlagInfo = 1 << 2,
    /**0...1000*/
    YCLogFlagDebug = 1 << 3
};

/**
 YCLogLevel

 - YCLogLevelOff: no logs
 - YCLogLevelError: error level log
 - YCLogLevelWarn: error, warn, level log
 - YCLogLevelInfo: error, warn, level log
 - YCLogLevelDebug: error, warn ,debug level log
 - YCLogLevelAll: all logs
 */
typedef NS_ENUM(NSUInteger, YCLogLevel) {
    YCLogLevelOff = 0,
    YCLogLevelError = (YCLogFlagError),
    YCLogLevelWarn = (YCLogFlagWarn | YCLogLevelError),
    YCLogLevelInfo = (YCLogFlagInfo | YCLogLevelWarn),
    YCLogLevelDebug = (YCLogFlagDebug | YCLogLevelInfo),
    YCLogLevelAll = NSUIntegerMax
};

NS_ASSUME_NONNULL_BEGIN

@interface YCLogConfig : NSObject

/// 禁用日志输出到 Xcode 控制台
@property (nonatomic, assign) BOOL disableLogConsole;

@end

@interface YCLogManager : NSObject

+ (void)setup:(YCLogConfig *)config;

+ (void)logLevel:(YCLogLevel)level
            flag:(YCLogFlag)flag
            file:(const char * __nullable)file
            line:(NSUInteger)line
          format:(NSString *)format, ... NS_FORMAT_FUNCTION(5,6);

+ (void)logLevel:(YCLogLevel)level
            flag:(YCLogFlag)flag
             tag:(NSString * __nullable)tag
          format:(NSString *)format, ... NS_FORMAT_FUNCTION(4,5);


@end

NS_ASSUME_NONNULL_END

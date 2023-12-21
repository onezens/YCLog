//
//  YCLog.h
//  YCLog
//
//  Created by wz on 2023/9/5.
//


#import <YCLog/YCLogConfig.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef YCLog_h
#define YCLog_h

/** default log level */
#ifndef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF YCLogLeveDebug
#endif

#define YCLogError(frmt,...) [YCLog logLevel:LOG_LEVEL_DEF flag:YCLogFlagError file:__FILE__ line:__LINE__ format:frmt, ##__VA_ARGS__]
#define YCLogWarn(frmt,...) [YCLog logLevel:LOG_LEVEL_DEF flag:YCLogFlagWarn file:__FILE__ line:__LINE__ format:frmt, ##__VA_ARGS__]
#define YCLogInfo(frmt,...) [YCLog logLevel:LOG_LEVEL_DEF flag:YCLogFlagInfo file:__FILE__ line:__LINE__ format:frmt, ##__VA_ARGS__]
#define YCLogDebug(frmt,...) [YCLog logLevel:LOG_LEVEL_DEF flag:YCLogFlagDebug file:__FILE__ line:__LINE__ format:frmt, ##__VA_ARGS__]


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
 - YCLogLeveWarn: error, warn, level log
 - YCLogLeveInfo: error, warn, level log
 - YCLogLeveDebug: error, warn ,debug level log
 - YCLogLeveAll: all logs
 */
typedef NS_ENUM(NSUInteger, YCLogLevel) {
    YCLogLevelOff = 0,
    YCLogLevelError = (YCLogFlagError),
    YCLogLeveWarn = (YCLogFlagWarn | YCLogLevelError),
    YCLogLeveInfo = (YCLogFlagInfo | YCLogLeveWarn),
    YCLogLeveDebug = (YCLogFlagDebug | YCLogLeveInfo),
    YCLogLeveAll = NSUIntegerMax
};


#endif /* YCLog_h */

@interface YCLog : NSObject

+ (instancetype)shared;

/// 设置日志配置
- (void)setup:(YCLogConfig *)config;
/// 更新日志服务
- (void)refreshLogHost:(NSString *)logHost;

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




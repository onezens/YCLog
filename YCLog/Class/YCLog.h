//
//  YCLog.h
//  YCLog
//
//  Created by wz on 2019/3/21.
//  Copyright © 2019 wz. All rights reserved.
//

#ifndef YCLog_h
#define YCLog_h

#import "YCLogManager.h"

/** default log level */
#ifndef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF YCLogLevelDebug
#endif

#define YCLogError(frmt,...) [YCLogManager logLevel:LOG_LEVEL_DEF flag:YCLogFlagError function:__FILE__ line:__LINE__ format:frmt, ##__VA_ARGS__]
#define YCLogWarn(frmt,...) [YCLogManager logLevel:LOG_LEVEL_DEF flag:YCLogFlagWarn function:__FILE__ line:__LINE__ format:frmt, ##__VA_ARGS__]
#define YCLogInfo(frmt,...) [YCLogManager logLevel:LOG_LEVEL_DEF flag:YCLogFlagInfo function:__FILE__ line:__LINE__ format:frmt, ##__VA_ARGS__]
#define YCLogDebug(frmt,...) [YCLogManager logLevel:LOG_LEVEL_DEF flag:YCLogFlagDebug function:__FILE__ line:__LINE__ format:frmt, ##__VA_ARGS__]



#endif /* YCLog_h */

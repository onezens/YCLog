//
//  YCLog.h
//  YCLog
//
//  Created by wz on 2018/2/8.
//  Copyright © 2018年 wz. All rights reserved.
//

#ifndef YCLog_h
#define YCLog_h
#include <CoreFoundation/CoreFoundation.h>
#define YC_FILE [NSString stringWithCString:__BASE_FILE__ encoding:NSUTF8StringEncoding].lastPathComponent

#if DEBUG

    enum {    // Legal level values for CFLog()
        kYCLogLevelError = 3,
        kYCLogLevelWarning = 4,
        kYCLogLevelNotice = 5,
    };

    #ifndef CFLog
        //compiler define
        void CFLog(int32_t level, CFStringRef format, ...);
    #endif
    #define YC_LOG_FORMAT(color) CFSTR("\e[1;3" #color "m[%@:%d]\e[m \e[0;30;4" #color "[%@")
    #define YC_LOG_INTERNAL(color, level, ...) CFLog(level, YC_LOG_FORMAT(color), YC_FILE, __LINE__, [NSString stringWithFormat:__VA_ARGS__])

    #define YCLogInfo(...) YC_LOG_INTERNAL(5, kYCLogLevelNotice,  __VA_ARGS__)
    #define YCLogWarn(...) YC_LOG_INTERNAL(3, kYCLogLevelWarning, __VA_ARGS__)
    #define YCLogError(...) YC_LOG_INTERNAL(1, kYCLogLevelError, __VA_ARGS__)
    #define YCLogDebug(...) YC_LOG_INTERNAL(6, kYCLogLevelNotice, __VA_ARGS__)

#else

    #define YCLogInfo(...)
    #define YCLogWarn(...)
    #define YCLogError(...)
    #define YCLogDebug(...)

#endif

#endif /* YCLog_h */


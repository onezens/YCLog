//
//  YCLog.c
//  YCLog
//
//  Created by wz on 2018/2/8.
//  Copyright © 2018年 wz. All rights reserved.
//


#include <CoreFoundation/CoreFoundation.h>

#include "YCLog.h"

//#ifndef CFLog
//void CFLog(int32_t level, CFStringRef format, ...) {
//    printf("--------------------\n");
//}
//#endif



//[0;37mFeb  8 17:14:10 wz5[0;36m YCLog[16772] [2;32m<[0;32mNotice[2;32m>[0;37m:[m [1;32m[AppDelegate.m:25][m [0;30;42[HBLogInfo
//[0;37mFeb  8 17:14:10 wz5[0;36m YCLog[16772] [2;31m<[0;31mError[2;31m>[0;37m:[m [1;31m[AppDelegate.m:27][m [0;30;41[HBLogError

//#import <os/log.h>
//
//#define YC_LOG_INTERNAL(level, type, ...) os_log_with_type(OS_LOG_DEFAULT, level, "[1;32m[%{public}@:%{public}d][m [0;30;42[%{public}@", YC_FILE, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
//
//#define YCLogDebug(...) YC_LOG_INTERNAL(OS_LOG_TYPE_DEBUG, "DEBUG", __VA_ARGS__)
//#define YCLogInfo(...) YC_LOG_INTERNAL(OS_LOG_TYPE_INFO, "INFO", __VA_ARGS__)
//#define YCLogWarn(...) YC_LOG_INTERNAL(OS_LOG_TYPE_DEFAULT, "WARN", __VA_ARGS__)
//#define YCLogError(...) YC_LOG_INTERNAL(OS_LOG_TYPE_ERROR, "ERROR", __VA_ARGS__)
//
//
//


////&& __has_include(<os/log.h>)
//#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_10_0
//    #import <os/log.h>
//
//    #define YC_LOG_INTERNAL(level, type, ...) os_log_with_type(OS_LOG_DEFAULT, level, "[%{public}s:%{public}d] %{public}@", __BASE_FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
//
//    #define YCLogDebug(...) YC_LOG_INTERNAL(OS_LOG_TYPE_DEBUG, "DEBUG", __VA_ARGS__)
//    #define YCLogInfo(...) YC_LOG_INTERNAL(OS_LOG_TYPE_INFO, "INFO", __VA_ARGS__)
//    #define YCLogWarn(...) YC_LOG_INTERNAL(OS_LOG_TYPE_DEFAULT, "WARN", __VA_ARGS__)
//    #define YCLogError(...) YC_LOG_INTERNAL(OS_LOG_TYPE_ERROR, "ERROR", __VA_ARGS__)
//#else
//
//
//#endif


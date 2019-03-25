//
//  YCLogManager.m
//  YCLog
//
//  Created by wz on 2019/3/21.
//  Copyright © 2019 wz. All rights reserved.
//

#import "YCLogManager.h"
#import <UIKit/UIKit.h>
#import "YCLogClient.h"

#define COLOR_RESET         "\e[m"
#define COLOR_NORMAL        "\e[0m"
#define COLOR_DARK          "\e[2m"
#define COLOR_GRay          "\e[2;30m"
#define COLOR_GRay_BOLD     "\e[2;30;1m"
#define COLOR_RED           "\e[0;31m"
#define COLOR_RED_BOLD      "\e[0;31;1m"
#define COLOR_RED_DARK      "\e[2;31m"
#define COLOR_GREEN         "\e[0;32m"
#define COLOR_GREEN_BOLD    "\e[0;32;1m"
#define COLOR_GREEN_DARK    "\e[2;32m"
#define COLOR_YELLOW        "\e[0;33m"
#define COLOR_YELLOW_BOLD   "\e[0;33;1m"
#define COLOR_YELLOW_DARK   "\e[2;33m"
#define COLOR_BLUE          "\e[0;34m"
#define COLOR_BLUE_BOLD     "\e[0;34;1m"
#define COLOR_BLUE_DARK     "\e[2;34m"
#define COLOR_MAGENTA       "\e[0;35m" //洋红色的
#define COLOR_MAGENTA_BOLD  "\e[0;35;1m"
#define COLOR_MAGENTA_DARK  "\e[2;35m"
#define COLOR_CYAN          "\e[0;36m"
#define COLOR_CYAN_BOLD     "\e[0;36;1m"
#define COLOR_CYAN_DARK     "\e[2;36m"
#define COLOR_WHITE         "\e[0;37m"
#define COLOR_WHITE_DARK    "\e[2;37m"

void HandleException(NSException *exception)
{
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    
    // 出现异常的原因
    NSString *reason = [exception reason];
    
    // 异常名称
    NSString *name = [exception name];
    
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    
    [YCLogManager logLevel:YCLogLevelError flag:YCLogFlagError function:NULL line:0 format:@"%@",exceptionInfo];

}


void InstallUncaughtExceptionHandler(void)
{
    NSSetUncaughtExceptionHandler(&HandleException);
}


@implementation YCLogManager
NSFileHandle *fh ;
YCLogClient *_logClient;

+ (void)log:(NSString *)log, ...{
    if (!log) return;
    va_list args;
    va_start(args, log);
    NSString *allLog = [[NSString alloc] initWithFormat:log arguments:args];
    NSLog(@"%@", allLog);
}

+ (void)logLevel:(YCLogLevel)level flag:(YCLogFlag)flag function:(const char *)function line:(NSUInteger)line format:(NSString *)format, ... {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        InstallUncaughtExceptionHandler();
        _logClient = [[YCLogClient alloc] init];
    });
    if (!format) return;
    va_list args;
    va_start(args, format);
    if(!(level&flag)) return;
    NSString *flagDesc = nil;
    switch (flag) {
        case YCLogFlagError:
            flagDesc = [NSString stringWithFormat:@"%s<ERROR>%s",COLOR_GREEN, COLOR_RED_BOLD];
            break;
        case YCLogFlagWarn:
            flagDesc = [NSString stringWithFormat:@"%s<WARN>%s", COLOR_GREEN, COLOR_YELLOW_BOLD];
            break;
        case YCLogFlagInfo:
            flagDesc = [NSString stringWithFormat:@"%s<INFO>%s", COLOR_GREEN, COLOR_MAGENTA_BOLD];
            break;
        case YCLogFlagDebug:
            flagDesc = [NSString stringWithFormat:@"%s<DEBUG>%s", COLOR_GREEN, COLOR_CYAN_BOLD];
            break;
        default:
            break;
    }
    NSString *allLog = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSString *file = nil;
    if (function != NULL) {
        file = [NSString stringWithCString:function encoding:NSUTF8StringEncoding];
        file = file.lastPathComponent;
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MMM dd HH:mm:ss"];
    NSString *dateStr = [df stringFromDate:[NSDate date]];
    NSString *deviceName = [UIDevice currentDevice].name;
    NSString *appName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    
    NSString *log = [NSString stringWithFormat:@"%s%@ %@%s %@ %@ [%@:%lu] :%s %@ \n",COLOR_GRay,dateStr , deviceName, COLOR_CYAN, appName ,flagDesc, file, (unsigned long)line, COLOR_RESET, allLog];
    [self logInfoToFile:log];
}

+ (void)logInfoToFile:(NSString *)log {
    [self logfile:[log dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (void)logfile:(NSData *)data {
    if (!fh) {
        fh = [NSFileHandle fileHandleForWritingAtPath:@"/Users/wz/Desktop/1.log"];
        [fh seekToEndOfFile];
    }
    [fh writeData:data];
    [_logClient sendMsg:data];
}

@end

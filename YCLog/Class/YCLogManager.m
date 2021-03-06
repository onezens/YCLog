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

@interface YCLogManager()
+ (void)_logLevel:(YCLogLevel)level flag:(YCLogFlag)flag fileName:(NSString *)fileName line:(NSUInteger)line allLog:(NSString *)allLog;

@end


void HandleException(NSException *exception) {
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    [YCLogManager _logLevel:YCLogLevelError flag:YCLogFlagError fileName:nil line:0 allLog:exceptionInfo];
}

void InstallUncaughtExceptionHandler(void) {
    NSSetUncaughtExceptionHandler(&HandleException);
}

@implementation YCLogManager
NSFileHandle *fh ;
YCLogClient *_logClient;
NSString *_logPath;

+ (void)initLogBase {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        InstallUncaughtExceptionHandler();
        _logClient = [[YCLogClient alloc] init];
    });
}

+ (void)logLevel:(YCLogLevel)level flag:(YCLogFlag)flag file:(const char *)file line:(NSUInteger)line format:(NSString *)format, ... {

    [self initLogBase];
    if (!format | !(level&flag)) return;

    va_list args;
    va_start(args, format);
    NSString *allLog = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSString *fileName = nil;
    if (file != NULL) {
        fileName = [NSString stringWithCString:file encoding:NSUTF8StringEncoding].lastPathComponent;
    }
    [self _logLevel:level flag:flag fileName:fileName line:line allLog:allLog];
    [self _logConsoleLevel:level flag:flag fileName:fileName line:line allLog:allLog];
}

+ (void)_logConsoleLevel:(YCLogLevel)level flag:(YCLogFlag)flag fileName:(NSString *)fileName line:(NSUInteger)line allLog:(NSString *)allLog {
    NSString *flagDesc = nil;
    switch (flag) {
        case YCLogFlagError:
            flagDesc = [NSString stringWithFormat:@"<ERROR>"];
            break;
        case YCLogFlagWarn:
            flagDesc = [NSString stringWithFormat:@"<WARN>"];
            break;
        case YCLogFlagInfo:
            flagDesc = [NSString stringWithFormat:@"<INFO>"];
            break;
        case YCLogFlagDebug:
            flagDesc = [NSString stringWithFormat:@"<DEBUG>"];
            break;
        default:
            break;
    }
    NSString *log = [NSString stringWithFormat:@"%@ [%@:%lu] %@", flagDesc, fileName, line, allLog];
    NSLog(@"%@",log);
}

+ (void)_logLevel:(YCLogLevel)level flag:(YCLogFlag)flag fileName:(NSString *)fileName line:(NSUInteger)line allLog:(NSString *)allLog {
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
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd HH:mm:ss"];
    NSString *dateStr = [df stringFromDate:[NSDate date]];
    NSString *deviceName = [UIDevice currentDevice].name;
    NSString *appName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    
    NSString *log = [NSString stringWithFormat:@"%s%@ %@%s %@ %@ [%@:%lu] :%s %@ \n",COLOR_GRay,dateStr , deviceName, COLOR_CYAN, appName ,flagDesc, fileName, (unsigned long)line, COLOR_RESET, allLog];
    
    if (_logClient.isConnected) {
        [self logToServer:log];
        return;
    }
    [self logIphone:log dateStr:dateStr];
    
}

+ (NSString *)getLocalPhonePath{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    path = [path stringByAppendingPathComponent:@"YCLog"];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM-dd"];
    NSString *dateStr = [df stringFromDate:[NSDate date]];
    NSString *logfile = [path stringByAppendingFormat:@"/%@.log",dateStr];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
        [[NSFileManager defaultManager] createFileAtPath:logfile contents:nil attributes:nil];
    }
    return logfile;
}

+ (void)logIphone:(NSString *)log dateStr:(NSString *)dateStr{
    if (!_logPath) {
        _logPath = [self getLocalPhonePath];
    }
    [self logInfoToFile:log path:_logPath];
    
}

+ (void)logToServer:(NSString *)log {
    [_logClient sendMsg:[log dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (void)logInfoToFile:(NSString *)log path:(NSString *)path{
    NSData *logData = [log dataUsingEncoding:NSUTF8StringEncoding];
    if (!fh) {
        fh = [NSFileHandle fileHandleForWritingAtPath:path];
        [fh seekToEndOfFile];
    }
    [fh writeData:logData];
    [_logClient sendMsg:logData];
}




@end

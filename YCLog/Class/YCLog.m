//
//  YCLog.m
//  YCLog
//
//  Created by wz on 2023/9/5.
//


#import "YCLog.h"
#import "YCLogClient.h"

static char * const COLOR_RESET             =   "\e[m";
static char * const COLOR_NORMAL            =   "\e[0m";
static char * const COLOR_DARK              =   "\e[2m";
static char * const COLOR_GRay              =   "\e[2;30m";
static char * const COLOR_GRay_BOLD         =   "\e[2;30;1m";
static char * const COLOR_RED               =   "\e[0;31m";
static char * const COLOR_RED_BOLD          =   "\e[0;31;1m";
static char * const COLOR_RED_DARK          =   "\e[2;31m";
static char * const COLOR_GREEN             =   "\e[0;32m";
static char * const COLOR_GREEN_BOLD        =   "\e[0;32;1m";
static char * const COLOR_GREEN_DARK        =   "\e[2;32m";
static char * const COLOR_YELLOW            =   "\e[0;33m";
static char * const COLOR_YELLOW_BOLD       =   "\e[0;33;1m";
static char * const COLOR_YELLOW_DARK       =   "\e[2;33m";
static char * const COLOR_BLUE              =   "\e[0;34m";
static char * const COLOR_BLUE_BOLD         =   "\e[0;34;1m";
static char * const COLOR_BLUE_DARK         =   "\e[2;34m";
static char * const COLOR_MAGENTA           =   "\e[0;35m"; //洋红色的
static char * const COLOR_MAGENTA_BOLD      =   "\e[0;35;1m";
static char * const COLOR_MAGENTA_DARK      =   "\e[2;35m";
static char * const COLOR_CYAN              =   "\e[0;36m";
static char * const COLOR_CYAN_BOLD         =   "\e[0;36;1m";
static char * const COLOR_CYAN_DARK         =   "\e[2;36m";
static char * const COLOR_WHITE             =   "\e[0;37m";
static char * const COLOR_WHITE_DARK        =   "\e[2;37m";

@interface YCLog()

@property (nonatomic, strong) YCLogClient *logClient;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;


@end

@implementation YCLog

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    static YCLog *_restfulLog;
    dispatch_once(&onceToken, ^{
        _restfulLog = [YCLog new];
        [_restfulLog initPrivate];
    });
    return _restfulLog;
}

- (void)initPrivate
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];
    self.dateFormatter = df;
}

- (void)setup:(YCLogConfig *)config
{
    _logClient = [[YCLogClient alloc] initWithConfig:config];
}

- (void)refreshLogHost:(NSString *)logHost
{
    if (!self.logClient) {
        return;
    }
    if (![self.logClient.config.logHost isEqualToString:logHost]) {
        dispatch_async(self.logClient.config.queue, ^{
            [[YCLog shared].logClient connectToServer];
        });
        self.logClient.config.logHost = logHost;
    }
}

+ (BOOL)isDisable
{
    return ![YCLogConfig supportBonjour] && [YCLog shared].logClient.config.logHost.length == 0;
}

+ (void)logUnsupportTips
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *logId = YCLog.shared.logClient.config.logBonjourId;
        printf("[YCLogConsole] unsupport YCLog logId: %s, Please set log host!\n", logId.UTF8String);
    });
}

+ (void)logLevel:(YCLogLevel)level flag:(YCLogFlag)flag file:(const char *)file line:(NSUInteger)line format:(NSString *)format, ...
{
    if ([self isDisable]) {
        [self logUnsupportTips];
        return;
    }
    
    if (!format | !(level&flag)) return;

    va_list args;
    va_start(args, format);
    NSString *allLog = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSString *fileName = nil;
    if (file != NULL) {
        fileName = [NSString stringWithCString:file encoding:NSUTF8StringEncoding].lastPathComponent;
    }
    [[self shared] _logLevel:level flag:flag tag:[NSString stringWithFormat:@"%@:%ld", fileName, line] allLog:allLog];
}

+ (void)logLevel:(YCLogLevel)level flag:(YCLogFlag)flag tag:(NSString *)tag format:(NSString *)format, ...
{
    if ([self isDisable]) {
        [self logUnsupportTips];
        return;
    }
    if (!format | !(level&flag)) return;
    va_list args;
    va_start(args, format);
    NSString *allLog = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [[self shared] _logLevel:level flag:flag tag:tag allLog:allLog];
}

- (void)_logLevel:(YCLogLevel)level flag:(YCLogFlag)flag tag:(NSString *)tag allLog:(NSString *)allLog
{
    NSAssert(self.logClient.config, @"没有设置config");
    if (!self.logClient.config) {
        return;
    }
    dispatch_async(self.logClient.config.queue, ^{
        NSString *flagDesc = nil;
        switch (flag) {
            case YCLogFlagError:
                flagDesc = [NSString stringWithFormat:@"%s<ERROR>%s", COLOR_RED, COLOR_RED_BOLD];
                break;
            case YCLogFlagWarn:
                flagDesc = [NSString stringWithFormat:@"%s<WARN >%s", COLOR_YELLOW, COLOR_YELLOW_BOLD];
                break;
            case YCLogFlagInfo:
                flagDesc = [NSString stringWithFormat:@"%s<INFO >%s", COLOR_GREEN, COLOR_MAGENTA_BOLD];
                break;
            case YCLogFlagDebug:
                flagDesc = [NSString stringWithFormat:@"%s<DEBUG>%s", COLOR_GREEN, COLOR_BLUE_BOLD];
                break;
            default:
                break;
        }
        
        NSString *dateStr = [self.dateFormatter stringFromDate:[NSDate date]];
        NSString *deviceName = @"Apple";
#if TARGET_OS_OSX
        deviceName = [[NSHost currentHost] localizedName];
#elif TARGET_OS_IOS
        deviceName =  [UIDevice currentDevice].name;
#endif
        NSString *appName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
        NSString *log = nil;
        if (tag != nil) {
            log = [NSString stringWithFormat:@"%s%@ %@%s %@ %@ [%@] :%s %@ \n",COLOR_CYAN, dateStr , deviceName, COLOR_CYAN, appName ,flagDesc, tag, COLOR_RESET, allLog];
        }else {
            log = [NSString stringWithFormat:@"%s%@ %@%s %@ %@ : %@ \n",COLOR_CYAN, dateStr , deviceName, COLOR_CYAN, appName ,flagDesc, allLog];
        }
        [self logToServer:log];
    });
}

- (void)logToServer:(NSString *)log
{
    [_logClient sendMsg:log];
}

@end


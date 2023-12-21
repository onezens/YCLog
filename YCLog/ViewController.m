//
//  ViewController.m
//  YCLog
//
//  Created by wz on 2019/3/21.
//  Copyright © 2019 wz. All rights reserved.
//

#import "ViewController.h"
#import "YCLog.h"
#import "YCLogClient.h"

@interface ViewController ()
@property (nonatomic, strong) YCLogClient *client;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initYCLog];
}

- (void)initYCLog
{
    YCLogConfig *config = [YCLogConfig new];
    config.localLogPath = [self logPath];
    [[YCLog shared] setup:config];
}

- (NSString *)logPath
{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    path = [path stringByAppendingPathComponent:@"YCLog"];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM-dd"];
    NSString *dateStr = [df stringFromDate:[NSDate date]];
    NSString *logfile = [path stringByAppendingFormat:@"/%@.log",dateStr];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:logfile]) {
        [[NSFileManager defaultManager] createFileAtPath:logfile contents:nil attributes:nil];
    }
    return path;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    YCLogError(@"error");
    YCLogWarn(@"warn");
    YCLogInfo(@"info");
    YCLogDebug(@"debug");
    [self sendRequest];
}

- (void)sendRequest
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:@"http://api.onezen.cc/v1/video/list?page=1&size=1"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            YCLogError(@"[sendRequest] error: %@",error);
            return;
        }
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        YCLogInfo(@"[sendRequest] success result: %@", obj);
    }];
    [task resume];
}


@end

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
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    YCLogError(@"error");
    YCLogWarn(@"warn");
    YCLogInfo(@"info");
    YCLogDebug(@"debug");
}


@end

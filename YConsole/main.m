//
//  main.m
//  YConsole
//
//  Created by wz on 2019/3/21.
//  Copyright © 2019 wz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCLogServer.h"

YCLogServer *_logServer;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        _logServer = [[YCLogServer alloc] init];
        [_logServer createServer];
        
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop run];
    }
    return 0;
}

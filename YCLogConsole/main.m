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
        NSMutableArray *filterKeys = [NSMutableArray array];
        NSMutableArray *blockKeys = [NSMutableArray array];
        NSString *deviceID = nil;
        NSInteger serviceType = 0;
        int type = -1;
        for(int i=1; i<argc; i++){
            NSString *key = [NSString stringWithCString: argv[i] encoding:NSUTF8StringEncoding];
            if([key isEqualToString:@"-f"]) {
                type = 1;
                continue;;
            }else if ([key isEqualToString:@"-b"]){
                type = 2;
                continue;
            }else if ([key isEqualToString:@"-d"]){
                type = 3;
                continue;
            }else if ([key isEqualToString:@"-t"]){
                type = 4;
                continue;
            }
            if(type == 1){
                [filterKeys addObject:key];
            }else if (type == 2){
                [blockKeys addObject:key];
            }else if (type == 3){
                deviceID = key;
            }else if (type == 4){
                serviceType = [key intValue];
            }
        }
        _logServer = [[YCLogServer alloc] init];
        _logServer.filterKeys = filterKeys.copy;
        _logServer.blockKeys = blockKeys.copy;
        _logServer.deviceId = deviceID;
        _logServer.type = serviceType;
        [_logServer createServer];
        
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop run];
    }
    return 0;
}

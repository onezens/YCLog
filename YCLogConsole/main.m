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
        int type = -1;
        for(int i=1; i<argc; i++){
            NSString *key = [NSString stringWithCString: argv[i] encoding:NSUTF8StringEncoding];
            if([key isEqualToString:@"-f"]) {
                type = 1;
                continue;;
            }else if ([key isEqualToString:@"-b"]){
                type = 2;
                continue;
            }
            if(type == 1){
                [filterKeys addObject:key];
            }else if (type == 2){
                [blockKeys addObject:key];
            }
        }
        _logServer = [[YCLogServer alloc] init];
        _logServer.filterKeys = filterKeys.copy;
        _logServer.blockKeys = blockKeys.copy;
        [_logServer createServer];
        
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop run];
    }
    return 0;
}

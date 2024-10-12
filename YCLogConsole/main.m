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

NSString *cachePath(void) {
    return [NSHomeDirectory() stringByAppendingPathComponent:@".config/YCLogConsole"];
}

NSString *configPath(void) {
    return [cachePath() stringByAppendingPathComponent:@"config.json"];
}

void saveParams(NSDictionary *params) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:configPath() atomically:true];
}


NSDictionary *loadCacheParams (void) {
    NSData *data = [NSData dataWithContentsOfFile:configPath()];
    if (!data) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:cachePath()]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath() withIntermediateDirectories:true attributes:nil error:nil];
        }
        _logServer = [[YCLogServer alloc] init];
        NSMutableDictionary *params = loadCacheParams().mutableCopy ? : @{}.mutableCopy;
        NSMutableArray *filterKeys = [NSMutableArray array];
        NSMutableArray *blockKeys = [NSMutableArray array];
        BOOL verbose = NO;
        int type = -1;
        for(int i=1; i<argc; i++){
            NSString *key = [NSString stringWithCString: argv[i] encoding:NSUTF8StringEncoding];
            if([key isEqualToString:@"-f"]) {
                type = 1;
                continue;;
            } else if ([key isEqualToString:@"-b"]){
                type = 2;
                continue;
            } else if ([key isEqualToString:@"-d"]){
                type = 3;
                continue;
            } else if ([key isEqualToString:@"-t"]){
                type = 4;
                continue;
            } else if ([key isEqualToString:@"-n"]){
                type = 5;
                continue;
            } else if ([key isEqualToString:@"-bt"]){
                type = 6;
                continue;
            } else if ([key isEqualToString:@"-v"]){
                verbose = YES;
                continue;
            }
            if (type == 1){
                [filterKeys addObject:key];
            } else if (type == 2){
                [blockKeys addObject:key];
            } else if (type == 3){
                params[@"_deviceId"] = key;
            } else if (type == 4){
                params[@"_type"] = key;
            } else if (type == 5){
                params[@"_bonjourName"] = key;
            } else if (type == 6){
                params[@"_bonjourTypeID"] = key;
            }
        }
        params[@"_filterKeys"] = filterKeys;
        params[@"_blockKeys"] = blockKeys;

        [_logServer setValuesForKeysWithDictionary:params];
        _logServer.verbose = verbose;
        [_logServer createServer];
        NSMutableDictionary *savedParams = params.mutableCopy;
        saveParams(savedParams);
        if (_logServer.verbose) {
            printf("[YCLogConsole] Start Params: %s \n", params.description.UTF8String);
        }
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop run];

    }
    return 0;
}


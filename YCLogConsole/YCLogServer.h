//
//  YCLogServer.h
//  YConsole
//
//  Created by wz on 2019/3/25.
//  Copyright © 2019 wz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YCLogServerType) {
    YCLogServerTypeDefault,
    YCLogServerTypeIP,
    YCLogServerTypeBonjour
};

@interface YCLogServer : NSObject
@property (nonatomic, strong) NSArray *filterKeys;
@property (nonatomic, strong) NSArray *blockKeys;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, assign) YCLogServerType type;


- (void)createServer;
@end

NS_ASSUME_NONNULL_END

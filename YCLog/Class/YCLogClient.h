//
//  YCLogClient.h
//  YCLog
//
//  Created by wz on 2019/3/22.
//  Copyright © 2019 wz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCLogConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    YCLogClientStatusDisConnecting,
    YCLogClientStatusConnecting,
    YCLogClientStatusConnected,
} YCLogClientStatus;

@interface YCLogClient : NSObject

@property (nonatomic, strong, readonly) YCLogConfig *config;
- (void)connectToServer;

- (void)sendMsg:(NSString *)msgContent;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithConfig:(YCLogConfig *)config;
@end
NS_ASSUME_NONNULL_END

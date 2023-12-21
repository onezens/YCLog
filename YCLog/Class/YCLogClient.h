//
//  YCLogClient.h
//  YCLog
//
//  Created by wz on 2023/10/16.
//


#import <YCLog/YCLogConfig.h>

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


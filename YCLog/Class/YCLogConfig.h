//
//  YCLogConfig.h
//  YCLog
//
//  Created by wz on 2023/10/17.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kRestfulLoggerId;

@interface YCLogConfig : NSObject

/// 日志服务链接超时时间，默认20s
@property (nonatomic, assign) NSInteger timeout;
/// 打印日志的队列，需要指定串行子队列。
@property (nonatomic, strong) dispatch_queue_t queue;
/// 手动打印日志的 host
@property (nonatomic, copy) NSString *logHost;
/// 禁用日志输出到 Xcode 控制台
@property (nonatomic, assign) BOOL disableLogConsole;
/// 存储路径
@property (nonatomic, copy) NSString *localLogPath;
/// 日志标识
@property (nonatomic, copy, readonly) NSString *logBonjourId;
///是否支持组播服务，局域网自动连接服务
@property (nonatomic, assign, readonly) BOOL supportBonjour;
///是否支持组播服务，局域网自动连接服务
+ (BOOL)supportBonjour;

@end

NS_ASSUME_NONNULL_END


//
//  YCLog+Exception.h
//  YCLog
//
//  Created by wz on 2023/12/21.
//

#import <YCLog/YCLog.h>

NS_ASSUME_NONNULL_BEGIN


void HandleException(NSException *exception) {
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    [YCLog logLevel:YCLogLevelError flag:YCLogFlagError tag:nil format:@"%@", exceptionInfo];
}

void InstallUncaughtExceptionHandler(void) {
    NSSetUncaughtExceptionHandler(&HandleException);
}


NS_ASSUME_NONNULL_END

//
//  YCLogClient.h
//  YCLog
//
//  Created by wz on 2019/3/22.
//  Copyright © 2019 wz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YCLogClient : NSObject
@property (nonatomic, assign) BOOL isConnected;

- (void)sendMsg:(NSData *)msgData;
@end

NS_ASSUME_NONNULL_END

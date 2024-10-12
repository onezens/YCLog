//
//  YCLogServer.m
//  YConsole
//
//  Created by wz on 2019/3/25.
//  Copyright © 2019 wz. All rights reserved.
//

#import "YCLogServer.h"
#import "GCDAsyncSocket.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

#define YCLogServerEnableDebugLog 1

static NSInteger kYCLogServerPort = 46666;
static NSString * kYCLogBonjourType = @"YCLogConsole";
//static NSString * kYCLogBonjourType = @"MSVRestfulLog";

@interface YCLogServer()<NSNetServiceDelegate, GCDAsyncSocketDelegate>
@property (nonatomic, strong) NSMutableArray *clients;
@property (nonatomic, strong) NSNetService *bonjourServer;
@property (nonatomic, copy, readonly) NSString *bonjourType;
@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;
@property (nonatomic, strong) GCDAsyncSocket *ipHostSocket;
@end

@implementation YCLogServer

- (instancetype)init {
    if (self = [super init]) {
        _bonjourName = kYCLogBonjourType;
        _bonjourTypeID = kYCLogBonjourType;
    }
    return self;
}

- (void)createServer {
    if (self.deviceId.length) {
        self.bonjourName = self.deviceId;
    }
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    if (self.type != YCLogServerTypeIP && [_asyncSocket acceptOnPort:0 error:&err]) {
        _clients = [NSMutableArray array];
        _bonjourServer = [[NSNetService alloc] initWithDomain:@"local."
                                                         type:self.bonjourType
                                                         name:self.bonjourName
                                                         port:_asyncSocket.localPort];
        
        _bonjourServer.delegate = self;
        _bonjourServer.includesPeerToPeer = true;
        [_bonjourServer publish];
    }
    
    if (self.type != YCLogServerTypeBonjour) {
        _ipHostSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_ipHostSocket acceptOnPort:kYCLogServerPort error:&err];
    }
    [self serverIP];
    NSString *filterKeys = self.filterKeys.count > 0 ? [self.filterKeys componentsJoinedByString:@"、"] : @"null";
    NSString *blockKeys = self.blockKeys.count > 0 ? [self.blockKeys componentsJoinedByString:@"、"] : @"null";
    printf("[YCLogConsole] YCLogServer Started, Filter Keys: %s, Block Keys: %s \n", filterKeys.UTF8String, blockKeys.UTF8String);

}

- (NSString *)bonjourType
{
    return [NSString stringWithFormat:@"_%@._tcp.", self.bonjourTypeID];
}

- (void)serverIP
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSMutableArray *ipAddresses = [NSMutableArray array];
    
    // 获取网络接口信息
    if (getifaddrs(&interfaces) == 0) {
        // 遍历接口列表
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if (sa_type == AF_INET || sa_type == AF_INET6) {
                // 获取 IP 地址
                NSString *ipAddress = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                NSString *name = [NSString stringWithUTF8String:(const char *)(struct sockaddr_in *)temp_addr->ifa_name];
                if (![ipAddress isEqualToString:@"0.0.0.0"] && ![ipAddress isEqualToString:@"127.0.0.1"] && [name hasPrefix:@"en"]) {
                    [ipAddresses addObject:[NSString stringWithFormat:@"%@: %@", name, ipAddress]];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // 释放资源
    freeifaddrs(interfaces);
    
    // 打印 IP 地址
    for (NSString *ipAddress in ipAddresses) {
        printf("%s \n", ipAddress.UTF8String);
    }
}

- (void)logLevel:(NSInteger)level flag:(NSInteger)flag function:(const char *)function line:(NSUInteger)line detail:(NSString *)detail {
    
}


#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
    NSInteger errorCode = [[errorDict valueForKey:@"NSNetServicesErrorCode"] integerValue];
    if (errorCode == -72001) {
        printf("[YCLogConsole] YCLogServer 自动连接广播发送失败，已有相同的广播。加上 -d <设备标识> 重新启动日志 \n[YCLogConsole] 错误详情 (注意：该错误不影响通过 IP 连接日志服务) Error: %s \n", errorDict.description.UTF8String);
    } else {
        printf("[YCLogConsole] YCLogServer publish error %s\n", errorDict.description.UTF8String);
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    
}

- (void)netServiceDidStop:(NSNetService *)sender {
    if (self.verbose) {
        printf("[YCLogConsole] YCLogServer stop publish error \n");
    }
}

- (void)netServiceDidPublish:(NSNetService *)ns
{
    NSString *srvTypeDesc = @"支持IP和自动连接";
    if (self.type == 1) {
        srvTypeDesc = @"仅支持IP连接";
    } else if (self.type == 2) {
        srvTypeDesc = @"仅支持自动连接";
    }
    printf("[YCLogConsole] YCLogServer Did Publish Port:%zd Type: %s \n", kYCLogServerPort, srvTypeDesc.UTF8String);
    printf("[YCLogConsole] Bonjour Type: %s Name: %s \n", self.bonjourType.UTF8String, self.bonjourName.UTF8String);
}

#pragma mark - data

- (NSData *)getConfigData
{
    NSDictionary *config = @{
        @"type": @"config",
        @"data" : @{
            @"filterKey": self.filterKeys,
            @"blockKey": self.blockKeys
        }
    };
    return [NSJSONSerialization dataWithJSONObject:config options:0 error:nil];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    printf("[YCLogConsole] didAcceptNewSocket %s \n", newSocket.description.UTF8String);
    [self.clients addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:0];
    NSData *data = [self getConfigData];
    if(!data) return;
    [newSocket writeData:data withTimeout:-1 tag:10];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error{
    [_clients removeObject:socket];
    printf("[YCLogConsole] socketDidDisconnect %s error: %s\n", socket.description.UTF8String, error.description.UTF8String);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [sock readDataWithTimeout:-1 tag:0];
    [self printMessage:text];
}

- (void)printMessage:(NSString *)msg
{
    NSString *result = msg;
    // 打印客户端日志
    printf("%s", result.UTF8String);
}
@end

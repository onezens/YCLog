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
@interface YCLogServer()<NSNetServiceDelegate, GCDAsyncSocketDelegate>
@property (nonatomic, strong) NSMutableArray *clients;
@property (nonatomic, strong) NSNetService *bonjourServer;
@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;
@property (nonatomic, strong) GCDAsyncSocket *ipHostSocket;
@end

@implementation YCLogServer



- (void)createServer {
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    if (self.type != YCLogServerTypeIP && [_asyncSocket acceptOnPort:0 error:&err]) {
        _clients = [NSMutableArray array];
        _bonjourServer = [[NSNetService alloc] initWithDomain:@"local."
                                                         type:[self bonjourType]
                                                         name:[self bonjourName]
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
}

- (NSString *)bonjourType
{
    return @"_MSVRestfulLog._tcp.";
}

- (NSString *)bonjourName
{
    return _deviceId.length ? _deviceId : @"MSVRestfulLog";
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
#if YCLogServerEnableDebugLog
    printf("[YCLogConsole] YCLogServer publish error %s\n", errorDict.description.UTF8String);
#endif
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    
}

- (void)netServiceDidStop:(NSNetService *)sender {
#if YCLogServerEnableDebugLog
    printf("[YCLogConsole] YCLogServer stop publish error \n");
#endif
}

- (void)netServiceDidPublish:(NSNetService *)ns
{
    printf("[YCLogConsole] YCLogServer publish port:%zd \nfilterKeys: %s blockKeys: %s\n", kYCLogServerPort, [self.filterKeys componentsJoinedByString:@"、"].UTF8String, [self.blockKeys componentsJoinedByString:@"、"].UTF8String);
    printf("bonjour type: %s name: %s srvType: %ld\n", [self bonjourType].UTF8String, [self bonjourName].UTF8String, self.type);
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
#if YCLogServerEnableDebugLog
    printf("[YCLogConsole] didAcceptNewSocket %s \n", newSocket.description.UTF8String);
#endif
    [self.clients addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:0];
    NSData *data = [self getConfigData];
    if(!data) return;
    [newSocket writeData:data withTimeout:-1 tag:10];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error{
    [_clients removeObject:socket];
#if YCLogServerEnableDebugLog
    printf("[YCLogConsole] socketDidDisconnect %s error: %s\n", socket.description.UTF8String, error.description.UTF8String);
#endif
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [sock readDataWithTimeout:-1 tag:0];
    // 打印客户端日志
    printf("%s", text.UTF8String);
}
@end

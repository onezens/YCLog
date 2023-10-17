//
//  YCLogServer.m
//  YConsole
//
//  Created by wz on 2019/3/25.
//  Copyright © 2019 wz. All rights reserved.
//

#import "YCLogServer.h"
#import "GCDAsyncSocket.h"

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
    _ipHostSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    if ([_asyncSocket acceptOnPort:0 error:&err]) {
        _clients = [NSMutableArray array];
        _bonjourServer = [[NSNetService alloc] initWithDomain:@"local."
                                                         type:@"_YCLog._tcp."
                                                         name:@"YCLogBonjour"
                                                         port:_asyncSocket.localPort];
        
        _bonjourServer.delegate = self;
        _bonjourServer.includesPeerToPeer = true;
        [_bonjourServer publish];
    }
    
    if ([_ipHostSocket acceptOnPort:kYCLogServerPort error:&err]) { }
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

//
//  YCLogServer.m
//  YConsole
//
//  Created by wz on 2019/3/25.
//  Copyright © 2019 wz. All rights reserved.
//

#import "YCLogServer.h"
#import "GCDAsyncSocket.h"

@interface YCLogServer()<NSNetServiceDelegate, GCDAsyncSocketDelegate>
@property (nonatomic, strong) NSMutableArray *clients;
@property (nonatomic, strong) NSNetService *bonjourServer;
@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;
@end

@implementation YCLogServer

- (void)createServer {
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    if ([_asyncSocket acceptOnPort:0 error:&err]) {
        _clients = [NSMutableArray array];
        _bonjourServer = [[NSNetService alloc] initWithDomain:@"local."
                                                         type:@"_YCLogBonjour._tcp."
                                                         name:@"YCLogBonjour"
                                                         port:_asyncSocket.localPort];
        
        _bonjourServer.delegate = self;
        _bonjourServer.includesPeerToPeer = true;
        [_bonjourServer publish];
    }
}

- (void)logLevel:(NSInteger)level flag:(NSInteger)flag function:(const char *)function line:(NSUInteger)line detail:(NSString *)detail {
    
}


#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
    printf("YCLogServer publish error %s\n", errorDict.description.UTF8String);
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {

}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict {

}

- (void)netServiceDidStop:(NSNetService *)sender {
    printf("YCLogServer stop publish error \n");
}

- (void)netServiceDidPublish:(NSNetService *)ns
{
    printf("YCLogServer publish  \n");
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [self.clients addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error{
    [_clients removeObject:socket];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [sock readDataWithTimeout:-1 tag:0];
    printf("%s", text.UTF8String);
}
@end

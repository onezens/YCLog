//
//  YCLogClient.m
//  YCLog
//
//  Created by wz on 2019/3/22.
//  Copyright © 2019 wz. All rights reserved.
//

#define kConnectTimeOut 20

#import "YCLogClient.h"
#import "GCDAsyncSocket.h"

@interface YCLogClient()<NSNetServiceBrowserDelegate , NSNetServiceDelegate, GCDAsyncSocketDelegate>
@property (nonatomic, strong) NSNetServiceBrowser *bonjourClient;
@property (nonatomic, strong) NSMutableArray <NSNetService *> *bonjourServers;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSArray <NSData *> *addresses;
@property (nonatomic, assign) BOOL isConnected;
@end


@implementation YCLogClient

- (instancetype)init {
    if (self = [super init]) {
        [self createClient];
    }
    return self;
}

- (BOOL)createClient {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self->_bonjourClient = [[NSNetServiceBrowser alloc] init];
        [self->_bonjourClient setDelegate:self];
        [self->_bonjourClient searchForServicesOfType:@"_YCLogBonjour._tcp." inDomain:@"local."];
        self->_bonjourServers = [NSMutableArray array];
        self->_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    });
    return true;
}


- (void)sendMsg:(NSData *)msgData {
    if (self.addresses.count==0) {
        NSLog(@"need retry search");
        return;
    }
    if (!self.isConnected) {
        [self connectToServer];
    }
    if (self.socket) {
        [self.socket writeData:msgData withTimeout:kConnectTimeOut tag:1001];
    }else{
        NSLog(@"socket send msg error");
    }
}

- (void)connectToServer {
    if (self.addresses.count==0) {
        NSLog(@"searched server address empty!");
        return;
    }
    NSError *err = nil;
    [_socket connectToAddress:self.addresses.firstObject error:&err];
    if (err) {
        NSLog(@"connect server socket error");
    }else{
        NSLog(@"connect server socket success");
    }
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser {
    NSLog(@"%s", __func__);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser {
    NSLog(@"%s", __func__);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    NSLog(@"%s", __func__);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    NSLog(@"%s", __func__);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    if (service) {
        [self.bonjourServers addObject:service];
        [service setDelegate:self];
        [service resolveWithTimeout:20];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    NSLog(@"%s", __func__);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    NSLog(@"%s", __func__);
    self.addresses = nil;
}

#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    NSLog(@"%s", __func__);
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"bonjour server name: %@, hostname: %@, port:  %zd ",sender.name, sender.hostName, sender.port);
    self.addresses = sender.addresses;
    [self connectToServer];
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    NSLog(@"%s", __func__);
}

- (void)netServiceDidStop:(NSNetService *)sender {
    if (sender) {
        [self.bonjourServers removeObject:sender];
    }
}


#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [sock readDataWithTimeout:kConnectTimeOut tag:1000];
    self.isConnected = true;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"%s", __func__);
    //TODO:retry connect
    self.isConnected = false;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[Client] Received: %@", text);
    text = [text stringByAppendingString:@"\n"];
    [sock readDataWithTimeout:-1 tag:0];
}

@end

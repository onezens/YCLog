//
//  YCLogClient.m
//  YCLog
//
//  Created by wz on 2019/3/22.
//  Copyright © 2019 wz. All rights reserved.
//

#import "YCLogClient.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

#define YCLogEnableDebugLog 1

@interface YCLogClient() <NSNetServiceBrowserDelegate , NSNetServiceDelegate, GCDAsyncSocketDelegate>

@property (nonatomic, strong) NSNetServiceBrowser *bonjourClient;
@property (nonatomic, strong) NSMutableArray <NSNetService *> *bonjourServers;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSArray <NSData *> *addresses;
@property (nonatomic, strong) NSMutableArray <NSString *> *logQueue;
@property (nonatomic, strong) NSFileHandle *fh;
@property (nonatomic, copy) NSString *logPath;
@property (nonatomic, assign) YCLogClientStatus status;
@property (nonatomic, assign) NSInteger addressIdx;
@property (nonatomic, strong) NSArray <NSString *> *filterKeys;
@property (nonatomic, strong) NSArray <NSString *> *blockKeys;

@end


@implementation YCLogClient

- (instancetype)initWithConfig:(YCLogConfig *)config
{
    if (self = [super init]) {
        _config = config;
        _logPath = config.localLogPath;
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:config.queue];
        [self initLogQueueWithThreadQueue:config.queue];
    }
    return self;
}

- (void)startBonjourService
{
    if (self.config.logHost.length > 0) {
        return;
    }
    self.bonjourClient = [[NSNetServiceBrowser alloc] init];
    [self.bonjourClient scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self.bonjourClient setDelegate:self];
    self.bonjourClient.includesPeerToPeer = true;
    [self.bonjourClient searchForServicesOfType:self.config.logBonjourId inDomain:@"local."];
    self.bonjourServers = [NSMutableArray array];
}

- (void)initLogQueueWithThreadQueue:(dispatch_queue_t)queue
{
    dispatch_async(queue, ^{
        NSMutableArray *logQueue = [NSMutableArray array];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];
        NSString *dateStr = [df stringFromDate:[NSDate date]];
        NSString *initLog = @"";
        initLog = [initLog stringByAppendingFormat:@"\n\n**************************************************************************************\n"];
        initLog = [initLog stringByAppendingFormat:@" %@ v1.0.1 Init: %@\n", kRestfulLoggerId, dateStr];
        initLog = [initLog stringByAppendingFormat:@" Sandbox Log Path: %@\n", [self logPath]];
        initLog = [initLog stringByAppendingFormat:@"**************************************************************************************\n"];
        [logQueue addObject:initLog];
        NSData *data = [initLog dataUsingEncoding:NSUTF8StringEncoding];
        [self logLocal:data];
        self.logQueue = logQueue;
        if (self.config.supportBonjour) {
            [self startBonjourService];
        }
    });
}


- (void)sendMsg:(NSString *)msgContent;
{
    NSData *msgData = [msgContent dataUsingEncoding:NSUTF8StringEncoding];
    [self logLocal:msgData];
    BOOL canLog = [self canLogMsg:msgContent];
    if (self.status != YCLogClientStatusConnected) {
        [self connectToServer];
        if(canLog) [self.logQueue addObject:msgContent];
        return;
    }
    if(canLog) {
        [self.socket writeData:msgData withTimeout:self.config.timeout tag:1001];
    }
}

- (BOOL)canLogMsg:(NSString *)msg
{
    if ([msg containsString:@"Sandbox Log Path"])  return true;
    BOOL can = [self checkFilterWithMsg:msg];
    can = can && ![self isBlockMsg:msg];
    return can;
}

- (BOOL)checkFilterWithMsg:(NSString *)msg
{
    if(!self.filterKeys.count) return true;
    for (NSString *key in self.filterKeys) {
        if([key containsString:@"&"]){
            NSArray *keys = [key componentsSeparatedByString:@"&"];
            for (NSString *andKey in keys) {
                if(![msg containsString:andKey]){
                    return false;
                }
            }
            return true;
        }
        if([msg containsString:key]) {
            return true;
        }
    }
    return false;
}

- (BOOL)isBlockMsg:(NSString *)msg
{
    for (NSString *key in self.blockKeys) {
        if([msg containsString:key]){
            return true;
        }
    }
    return false;
}

- (void)connectToServer
{
    NSError *err = nil;
    if (self.config.logHost.length > 0) {
        if (self.status != YCLogClientStatusDisConnecting) {
            return;
        }
        self.status = YCLogClientStatusConnecting;
        BOOL isConnect = [_socket connectToHost:self.config.logHost onPort:46666 error:&err];
        if (!isConnect || err != nil) {
#if YCLogEnableDebugLog
            printf("[YCLogConsole] [connectToServer1] error: %s\n", err.description.UTF8String);
#endif
        }
    }else {
        if (self.addresses.count == 0) {
            return;
        }
        if (self.status != YCLogClientStatusDisConnecting) {
            return;
        }
        self.status = YCLogClientStatusConnecting;
        // 链接超时后，换一个新的地址重连
        BOOL isConnect = [_socket connectToAddress:self.addresses[self.addressIdx] withTimeout:2 error:&err];
#if YCLogEnableDebugLog
        printf("[YCLogConsole]  connectToAddress \n");
        if (!isConnect || err != nil) {
            printf("[YCLogConsole] [connectToServer] error: %s\n", err.description.UTF8String);
        }
#endif
    }
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict {
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    dispatch_async(self.config.queue, ^{
        if (service) {
            [self.bonjourServers addObject:service];
            [service setDelegate:self];
            [service resolveWithTimeout:20];
        }
    });
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    self.addresses = nil;
}

#pragma mark - NSNetServiceDelegate


- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    dispatch_async(self.config.queue, ^{
#if YCLogEnableDebugLog
        printf("[YCLogConsole]  DidResolveAddress name: %s  host: %s domain: %s type: %s port: %zd \n", sender.name.UTF8String, sender.hostName.UTF8String, sender.domain.UTF8String, sender.type.UTF8String, sender.port);
#endif
    //    [sender.addresses enumerateObjectsUsingBlock:^(NSData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    //        NSLog(@"address: %@", [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding]);
    //    }];
        self.addressIdx = 0;
        self.addresses = sender.addresses.copy;
        [self connectToServer];
        //    [self.bonjourClient removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    });
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
#if YCLogEnableDebugLog
    printf("[YCLogConsole]  didNotResolve %s \n", errorDict.description.UTF8String);
#endif
}

- (void)netServiceDidStop:(NSNetService *)sender {
    
    dispatch_async(self.config.queue, ^{
        if (sender) {
            [self.bonjourServers removeObject:sender];
        }
#if YCLogEnableDebugLog
        printf("[YCLogConsole]  netServiceDidStop \n");
#endif
    });
}


#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
#if YCLogEnableDebugLog
    printf("[YCLogConsole]  didConnectToHost: %s port: %d \n", host.UTF8String, port);
#endif
    [sock readDataWithTimeout:self.config.timeout tag:10];
    self.status = YCLogClientStatusConnected;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    //TODO:retry connect
    self.status = YCLogClientStatusDisConnecting;
    self.addressIdx += 1;
    if (self.addressIdx >= self.addresses.count) {
        self.addressIdx = 0;
    }
    //TODO: handler max retry time
    if (err.code == 3) {
        // Error Domain=GCDAsyncSocketErrorDomain Code=3 "Attempt to connect to host timed out" UserInfo={NSLocalizedDescription=Attempt to connect to host timed out}
        [self connectToServer];
    }
#if YCLogEnableDebugLog
    printf("[YCLogConsole]  Disconnect: %s \n", err.description.UTF8String);
#endif
    self.addresses = nil;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [self handlerSocketMsg:data];
    [sock readDataWithTimeout:-1 tag:tag];
}

- (void)handlerSocketMsg:(NSData *)msg
{
    if(msg){
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:msg options:0 error:nil];
        if([dict isKindOfClass:NSDictionary.class]){
            NSString *type = [dict valueForKey:@"type"];
            if([type isEqualToString:@"config"]){
                NSDictionary *data = dict[@"data"];
                self.filterKeys = [data valueForKey:@"filterKey"];
                self.blockKeys = [data valueForKey:@"blockKey"];
            }
        }
    }
    // send log queue msg to log server
    if (self.logQueue.count > 0) {
        NSArray *pendingLogs = self.logQueue.copy;
        [self.logQueue removeAllObjects];
        [pendingLogs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self sendMsg:obj];
        }];
    }
}

#pragma mark - log file

- (void)logLocal:(NSData *)log
{
    if (_logPath) {
        [self logInfoToFile:log path:_logPath];
    }
}

- (void)logInfoToFile:(NSData *)log path:(NSString *)path
{
    NSAssert(![NSThread isMainThread], @"log to file can not main thread!");
    NSFileHandle *fh = self.fh;
    if (!fh) {
        fh = [NSFileHandle fileHandleForWritingAtPath:path];
        [fh seekToEndOfFile];
    }
    [fh writeData:log];
}


@end



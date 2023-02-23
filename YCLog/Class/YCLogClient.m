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

typedef enum : NSUInteger {
    YCLogClientDisConnect,
    YCLogClientConnecting,
    YCLogClientConnected,
} YCLogClientStatus;

@interface YCLogClient()<NSNetServiceBrowserDelegate , NSNetServiceDelegate, GCDAsyncSocketDelegate>
@property (nonatomic, strong) NSNetServiceBrowser *bonjourClient;
@property (nonatomic, strong) NSMutableArray <NSNetService *> *bonjourServers;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSArray <NSData *> *addresses;
@property (nonatomic, strong) NSMutableArray <NSString *> *logQueue;
@property (nonatomic, strong) NSFileHandle *fh;
@property (nonatomic, copy) NSString *logPath;
@property (nonatomic, strong) dispatch_queue_t clientQueue;
@property (nonatomic, assign) YCLogClientStatus status;
@property (nonatomic, assign) NSInteger addressIdx;
@property (nonatomic, strong) NSArray <NSString *> *filterKeys;
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
        [self initClient];
    });
    return true;
}

- (void)initClient
{
    self.clientQueue = dispatch_queue_create("YCLog.client", DISPATCH_QUEUE_SERIAL);
    self.bonjourClient = [[NSNetServiceBrowser alloc] init];
    [self.bonjourClient scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self.bonjourClient setDelegate:self];
    self.bonjourClient.includesPeerToPeer = true;
    [self.bonjourClient searchForServicesOfType:@"_YCLogBonjour._tcp." inDomain:@"local."];
    self.bonjourServers = [NSMutableArray array];
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.clientQueue];
    [self initLogQueue];
}

- (void)initLogQueue
{
    dispatch_async(self.clientQueue, ^{
        NSMutableArray *logQueue = [NSMutableArray array];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];
        NSString *dateStr = [df stringFromDate:[NSDate date]];
        NSString *initLog = @"";
        initLog = [initLog stringByAppendingFormat:@"\n\n**************************************************************************************\n"];
        initLog = [initLog stringByAppendingFormat:@" YCLog v1.0.1 Init: %@\n", dateStr];
        initLog = [initLog stringByAppendingFormat:@" Sandbox Log Path: %@\n", [self getLocalPhonePath]];
        initLog = [initLog stringByAppendingFormat:@"**************************************************************************************\n"];
        [logQueue addObject:initLog];
        NSData *data = [initLog dataUsingEncoding:NSUTF8StringEncoding];
        [self logIphone:data];
        self.logQueue = logQueue;
    });
}


- (void)sendMsg:(NSString *)msgContent;
{
    dispatch_async(self.clientQueue, ^{
        NSData *msgData = [msgContent dataUsingEncoding:NSUTF8StringEncoding];
        [self logIphone:msgData];
        BOOL canLog = [self checkFilterWithMsg:msgContent];
        if (self.status != YCLogClientConnected) {
            [self connectToServer];
            if(canLog) [self.logQueue addObject:msgContent];
            return;
        }
        if(canLog) {
            [self.socket writeData:msgData withTimeout:kConnectTimeOut tag:1001];
        }
    });
}

- (BOOL)checkFilterWithMsg:(NSString *)msg
{
    if(!self.filterKeys.count) return true;
    for (NSString *key in self.filterKeys) {
        if([msg containsString:key]) {
            return true;
        }
    }
    return false;
}

- (void)connectToServer
{
    if (self.addresses.count==0) {
        return;
    }
    if (self.status != YCLogClientDisConnect) return;
    self.status = YCLogClientConnecting;
    NSError *err = nil;
    // 链接超时后，换一个新的地址重连
    BOOL isConnect = [_socket connectToAddress:self.addresses[self.addressIdx] withTimeout:2 error:&err];
    if (!isConnect || err != nil) {
        NSLog(@"[connectToServer] error: %@", err);
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
    if (service) {
        [self.bonjourServers addObject:service];
        [service setDelegate:self];
        [service resolveWithTimeout:20];
    }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    self.addresses = nil;
}

#pragma mark - NSNetServiceDelegate


- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"name: %@  host: %@ domain: %@ type: %@ port: %zd", sender.name, sender.hostName, sender.domain, sender.type, sender.port);
    [sender.addresses enumerateObjectsUsingBlock:^(NSData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"address: %@", [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding]);
    }];
    self.addresses = sender.addresses.copy;
    [self connectToServer];
//    [self.bonjourClient removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict {
}

- (void)netServiceDidStop:(NSNetService *)sender {
    if (sender) {
        [self.bonjourServers removeObject:sender];
    }
}


#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [sock readDataWithTimeout:kConnectTimeOut tag:1000];
    self.status = YCLogClientConnected;
    if (self.logQueue.count > 0) {
        NSArray *pendingLogs = self.logQueue.copy;
        [self.logQueue removeAllObjects];
        [pendingLogs enumerateObjectsUsingBlock:^(NSData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self sendMsg:obj];
        }];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    //TODO:retry connect
    self.status = YCLogClientDisConnect;
    self.addressIdx += 1;
    if (self.addressIdx >= self.addresses.count) {
        self.addressIdx = 0;
    }
    //TODO: handler max retry time
    if (err.code == 3) { //Error Domain=GCDAsyncSocketErrorDomain Code=3 "Attempt to connect to host timed out" UserInfo={NSLocalizedDescription=Attempt to connect to host timed out}
        [self connectToServer];
    }
    
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"socket read data: %@  tag: %zd", text, tag);
    [self handlerSocketMsg:data];
    [sock readDataWithTimeout:-1 tag:tag];
}

- (void)handlerSocketMsg:(NSData *)msg
{
    if(!msg.length) return;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:msg options:0 error:nil];
    if([dict isKindOfClass:NSDictionary.class]){
        NSString *type = [dict valueForKey:@"type"];
        if([type isEqualToString:@"config"]){
            NSDictionary *data = dict[@"data"];
            self.filterKeys = [data valueForKey:@"filterKey"];
        }
    }
}

#pragma mark - log file

- (NSString *)getLocalPhonePath
{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    path = [path stringByAppendingPathComponent:@"YCLog"];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM-dd"];
    NSString *dateStr = [df stringFromDate:[NSDate date]];
    NSString *logfile = [path stringByAppendingFormat:@"/%@.log",dateStr];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
        [[NSFileManager defaultManager] createFileAtPath:logfile contents:nil attributes:nil];
    }
    return logfile;
}

- (void)logIphone:(NSData *)log
{
    if (!_logPath) {
        _logPath = [self getLocalPhonePath];
    }
    [self logInfoToFile:log path:_logPath];
    
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

# YCLog
iOS 轻量级彩色终端日志系统。采用了BS架构设计，包含了日志服务端和日志客户端，客户端日志可以集成到APP项目中，服务端日志需要手动编译和安装

## 安装服务端

下载源码，编译 YCLogConsole 为二进制可执行文件，然后把他放到 /usr/local/bin/ 路径下，或者其他的 $PATH 路径里面。最后在终端执行 YCLogConsole 命令，启动日志服务端。

```
# 显示所有日志
$ YCLogConsole

# 只展示包含 debug 或 info关键字的日志
$ YCLogConsole -f debug info

# 只展示包含 debug 且 info关键字的日志
$ YCLogConsole -f 'debug&info'

# 不展示包含 debug 或 info关键字的日志
$ YCLogConsole -b debug info

# 根据设备标识，查看日志。需要在日志客户端设置设备标识
$ YCLogConsole -d 81201006352934AC0201

# 指定日志标识，启动日志
$ YCLogConsole -n DDLogSrv
```

## 客户端使用日志

```
YCLogConfig *config = [YCLogConfig new];
config.localLogPath = [self logPath];
config.logHost = @"192.168.2.2"; // 日志服务端的IP地址，需要确保局域网内可互相访问到
config.deviceId = @"81201006352934AC0201";  // 指定设备标识、如果同一局域网有多个用户使用时，推荐指定设备标识
[[YCLog shared] setup:config];

```

## 打印日志

```
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event 
{
    YCLogError(@"error");
    YCLogWarn(@"warn");
    YCLogInfo(@"info");
    YCLogDebug(@"debug");
    [self sendRequest];
}

- (void)sendRequest
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:@"http://api.onezen.cc/v1/video/list?page=1&size=1"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            YCLogError(@"[sendRequest] error: %@",error);
            return;
        }
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        YCLogInfo(@"[sendRequest] success result: %@", obj);
    }];
    [task resume];
}

```

## Terminal 展示效果
![https://github.com/onezens/StorageCenter/blob/main/images/yclog.png?raw=true
](https://github.com/onezens/StorageCenter/blob/main/images/yclog.png?raw=true)



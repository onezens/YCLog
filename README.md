# YCLog
iOS simply terminal color log

## MacOS Install
Compile the YCLogConsole binary file, then put it in /usr/local/bin/ or other $PATH directory of your computer, and finally execute YCLogConsole in the terminal

```
# show all log
$ YCLogConsole

# Only show logs containing debug or info keywords
$ YCLogConsole -f debug info

# Only show logs containing debug & info keywords
$ YCLogConsole -f 'debug&info'

# Block logs containing the debug or info keywords
$ YCLogConsole -b debug info

# Connection log based on device ID
$ YCLogConsole -d 000081201006352934AC0201

# Custom device connection identifier
$ YCLogConsole -n DDLogSrv
```

## Output log

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

## Terminal 
![https://github.com/onezens/StorageCenter/blob/main/images/yclog.png?raw=true
](https://github.com/onezens/StorageCenter/blob/main/images/yclog.png?raw=true)



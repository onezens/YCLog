# YCLog
iOS simply terminal color log

## MacOS Install
Compile YCLogConsole, then put it in the /usr/local/bin/ directory of your computer, and finally execute YCLogConsole in the terminal

```
# show all log
$ YCLogConsole

# show filter log
$ YCLogConsole -f debug info

# show filter debug & info log
$ YCLogConsole -f 'debug&info'

# block log
$ YCLogConsole -b debug info
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



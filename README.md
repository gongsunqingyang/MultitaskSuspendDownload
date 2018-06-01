# 1.前言

> iOS开发中断点下载功能很常见，网上也有很多框架，本文选择了原生的`NSURLSession`和`NSFileHandle`，实现了多任务、大文件的断点下载，保证了较低的内存占用。

# 2.预览
* * *
![image](http://upload-images.jianshu.io/upload_images/3276250-e3ef598c35591775?imageMogr2/auto-orient/strip)

# 3.设计思路
* * *
* #### 断点下载方案：
`NSMutableData ` _如果文件很大会出现内存警告_
`NSURLConnection` _iOS9之后弃用，没有暂停的方法_
`NSURLSession` _推荐_
将下载记录保存到plist，重启应用时就能拿到下载记录，从而继续下载。

* #### 文件存储方案：
`NSMutableData` _如果文件很大会出现内存警告_
`NSOutputStream` _推荐_
`NSFileHandle` _推荐_
实际使用发现`NSOutputSteam`和`NSFileHandle`差别不大，但要注意不再写入时需要调用`close`方法。
内存占用：
![屏幕快照 2018-06-01 上午11.36.50.png](https://upload-images.jianshu.io/upload_images/3276250-e802600ffaebe9a4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


* #### 多任务
创建下载任务时我们采用了`NSURLSessionDataTask`，它是`NSURLSessionTask`的子类，其拥有只读属性taskIdentifier，若要将其作为任务的唯一标识符需要利用KVC。这里我们没有这么做，而是创建了`NSURLSession`的分类，为其添加了taskKey属性作为任务的为一标识符。创建任务时将传入的URL的MD5值作为key，并将其作查询下载任务、本地文件缓存、下载记录的为一索引。

# 4.代码
* * *
* #### 文件结构
创建下载管理者类`MYDownloadManager`，考虑到会在多个地方调用下载功能，所以将其设计为单例模式。管理者拥有多个下载任务，每个任务有其唯一的key，所以创建一个保存着多个任务的字典。
```
@interface MYDownloadManager ()<NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableDictionary *downloadDict;    // {Key : md5, Value : <MYDonwload *>}
@end
```
创建下载类
```
@interface MYDownload : NSObject
@property (nonatomic, copy) NSString *url;                  // 下载地址
@property (nonatomic, assign) long long downloadedLength;   // 已下载大小
@property (nonatomic, assign) long long totalLength;        // 总大小
@property (nonatomic, strong) NSURLSessionDataTask *task;   // 任务
@property (nonatomic, strong) NSFileHandle *fileHandle;     // 文件句柄
@property (nonatomic, copy) ProgressBlock progressBlock;    // 下载进度回调
@property (nonatomic, copy) StateBlock stateBlock;          // 下载状态回调
@end
```
下载记录`Download.plist`结构
![屏幕快照 2018-06-01 下午4.31.13.png](https://upload-images.jianshu.io/upload_images/3276250-9de50c9c540677d9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* #### 开始、恢复下载
我们要从上次结束的位置开始下载，所以需要设置请求头，下载指定范围的文件，设置规则如下：
>表示头500个字节：Range: bytes=0-499
表示第二个500字节：Range: bytes=500-999
表示最后500个字节：Range: bytes=-500
表示500字节以后的范围：Range: bytes=500-
同时指定几个范围：Range: bytes=100-199,400-500



```
- (void)downloadWithUrl:(NSString *)url resume:(BOOL)resume progress:(ProgressBlock)progressBlock state:(StateBlock)stateBlock {
if (!url.length) {
return;
}

// 将url的md5值作为key
NSString *key = [url md5];
long long totalLength = [self getTotalLengthWithKey:key];
long long downloadedLength = [self getDownloadedLengthWithKey:key];

// 任务已完成
if (totalLength == downloadedLength && totalLength > 0) {
if (progressBlock) {
progressBlock(1.0, downloadedLength, totalLength);
}
if (stateBlock) {
stateBlock(MYDownloadStateComplete);
}
}

// 查询任务是否存在
MYDownload *download = [self.downloadDict valueForKey:key];
if (download) {

// 取出下载任务
if (resume) {
[download.task resume];
} else {
[download.task suspend];
if (download.stateBlock) {
download.stateBlock(MYDownloadStateSuspend);
}
}
} else {

// 创建下载任务
NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];

NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
NSString *rangeValue = [NSString stringWithFormat:@"bytes=%lld-", downloadedLength];
[request setValue:rangeValue forHTTPHeaderField:@"Range"];

NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
task.taskKey = key;
task.url = url;

if (resume) {
[task resume];
}

// 创建并保存下载对象
download = [MYDownload new];
download.url = url;
download.task = task;
download.progressBlock = progressBlock;
download.stateBlock = stateBlock;
[self.downloadDict setValue:download forKey:key];
}
}
```
* #### 实现代理方法`NSURLSessionDataDelegate`
根据dataTask的taskKey可以得到当前下载对象，从服务器返回的response我们可以得到任务的总大小。开辟缓存文件，创建文件句柄准备写入文件，保存下载记录到plist。

```
// 收到服务器相应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
NSString *key = dataTask.taskKey;
NSString *url = dataTask.url;
NSString *filePath = [self getDownloadedPathWithFileName:response.suggestedFilename];

MYDownload *download = [self.downloadDict valueForKey:key];

// 计算总大小并保存到plist
long long expectedLength = response.expectedContentLength;
long long downloadedLength = [self getDownloadedLengthWithKey:key];
long long totalLength = expectedLength + downloadedLength;
if (totalLength == 0) {
if (download.progressBlock) {
download.progressBlock(0.f, downloadedLength, totalLength);
}
if (download.stateBlock) {
download.stateBlock(MYDownloadStateError);
}
return;
}
NSDictionary *dict = @{@"TotalLength" : @(totalLength),
@"Url" : url,
@"FileName" : response.suggestedFilename
};
[self setPlistValue:dict forKey:key];

// 创建NSFileHandle
NSFileManager *fileManager = [NSFileManager defaultManager];
if (![fileManager fileExistsAtPath:filePath]) {
[fileManager createFileAtPath:filePath contents:nil attributes:nil];
}
NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];

// 设置下载对象
download.totalLength = totalLength;
download.downloadedLength = downloadedLength;
download.fileHandle = fileHandle;

completionHandler(NSURLSessionResponseAllow);
}
```

开始接收数据，利用`NSFileHandle`将文件写入沙盒，不会导致内存占用过高。

```
// 收到数据（多次调用）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
NSString *key = dataTask.taskKey;

// 写数据
MYDownload *download = [self.downloadDict valueForKey:key];
if (download) {
[download.fileHandle seekToEndOfFile];
[download.fileHandle writeData:data];

download.downloadedLength += data.length;
CGFloat progress = (CGFloat) download.downloadedLength / download.totalLength;

if (download.progressBlock) {
download.progressBlock(progress, download.downloadedLength, download.totalLength);
}
if (download.stateBlock) {
download.stateBlock(MYDownloadStateDownloading);
}
}
}
```

任务完成、中止时关闭`NSFileHandle`，移除下载对象

```
// 任务完成、中止
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
NSString *key = task.taskKey;

// 关闭写数据流
MYDownload *download = [self.downloadDict valueForKey:key];
[download.fileHandle closeFile];
download.fileHandle = nil;

if (download.stateBlock) {
if (error) {
download.stateBlock(MYDownloadStateError);
} else {
download.stateBlock(MYDownloadStateComplete);
}
}

[self.downloadDict removeObjectForKey:key];
}
```

# 5.其他
* * *
* Git地址： **[MultitaskSuspendDownload](https://github.com/gongsunqingyang/MultitaskSuspendDownload)**


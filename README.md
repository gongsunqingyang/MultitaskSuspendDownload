## 简介
* iOS7 +
* 基于NSURLSession，实现了多任务断点下载。
* 文件读写采用NSFileHandle，保证了下载大文件时较低的内存占用。

## 使用
* 开始、暂停下载任务
```
- (void)downloadWithUrl:(NSString *)url resume:(BOOL)resume progress:(ProgressBlock)progressBlock state:(StateBlock)stateBlock;
```
* 获取任务记录
```
- (void)downloadWithUrl:(NSString *)url resume:(BOOL)resume progress:(ProgressBlock)progressBlock state:(StateBlock)stateBlock;
```
* 开始、暂停下载任务
```
- (NSMutableDictionary *)getPlist;
```
* 获取已下载大小
```
- (long long)getDownloadedLengthWithUrl:(NSString *)url;
```
* 移除单个文件
```
- (void)removeFileWithUrl:(NSString *)url;
```
* 移除所有文件
```
- (void)removeAllFile;
```

## 预览
![enter image description here](https://github.com/gongsunqingyang/MultitaskSuspendDownload/blob/master/Preview/Untitled.gif)

![enter image description here](https://github.com/gongsunqingyang/MultitaskSuspendDownload/blob/master/Preview/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202018-06-01%20%E4%B8%8A%E5%8D%8811.36.50.png)


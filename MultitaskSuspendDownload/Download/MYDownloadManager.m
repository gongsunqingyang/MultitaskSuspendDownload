//
//  MYDownloadManager.m
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/28.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import "MYDownloadManager.h"
#import "NSString+MD5.h"
#import "NSURLSessionTask+Extension.h"

@interface MYDownloadManager ()<NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableDictionary *downloadDict;    // 当前下载任务的字典（key:url, value:<MYDownload *>）

@end


@implementation MYDownloadManager

#pragma mark - Public
+ (instancetype)sharedManager{
    static MYDownloadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)downloadWithUrl:(NSString *)url resume:(BOOL)resume progress:(void (^)(CGFloat progress))progressBlock state:(void (^)(MYDownloadState state))stateBlock {
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
            progressBlock(1.0);
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
        download.key = key;
        download.url = url;
        download.task = task;
        download.progressBlock = progressBlock;
        download.stateBlock = stateBlock;
        [self.downloadDict setValue:download forKey:key];
    }
}

// 获取plist文件(如果没有则创建一个空的plist)
- (NSMutableDictionary *)getPlist {
    NSString *path = [self getPlistPath];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    return dict;
}

// 获取已下载文件大小
- (long long)getDownloadedLengthWithUrl:(NSString *)url {
    NSString *key = [url md5];
    long long length = [self getDownloadedLengthWithKey:key];
    return length;
}

// 删除所有文件
- (void)removeAllFile {
    NSMutableDictionary *plistDict = [self getPlist];
    for (NSString *key in plistDict.allKeys) {
        [self removeFileWithKey:key];
    }
}

// 删除下载文件
- (void)removeFileWithUrl:(NSString *)url {
    NSString *key = [url md5];
    [self removeFileWithKey:key];
}



#pragma mark - Private
// 获取文件总大小
- (long long)getTotalLengthWithKey:(NSString *)key {
    NSDictionary *plistDict = [self getPlist];
    if ([plistDict.allKeys containsObject:key]) {
        NSDictionary *dict = [plistDict valueForKey:key];
        long long length = [[dict valueForKey:@"totalLength"] unsignedIntegerValue];
        return length;
    }
    return 0;
}

// 获取文件下载地址
- (NSString *)getUrlWithKey:(NSString *)key {
    NSDictionary *plistDict = [self getPlist];
    if ([plistDict.allKeys containsObject:key]) {
        NSDictionary *dict = [plistDict valueForKey:key];
        NSString *url = [dict valueForKey:@"url"];
        return url;
    }
    return nil;
}

// 获取plist文件路径
- (NSString *)getPlistPath {
    NSString *plistPath = [[self getFileCacheDirectory] stringByAppendingPathComponent:@"Downloads.plist"];
    return plistPath;
}

// 获取缓存Cache路径
- (NSString *)getFileCacheDirectory {
    NSString *cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"MYDownload"];
    return cachePath;
}

// 获取已下载文件大小
- (long long)getDownloadedLengthWithKey:(NSString *)key {
    NSLog(@"// 获取已下载文件大小");
    long long fileLength = 0;
    NSString *path = [self getDownloadedPathWithKey:key];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileLength = [fileDict fileSize];
        }
    }
    return fileLength;
}

// 获取下载文件路径
- (NSString *)getDownloadedPathWithKey:(NSString *)key {
    NSMutableDictionary *plistDict = [self getPlist];
    NSDictionary *dict = [plistDict valueForKey:key];
    NSString *fileName = [dict valueForKey:@"FileName"];
    NSString *filePath = [self getDownloadedPathWithFileName:fileName];
    return filePath;
}

// 创建plist文件
- (void)createPlistIfNotExist {
    NSString *path = [self getPlistPath];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:path]) {
        // 创建MYDownload目录
        NSString *directoryPath = [self getFileCacheDirectory];
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        // 创建plist文件
        [fileManager createFileAtPath:path contents:nil attributes:nil]; // 立即在沙盒中创建一个空plist文件
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict writeToFile:path atomically:YES]; // 将空字典写入plist文件
    }
}

// 获取下载文件路径
- (NSString *)getDownloadedPathWithFileName:(NSString *)fileName {
    NSString *path = [[self getFileCacheDirectory] stringByAppendingPathComponent:fileName];
    return path;
}

// 保存文件总大小到plist
- (void)setPlistValue:(id)value forKey:(NSString *)key {
    [self createPlistIfNotExist];
    NSString *path = [self getPlistPath];
    NSMutableDictionary *dict = [self getPlist];
    [dict setValue:value forKey:key];
    [dict writeToFile:path atomically:YES];
}

// 删除plist记录
- (void)removePlistValueForKey:(NSString *)key {
    NSString *path = [self getPlistPath];
    NSMutableDictionary *dict = [self getPlist];
    [dict removeObjectForKey:key];
    [dict writeToFile:path atomically:YES];
}

// 删除下载文件
- (void)removeFileWithKey:(NSString *)key {
    NSString *path = [self getDownloadedPathWithKey:key];
    
    // 停止下载任务，删除下载对象
    MYDownload *download = [self.downloadDict valueForKey:key];
    if (download) {
        [download.task cancel];
        if (download.progressBlock) {
            download.progressBlock(0.f);
        }
        if (download.stateBlock) {
            download.stateBlock(MYDownloadStateCancel);
        }
        
        [self.downloadDict removeObjectForKey:key];
    }
    
    // 删除plist记录
    [self removePlistValueForKey:key];
    
    // 删除下载文件
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
}


#pragma mark - Lazy
- (NSMutableDictionary *)downloadDict {
    if (!_downloadDict) {
        _downloadDict = [NSMutableDictionary dictionary];
    }
    return _downloadDict;
}

#pragma mark - NSURLSessionDataDelegate
// 收到相应
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
            download.progressBlock(0.f);
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
    
#warning 判断预计数据为0的情况
    completionHandler(NSURLSessionResponseAllow);
    NSLog(@"/// Response exp = %llu, down = %llu, total = %llu", expectedLength, downloadedLength, totalLength);
}

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
            download.progressBlock(progress);
        }
        if (download.stateBlock) {
            download.stateBlock(MYDownloadStateDownloading);
        }
//        NSLog(@"/// Receive Down %lld, Total %lld, Progress = %.2f", downloadedLength, totalLength, progress);
    }
}

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
    NSLog(@"/// Complete error = %@", error);
}



@end

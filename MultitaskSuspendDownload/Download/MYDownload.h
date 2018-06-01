//
//  MYDownload.h
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/28.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MYDownloadState) {
    MYDownloadStateDownloading,  // 下载中
    MYDownloadStateComplete,     // 完成
    MYDownloadStateError,        // 错误
    MYDownloadStateSuspend,      // 暂停
    MYDownloadStateCancel        // 取消
};

typedef void(^ProgressBlock)(CGFloat progress, long long downloadedlength, long long totalLength);
typedef void(^StateBlock)(MYDownloadState state);

@interface MYDownload : NSObject
@property (nonatomic, copy) NSString *url;                  // 下载地址
@property (nonatomic, assign) long long downloadedLength;   // 已下载大小
@property (nonatomic, assign) long long totalLength;        // 总大小
@property (nonatomic, strong) NSURLSessionDataTask *task;   // 任务
@property (nonatomic, strong) NSFileHandle *fileHandle;     // 文件句柄
@property (nonatomic, copy) ProgressBlock progressBlock;    // 下载进度回调
@property (nonatomic, copy) StateBlock stateBlock;          // 下载状态回调
@end

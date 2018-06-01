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
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) long long totalLength;
@property (nonatomic, assign) long long downloadedLength;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, copy) ProgressBlock progressBlock;
@property (nonatomic, copy) StateBlock stateBlock;
@end

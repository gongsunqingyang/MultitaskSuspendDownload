//
//  MYDownloadManager.h
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/28.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MYDownload.h"

@interface MYDownloadManager : NSObject

/**
 单例
 */
+ (instancetype)sharedManager;
/**
 开始、暂停下载任务
 */
- (void)downloadWithUrl:(NSString *)url resume:(BOOL)resume progress:(ProgressBlock)progressBlock state:(StateBlock)stateBlock;
/**
 获取任务记录
 */
- (NSMutableDictionary *)getPlist;
/**
 获取已下载大小
 */
- (long long)getDownloadedLengthWithUrl:(NSString *)url;
/**
 移除单个文件
 */
- (void)removeFileWithUrl:(NSString *)url;
/**
 移除所有文件
 */
- (void)removeAllFile;

@end

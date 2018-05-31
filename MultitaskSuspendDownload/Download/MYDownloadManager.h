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
+ (instancetype)sharedManager;
- (void)downloadWithUrl:(NSString *)url resume:(BOOL)resume progress:(void (^)(CGFloat progress))progressBlock state:(void (^)(MYDownloadState state))stateBlock;
/**
 获取任务记录

 @return @{@"key" : @{@"totalLength" : @(9999), @"url" : @"http://.../file.mp4"}}
 */
- (NSMutableDictionary *)getPlist;
- (long long)getDownloadedLengthWithUrl:(NSString *)url;
- (void)removeFileWithUrl:(NSString *)url;
- (void)removeAllFile;
@end

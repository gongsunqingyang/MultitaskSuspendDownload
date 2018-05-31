//
//  NSURLSessionTask+Extension.h
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/29.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSessionTask (Extension)
@property (nonatomic, copy) NSString *taskKey;
@property (nonatomic, copy) NSString *url;
@end

//
//  NSURLSessionTask+Extension.m
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/29.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import "NSURLSessionTask+Extension.h"
#import <objc/runtime.h>

@implementation NSURLSessionTask (Extension)
static const void *TASK_KEY = &TASK_KEY;
static const void *URL_KEY = &URL_KEY;

- (NSString *)taskKey {
    return objc_getAssociatedObject(self, TASK_KEY);
}

- (void)setTaskKey:(NSString *)taskKey {
    objc_setAssociatedObject(self, TASK_KEY, taskKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)url {
    return objc_getAssociatedObject(self, URL_KEY);

}

- (void)setUrl:(NSString *)url {
    objc_setAssociatedObject(self, URL_KEY, url, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


@end

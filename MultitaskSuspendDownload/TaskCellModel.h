//
//  TaskCellModel.h
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/29.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TaskCellModel : NSObject
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) long long totalLength;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL resume;
@end

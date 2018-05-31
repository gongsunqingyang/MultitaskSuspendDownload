//
//  TaskCell.h
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/29.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaskCellModel.h"

typedef NS_ENUM(NSInteger, TaskCellEvent) {
    TaskCellEventResume,
    TaskCellEventSuspend,
    TaskCellEventDelete,
};

@class TaskCell;
@protocol TaskCellDelegate <NSObject>
- (void)taskCell:(TaskCell *)cell event:(TaskCellEvent)event;
@end

@interface TaskCell : UITableViewCell
@property (nonatomic, weak) id <TaskCellDelegate> delegate;
@property (nonatomic, strong) TaskCellModel *model;
@end

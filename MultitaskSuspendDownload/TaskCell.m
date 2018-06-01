//
//  TaskCell.m
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/29.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import "TaskCell.h"

@interface TaskCell ()
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIButton *resumeBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@end

@implementation TaskCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (IBAction)clickResumeBtn:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.model.resume = sender.selected;
    
    if (sender.selected) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(taskCell:event:)]) {
            [self.delegate taskCell:self event:TaskCellEventResume];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(taskCell:event:)]) {
            [self.delegate taskCell:self event:TaskCellEventSuspend];
        }
    }
}

- (IBAction)clickDeleteBtn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskCell:event:)]) {
        [self.delegate taskCell:self event:TaskCellEventDelete];
    }
}

- (void)updateCellWithUrl:(NSString *)url downloadedLength:(long long)downloadedLength totalLength:(long long)totalLength resume:(BOOL)resume {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGFloat progress = 0.f;
        if (totalLength) {
            progress = (CGFloat) downloadedLength / totalLength;
        }
        if (progress == 1) {
            self.model.resume = NO;
            self.resumeBtn.selected = NO;
        } else {
            self.resumeBtn.selected = resume;
        }
        self.urlLabel.text = url;
        self.progressView.progress = progress;
        self.progressLabel.text = [NSString stringWithFormat:@"[%.1f%%]  [%.1fMb/%.1fMb]", progress * 100, downloadedLength  / pow(1024, 2), totalLength / pow(1024, 2)];
    });
}


@end

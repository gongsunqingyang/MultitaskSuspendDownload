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
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *resumeBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@end

@implementation TaskCell

- (void)awakeFromNib {
    [super awakeFromNib];

    // KVO
    [self addObserver:self forKeyPath:@"model.progress" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"model.resume" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"model.progress"];
    [self removeObserver:self forKeyPath:@"model.resume"];
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

- (void)setModel:(TaskCellModel *)model {
    _model = model;
    
    self.urlLabel.text = model.url;
    self.totalLabel.text = [NSString stringWithFormat:@"%.1fMb", model.totalLength / pow(1024, 2)];
//    self.progressView.progress = model.progress;
//    self.progressLabel.text = [NSString stringWithFormat:@"%.f %%", model.progress * 100];
//    self.resumeBtn.selected = model.resume;
}

// KVO
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    if ([keyPath isEqualToString:@"model.progress"]) {
        CGFloat progress = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
        if (progress == 1) {
            self.model.resume = NO;
        }
//        NSLog(@"KVO progress %.2f", progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
            self.progressLabel.text = [NSString stringWithFormat:@"%.f%%", progress * 100];
        });
    } else if ([keyPath isEqualToString:@"model.resume"]){
        BOOL resume = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
//        NSLog(@"KVO resume %d", resume);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resumeBtn.selected = resume;
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

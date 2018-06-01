//
//  ViewController.m
//  MultitaskSuspendDownload
//
//  Created by yanglin on 2018/5/28.
//  Copyright © 2018年 Softisland. All rights reserved.
//

#import "ViewController.h"
#import "MYDownloadManager.h"
#import "TaskCell.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, TaskCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSMutableArray<TaskCellModel *> *dataSource;
@property (nonatomic, copy) NSArray *urls;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];

    
}

- (void)setupUI {
    self.title = @"多任务断点下载";
    
    UIBarButtonItem *item0 = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clean)];
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"添加" style:UIBarButtonItemStylePlain target:self action:@selector(addTask)];
    self.navigationItem.rightBarButtonItems = @[item0, item1];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    self.tableView.rowHeight = 70;
    [self.tableView registerNib:[UINib nibWithNibName:@"TaskCell" bundle:nil] forCellReuseIdentifier:@"identifier"];
    [self.view addSubview:self.tableView];
    
    
}

- (void)addTask {
    NSString *url = nil;
    if (!self.dataSource.count) {
        url = [self.urls firstObject];
    } else {
        for (int i = 0; i < self.urls.count; i++) {
            BOOL available = YES;
            NSString *tempUrl = self.urls[i];
            
            for (int j = 0; j < self.dataSource.count; j++) {
                TaskCellModel *model = self.dataSource[j];
                if ([model.url isEqualToString:tempUrl]) {
                    available = NO;
                    break;
                }
            }
            
            if (available) {
                url = tempUrl;
                break;
            }
        }
    }
    
    if (url) {
        TaskCellModel *model = [TaskCellModel new];
        model.url = url;
        model.downloadedLength = 0;
        model.totalLength = 0;
        model.progress = 0.f;
        model.resume = NO;
        
        [self.dataSource addObject:model];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
    } else {
        NSLog(@"没有更多任务了");
    }
}

- (void)clean {
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (int i = 0; i < self.dataSource.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    [self.dataSource removeAllObjects];
    
    [[MYDownloadManager sharedManager] removeAllFile];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (NSMutableArray<TaskCellModel *> *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
        
        // 读取plist记录
        NSMutableDictionary *plistDict = [[MYDownloadManager sharedManager] getPlist];
        for (NSString *key in plistDict.allKeys) {
            NSDictionary *dict = [plistDict valueForKey:key];
            
            NSNumber *totalLengthNumber = [dict valueForKey:@"TotalLength"];
            NSString *url = [dict valueForKey:@"Url"];
            long long totalLength = [totalLengthNumber longLongValue];
            long long downloadedLength = [[MYDownloadManager sharedManager] getDownloadedLengthWithUrl:url];
            CGFloat progress = (CGFloat) downloadedLength / totalLength;
            
            TaskCellModel *model = [TaskCellModel new];
            model.url = url;
            model.downloadedLength = downloadedLength;
            model.totalLength = totalLength;
            model.progress = progress;
            model.resume = NO;
            
            [_dataSource addObject:model];
        }
    }
    return _dataSource;
}

- (NSArray *)urls {
    if (!_urls) {
        _urls = @[@"http://speedtest.tokyo.linode.com/100MB-tokyo.bin",
                  @"http://yun.it7090.com/video/XHLaunchAd/video03.mp4",
                  @"https://media.w3.org/2010/05/sintel/trailer.mp4",
                  @"http://www.w3school.com.cn/example/html5/mov_bbb.mp4",
                  @"https://gcs-vimeo.akamaized.net/exp=1527663379~acl=%2A%2F623685558.mp4%2A~hmac=83e6d2bce66e8e8f2e484034d9ebf902f7e0675c6f7ee946c5a0be1989cfe643/vimeo-prod-skyfire-std-us/01/2670/7/188350983/623685558.mp4",
                  @"https://gcs-vimeo.akamaized.net/exp=1527663362~acl=%2A%2F623661526.mp4%2A~hmac=182bb0761e8a920a2b240b196038ea8173a884eccaf139bc39b60ede1f55db2b/vimeo-prod-skyfire-std-us/01/2684/7/188421287/623661526.mp4"
                  ];
    }
    return _urls;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:@"identifier"];
    if (!cell) {
        cell = [[TaskCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"identifier"];
    }
    cell.delegate = self;
    TaskCellModel *model = self.dataSource[indexPath.row];
    cell.model = model;
    [cell updateCellWithUrl:model.url downloadedLength:model.downloadedLength totalLength:model.totalLength resume:model.resume];
    return cell;
}

#pragma mark - TaskCellDelegate
- (void)taskCell:(TaskCell *)cell event:(TaskCellEvent)event {
    TaskCellModel *model = cell.model;
    
    switch (event) {
        case TaskCellEventResume: case TaskCellEventSuspend:{
            // 开始、暂停下载任务
            [[MYDownloadManager sharedManager] downloadWithUrl:model.url resume:model.resume progress:^(CGFloat progress, long long downloadedlength, long long totalLength) {
                model.downloadedLength = downloadedlength;
                model.totalLength = totalLength;
                model.progress = progress;
                [cell updateCellWithUrl:model.url downloadedLength:downloadedlength totalLength:totalLength resume:model.resume];
            } state:^(MYDownloadState state) {
                switch (state) {
                    case MYDownloadStateDownloading: {
                        
                    }
                        break;
                    case MYDownloadStateComplete: {
                        model.resume = NO;
                    }
                        break;
                    case MYDownloadStateError: {
                        model.resume = NO;
                    }
                        break;
                    case MYDownloadStateSuspend: {
                        
                    }
                        break;
                    case MYDownloadStateCancel: {
                        model.resume = NO;
                    }
                        break;
                    default:
                        break;
                }
            }];
        }
            break;
        case TaskCellEventDelete:{
            [[MYDownloadManager sharedManager] removeFileWithUrl:model.url];
            model.downloadedLength = 0.f;
            model.progress = 0.f;
            model.resume = NO;
            [cell updateCellWithUrl:model.url downloadedLength:model.downloadedLength totalLength:model.totalLength resume:model.resume];
        }
            break;
        default:
            break;
    }
}

@end

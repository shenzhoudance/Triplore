//
//  TPPlayViewController.m
//  Triplore
//
//  Created by 宋 奎熹 on 2017/5/30.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

#import "TPPlayViewController.h"
#import "QYPlayerController.h"
#import "ActivityIndicatorView.h"
#import "Utilities.h"
#import "TPNoteCreator.h"
#import "TPNoteViewController.h"
#import "TPAddTextViewController.h"
#import <objc/runtime.h>
#import "QYAVPlayerController.h"
#import "PlayerController.h"
#import "UIImage+Extend.h"
#import "TPNoteCreator.h"
#import "TPNoteViewTableViewCell.h"

#define KIPhone_AVPlayerRect_mwidth 320.0
#define KIPhone_AVPlayerRect_mheight 180.0

#define NAVIGATION_BAR_HEIGHT 0.0
#define CONTROLLER_BAR_WIDTH 30.0

@interface TPPlayViewController () <QYPlayerControllerDelegate, TPAddNoteViewDelegate, PlayerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>{
    CGRect playFrame;
    UIView *playerView;
    UITextField *titleText;
    
    NSMutableArray *noteViews;
    NSIndexPath *selectedIndexPath;
}

@property (nonnull, nonatomic) UITableView *tableView;
@property (nonatomic,strong) ActivityIndicatorView *activityWheel;

@end

@implementation TPPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    noteViews = [[NSMutableArray alloc] init];
    
    self.view.backgroundColor = [Utilities getBackgroundColor];

    self.navigationController.navigationBar.barTintColor = [Utilities getColor];
    self.navigationController.navigationBar.backgroundColor = [Utilities getColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationItem.title = @"视频";
    
    self.hidesBottomBarWhenPushed = YES;
    self.tabBarController.tabBar.hidden = YES;
    
    playFrame = CGRectMake(0,
                           0,
                           self.view.frame.size.width,
                           self.view.frame.size.width / KIPhone_AVPlayerRect_mwidth * KIPhone_AVPlayerRect_mheight);
    [QYPlayerController sharedInstance].delegate = self;
    [[QYPlayerController sharedInstance] setPlayerFrame:CGRectMake(0,
                                                                   0,
                                                                   self.view.frame.size.width,
                                                                   self.view.frame.size.width / KIPhone_AVPlayerRect_mwidth * KIPhone_AVPlayerRect_mheight + 64)];
    playerView = [QYPlayerController sharedInstance].view;
    [self.view addSubview:playerView];
    
//    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [backButton setFrame:CGRectMake(10, 10, 30, 30)];
//    UIImage *backImg = [UIImage imageNamed:@"playerBack"];
//    [backButton setImage:backImg forState:UIControlStateNormal];
//    [backButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:backButton];
    
    ActivityIndicatorView *wheel = [[ActivityIndicatorView alloc] initWithFrame: CGRectMake(0, 0, 15, 15)];
    wheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    self.activityWheel = wheel;
    self.activityWheel.center = [QYPlayerController sharedInstance].view.center;
    
    titleText = [[UITextField alloc] initWithFrame:CGRectMake(20,
                                                              playFrame.size.height + NAVIGATION_BAR_HEIGHT,
                                                              self.view.frame.size.width - 78,
                                                              64)];
    titleText.placeholder = @"填写笔记标题";
    titleText.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18.0f];
    titleText.delegate = self;
    titleText.textColor = [UIColor colorWithRed:94.0/255.0 green:113.0/255.0 blue:113.0/255.0 alpha:1.0];
    [self.view addSubview:titleText];
    
    UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 112,
                                                                      playFrame.size.height + 20 + NAVIGATION_BAR_HEIGHT,
                                                                      24,
                                                                      24)];
    [editButton setImage:[UIImage imageNamed:@"NOTE_EDIT"] forState:UIControlStateNormal];
    [editButton addTarget:self action:@selector(editNoteAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:editButton];
    
    UIButton *screenshotButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 78,
                                                                            playFrame.size.height + 20 + NAVIGATION_BAR_HEIGHT,
                                                                            24,
                                                                            24)];
    [screenshotButton setImage:[UIImage imageNamed:@"NOTE_SCREENSHOT"] forState:UIControlStateNormal];
    [screenshotButton addTarget:self action:@selector(screenShotAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:screenshotButton];
    
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 44,
                                                                      playFrame.size.height + 20 + NAVIGATION_BAR_HEIGHT,
                                                                      24,
                                                                      24)];
    [saveButton setImage:[UIImage imageNamed:@"NOTE_SAVE"] forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveNoteAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
    
    //    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
    //    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                   CGRectGetHeight(playFrame) + 64,
                                                                   CGRectGetWidth(self.view.bounds),
                                                                   CGRectGetHeight(self.view.bounds) - CGRectGetHeight(playFrame) - 64 - 64)
                                                  style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated{
    self.tabBarController.tabBar.hidden = YES;
    [self reloadNoteViews];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    NSString* aid = [self.playDetail valueForKey:@"a_id"];
    NSString* tvid = [self.playDetail valueForKey:@"tv_id"];
    NSString* isvip = [self.playDetail valueForKey:@"is_vip"];
    [[QYPlayerController sharedInstance] openPlayerByAlbumId:aid tvId:tvid isVip:isvip];
}

- (void)viewWillDisappear:(BOOL)animated{
    self.tabBarController.tabBar.hidden = NO;
    
    [[QYPlayerController sharedInstance] pause];
}

- (void)dealloc{
    [[TPNoteCreator shareInstance] clearNoteView];
}

- (void)reloadNoteViews{
    [noteViews removeAllObjects];
    [noteViews addObjectsFromArray:[[TPNoteCreator shareInstance] getNoteViews]];
}

- (void)showPlayView{
    UIView *playView = [self.view viewWithTag:100];
    UIView *pauseView = [self.view viewWithTag:200];
    if(playView == nil){
        UIButton *play= [UIButton buttonWithType:UIButtonTypeCustom];
        [play setBackgroundColor:[UIColor blackColor]];
        [play setFrame:CGRectMake(10,
                                  CGRectGetHeight(playFrame) - 40,
                                  30,
                                  30)];
        [play setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        play.layer.masksToBounds=YES;
        play.layer.cornerRadius=15;
        play.alpha = 0.7;
        [play addTarget:self action:@selector(playClick) forControlEvents:UIControlEventTouchUpInside];
        [play setTag:100];
        [self.view addSubview:play];
        play.hidden = NO;
        pauseView.hidden = YES;
    }else{
        playView.hidden = NO;
        pauseView.hidden = YES;
    }
}

- (void)showPauseView{
    UIView *playView = [self.view viewWithTag:100];
    UIView *pauseView = [self.view viewWithTag:200];
    if(pauseView==nil){
        UIButton *pause= [UIButton buttonWithType:UIButtonTypeCustom];
        [pause setBackgroundColor:[UIColor blackColor]];
        [pause setFrame:CGRectMake(10,
                                   CGRectGetHeight(playFrame) - 40,
                                   30,
                                   30)];
        [pause setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        pause.layer.masksToBounds=YES;
        pause.layer.cornerRadius=15;
        pause.alpha = 0.7;
        [pause addTarget:self action:@selector(pauseClick) forControlEvents:UIControlEventTouchUpInside];
        [pause setTag:200];
        [self.view addSubview:pause];
        pause.hidden = NO;
        playView.hidden = YES;
    }else{
        pauseView.hidden = NO;
        playView.hidden = YES;
    }
}

- (void)enablePlayPauseView{
    UIView *playView = [self.view viewWithTag:100];
    UIView *pauseView = [self.view viewWithTag:200];
    if(playView!=nil){
        playView.userInteractionEnabled = YES;
    }
    if(pauseView!=nil){
        playView.userInteractionEnabled = YES;
    }
}

- (void)unablePlayPauseView{
    UIView *playView = [self.view viewWithTag:100];
    UIView *pauseView = [self.view viewWithTag:200];
    if(playView!=nil){
        playView.userInteractionEnabled = NO;
    }
    if(pauseView!=nil){
        playView.userInteractionEnabled = NO;
    }
}

//- (void)backClick{
//    [[QYPlayerController sharedInstance] stopPlayer];
//    [self dismissViewControllerAnimated:YES completion:^{
//        
//    }];
//}

- (void)playClick{
    [[QYPlayerController sharedInstance] play];
    [self showPauseView];
}

- (void)pauseClick{
    if ([QYPlayerController sharedInstance].isPlaying==YES) {
        [[QYPlayerController sharedInstance] pause];
        [self showPlayView];
    }
}

#pragma QYBasePlayerControllerDelegate

/*
 * 播放出错
 */
- (void)onPlayerError:(NSDictionary *)error_no{
    [self.activityWheel stopAnimating];
    [self.activityWheel removeFromSuperview];
}

/*
 * 显示加载loading
 */
- (void)startLoading:(QYPlayerController *)player{
    if (self.activityWheel.superview==nil) {
        [self.view addSubview:self.activityWheel];
        [self.activityWheel startAnimating];
    }
    [self unablePlayPauseView];
}

/*
 * 关闭加载loading
 */
- (void)stopLoading:(QYPlayerController *)player{
    [self.activityWheel stopAnimating];
    [self.activityWheel removeFromSuperview];
    [self enablePlayPauseView];
}
/**
 **功能: 开始播放广告
 *
 */
- (void)onAdStartPlay:(QYPlayerController *)player{
    [self showPauseView];
}

/**
 **功能: 开始播放正片
 *
 */
- (void)onContentStartPlay:(QYPlayerController *)player{
    [self showPauseView];
}

/*
 * 播放时长发生变化
 */
-(void)playbackTimeChanged:(QYPlayerController *)player{
    
}

/*
 * 播放完成
 */
-(void)playbackFinshed:(QYPlayerController *)player{
    
}

/*
 * 网络变化
 */
- (void)playerNetworkChanged:(QYPlayerController *)player{
    
}

- (BOOL)shouldAutorotate{
    return YES;
}

//支持横竖屏显示
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Button Action

- (void)editNoteAction{
    TPAddTextViewController *textVC = [[TPAddTextViewController alloc] initWithNibName:@"TPAddTextViewController" bundle:[NSBundle mainBundle]];
    textVC.addNoteViewDelegate = self;
    [textVC setNoteString:@""];
    [textVC setAddMode:TPAddNote];
    [textVC setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    self.modalPresentationStyle = UIModalPresentationCurrentContext; //关键语句，必须有
    [self presentViewController:textVC animated:YES completion:^(void){
        [self pauseClick];
    }];
}

- (void)editNoteActionWithString:(NSString *)string{
    TPAddTextViewController *textVC = [[TPAddTextViewController alloc] initWithNibName:@"TPAddTextViewController" bundle:[NSBundle mainBundle]];
    textVC.addNoteViewDelegate = self;
    [textVC setNoteString:string];
    [textVC setAddMode:TPUpdateNote];
    [textVC setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    self.modalPresentationStyle = UIModalPresentationCurrentContext; //关键语句，必须有
    [self presentViewController:textVC animated:YES completion:^(void){
        [self pauseClick];
    }];
}

- (void)addNoteView:(UIView *_Nonnull)view{
    [[TPNoteCreator shareInstance] addNoteView:view];
    NSLog(@"%lu Views", (long)[[TPNoteCreator shareInstance] countNoteView]);
    [self reloadNoteViews];
    [self.tableView reloadData];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[noteViews indexOfObject:view] inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)updateNoteView:(UIView *_Nonnull)view{
    [[TPNoteCreator shareInstance] updateNoteView:view atIndex:selectedIndexPath.row];
    NSLog(@"%lu Views", (long)[[TPNoteCreator shareInstance] countNoteView]);
    [self reloadNoteViews];
    [self.tableView reloadData];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[noteViews indexOfObject:view] inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)screenShotAction{
    NSLog(@"截图");
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)), NO, 1.0f);
    [self.view drawViewHierarchyInRect:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)) afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    image = [image getSubImage:CGRectMake(0, NAVIGATION_BAR_HEIGHT, playFrame.size.width, playFrame.size.height)];
    image = [image changeImageSizeWithOriginalImage:image percent:(1.0 - 40 / self.view.bounds.size.width)];
    [self addNoteView:[[UIImageView alloc] initWithImage:image]];
}

- (void)saveNoteAction{
    NSLog(@"保存");
    
    NSArray *noteArr = [[TPNoteCreator shareInstance] getNoteViews];
    if(noteArr.count <= 0){
        NSLog(@"没有 View");
        return;
    }
    
    TPNoteViewController *noteVC = [[TPNoteViewController alloc] init];
    [noteVC setNoteTitle:titleText.text];
    [noteVC setVideoDict:self.playDetail];
    [noteVC setNoteViews:[NSMutableArray arrayWithArray:[[TPNoteCreator shareInstance] getNoteViews]]];
    [self.navigationController pushViewController:noteVC animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return noteViews.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"TPNoteViewTableViewCell";
    TPNoteViewTableViewCell *cell = (TPNoteViewTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    [cell setNoteView:noteViews[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    selectedIndexPath = indexPath;
    if([noteViews[indexPath.row] isKindOfClass:[UILabel class]]){
        UILabel *label = (UILabel *)noteViews[indexPath.row];
        [self editNoteActionWithString:label.text];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    UIView *view = noteViews[indexPath.row];
    return view.frame.size.height + 20;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    [[TPNoteCreator shareInstance] removeNoteView:noteViews[indexPath.row]];
    [self reloadNoteViews];
    [tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

@end
    
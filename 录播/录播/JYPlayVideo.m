//
//  JYPlayVideo.m
//  NRT
//
//  Created by JY on 15/9/14.
//  Copyright (c) 2015年 JY. All rights reserved.
//

#import "JYPlayVideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>


#define  WID     [UIScreen mainScreen].bounds.size.width
#define  HEIGHT  [UIScreen mainScreen].bounds.size.height


#define INTT (WID-5*48)/6

#define COUNT_DUR_TIMER_INTERVAL  0.025

@interface JYPlayVideo ()
{
     UIProgressView   *_progressView;
     UIButton         *_startBtn;
     NSTimer          *_timer;
     NSInteger         _int_count;//播放时间


BOOL  _playBeginState;
BOOL  _isPause;
}

@property (nonatomic ,strong) AVPlayer *player;
@property (nonatomic ,strong) AVPlayerItem *playerItem;

@end

@implementation JYPlayVideo



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor redColor];
    
    
     [self initPlayer];//创建播放器
     [self initView];//创建按钮 进度

    //播放结束
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(playerItemDidReachEnd:)
                                                 name: AVPlayerItemDidPlayToEndTimeNotification
                                               object: self.playerItem];
    
}

-(void)initPlayer
{

    
    AVURLAsset *movieAsset = [[AVURLAsset alloc]initWithURL:self.fileURL options:nil];
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
     playerLayer.frame =CGRectMake(0, 64, WID, WID);
    
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.view.layer addSublayer:playerLayer];
    
    [self.player setAllowsExternalPlayback:YES];
    
    
    
}

-(void)initView
{
    
    _startBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_startBtn setTitle:@"开始" forState:UIControlStateNormal];
    _startBtn.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.5];
    _startBtn.center = CGPointMake(WID/2, 64+160);
    _startBtn.bounds = CGRectMake(0, 0, 60, 60);
    [_startBtn addTarget:self action:@selector(startBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_startBtn];
    
   
    
    
    UIButton  *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    backBtn.frame=CGRectMake(10, 20, 40, 40);
    [backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    
}

#pragma mark - BtnClick

-(void)backBtnClick
{
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)startBtnClick:(UIButton *)sender
{
    
    if([sender.titleLabel.text isEqualToString:@"开始"])
    {
        
        [self startPlay];//开始
        
    }else if ([sender.titleLabel.text isEqualToString:@"重播"])
    {
        
        [self rePlay];//重播
        
    }else if ([sender.titleLabel.text isEqualToString:@"继续播放"])
    {
        [self continuePlay];//继续播放
        
    }else
    {
        [self pauesPlay];//暂停
    }
    
}


#pragma mark - 播放器状态
//重播
-(void)rePlay
{
    _startBtn.titleLabel.text=@"";
    [_startBtn setTitle:@"" forState:UIControlStateNormal];
    _startBtn.backgroundColor=[UIColor clearColor];
    
    
    AVPlayerItem *playerItem = [self.player currentItem];
    // 从头
    [playerItem seekToTime: kCMTimeZero];
    //结束无动作
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
 
    [self.player play];
    
    _progressView.progress=0;
    _isPause=NO;

    
}
//继续播放
-(void)continuePlay
{
    _startBtn.titleLabel.text=@"";
    [_startBtn setTitle:@"" forState:UIControlStateNormal];
    _startBtn.backgroundColor=[UIColor clearColor];
    [self.player play];
    _isPause=NO;
    
    
}
//暂停播放
-(void)pauesPlay
{
    _isPause=YES;
    [_startBtn setTitle:@"继续播放" forState:UIControlStateNormal];
    _startBtn.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.5];
    [self.player pause];
    
}
//开始播放
-(void)startPlay
{
    _startBtn.titleLabel.text=@"";
    [_startBtn setTitle:@"" forState:UIControlStateNormal];
    _startBtn.backgroundColor=[UIColor clearColor];
    [self.player play];
  
    _isPause=NO;
    
}
//结束播放
-(void)endPlay
{
    [_startBtn setTitle:@"重播" forState:UIControlStateNormal];
    _startBtn.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.5];
  //  [self endTimer];
}
#pragma mark - 获取播放的时间
- (NSTimeInterval) playableDuration
{
    
    AVPlayerItem * item = self.playerItem;
    
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        
        return CMTimeGetSeconds(self.playerItem.duration);
        
    }
    else
    {
        
        return(CMTimeGetSeconds(kCMTimeInvalid));
        
    }
    
}

- (NSTimeInterval)playableCurrentTime
{
    AVPlayerItem * item = self.playerItem;
    
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        

        
        if (!_playBeginState&&CMTimeGetSeconds(self.playerItem.currentTime)==CMTimeGetSeconds(self.playerItem.duration)) {
            
            [self.player pause];
            
        }
        
        _playBeginState = NO;
        
        return CMTimeGetSeconds(self.playerItem.currentTime);
    }
    else
    {
        return(CMTimeGetSeconds(kCMTimeInvalid));
    }
}
#pragma mark - 加载视频完成
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if ([keyPath isEqualToString:@"status"])
//    {
//        if (AVPlayerItemStatusReadyToPlay == self.player.currentItem.status)
//        {
//            // [self.player play];
//            
//            
//            NSLog(@"准备播放");
//            //            NSLog(@"%lf",[self playableDuration]);
//            //            [UIView animateWithDuration:[self playableDuration] animations:^{
//            //
//            //            }];
//            
//        }
//    }
//}
#pragma mark - 播放结束时
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    
    [self endPlay];//播放停止
    
    //        [self.player play];
    //    }else {
    //        mPlayer.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
    //    }
}
@end

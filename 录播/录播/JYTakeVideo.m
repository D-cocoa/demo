//
//  JYTakeVideo.m
//  NRT
//
//  Created by JY on 15/9/14.
//  Copyright (c) 2015年 JY. All rights reserved.
//

#import "JYTakeVideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import "JYPlayVideo.h"
#import "SVProgressHUD.h"




#define MAX_VIDEO_DUR    10
#define COUNT_DUR_TIMER_INTERVAL  0.025
#define VIDEO_FOLDER    @"videos"


@interface JYTakeVideo ()
{
    
    NSURL *_finashURL;
    UIButton *_sureBtn;
    MPMoviePlayerController *_player;
    float   _float_totalDur;
    float   _float_currentDur;
     BOOL on;
}
@property(nonatomic,strong)AVCaptureSession      *captureSession;
@property(nonatomic,strong)AVCaptureDeviceInput  *videoDeviceInput;
@property(nonatomic,strong)AVCaptureMovieFileOutput *movieFileOutput;
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *preViewLayer;
@property(nonatomic,strong)UIView          *preview;
@property(nonatomic,strong)UIProgressView  *progressView;
@property(nonatomic,strong)NSTimer     *timer;
@property(nonatomic,strong)NSMutableArray     *files;

@property(nonatomic,unsafe_unretained)BOOL      isCameraSupported;
@property(nonatomic,unsafe_unretained)BOOL      isTorchSupported;
@property(nonatomic,unsafe_unretained)BOOL      isFrontCameraSupported;

@end

@implementation JYTakeVideo
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor orangeColor];
   
    self.automaticallyAdjustsScrollViewInsets = NO;
   
    //创建视频存储目录
    [[self class] createVideoFolderIfNotExist];
    
    //用来存储视频路径 以便合成时使用
    self.files=[NSMutableArray array];
    
    //创建视频捕捉窗口
    [self initCapture];
    
    //创建录像按钮
    [self initRecordButton];
    
    // Do any additional setup after loading the view.
}


-(void)initCapture
{
    self.captureSession = [[AVCaptureSession alloc]init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetLow];
    
    
    AVCaptureDevice *frontCamera = nil;
    AVCaptureDevice *backCamera = nil;
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if (camera.position == AVCaptureDevicePositionFront) {
            frontCamera = camera;
        } else {
            backCamera = camera;
        }
    }
    
    if (!backCamera) {
        self.isCameraSupported = NO;
        return;
    } else {
        self.isCameraSupported = YES;
        
        if ([backCamera hasTorch]) {
            self.isTorchSupported = YES;
        } else {
            self.isTorchSupported = NO;
        }
    }
    
    if (!frontCamera) {
        self.isFrontCameraSupported = NO;
    } else {
        self.isFrontCameraSupported = YES;
    }
    
    
    [backCamera lockForConfiguration:nil];
    if ([backCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        [backCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    }
    
    [backCamera unlockForConfiguration];
    
    self.videoDeviceInput =  [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:nil];
    
    AVCaptureDeviceInput *audioDeviceInput =[AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
    
    [_captureSession addInput:_videoDeviceInput];
    [_captureSession addInput:audioDeviceInput];
    
    
    //output
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [_captureSession addOutput:_movieFileOutput];
    
    //preset
    _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    //preview layer------------------
    self.preViewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _preViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [_captureSession startRunning];
    
    
    
    self.preview = [[UIView alloc] initWithFrame:CGRectMake(80, 248, 300, 302)];
     _preview.clipsToBounds = YES;
    [self.view addSubview:self.preview];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 300, 300, 12)];
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 2.0f);
    self.progressView.transform = transform;
    self.progressView.progress=0;
    self.progressView.tintColor = [UIColor greenColor];
    self.progressView.trackTintColor = [UIColor blueColor];
    [self.preview addSubview:self.progressView];
    
    
    self.preViewLayer.frame = CGRectMake(0, 0, 300, 300);
    [self.preview.layer addSublayer:self.preViewLayer];
    
    
}



-(void)initRecordButton
{
   
    
    //闪光灯
    UIButton *lightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    lightBtn.frame = CGRectMake(30, 80, 80, 40);
    [lightBtn setTitle:@"闪光灯" forState:UIControlStateNormal];
    [lightBtn addTarget:self action:@selector(lightBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:lightBtn];
    
    //正反摄像头
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraBtn.frame = CGRectMake(150, 80, 90, 40);
    [cameraBtn setTitle:@"摄像头" forState:UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(cameraBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraBtn];
    
    
    //开始录制
    UIButton *recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    recordBtn.center = CGPointMake(160, 600);
    recordBtn.bounds = CGRectMake(0, 0, 80, 66);
    [recordBtn setTitle:@"录制" forState:UIControlStateNormal];
    [recordBtn addTarget:self action:@selector(longTouch) forControlEvents:UIControlEventTouchDown];
    [recordBtn addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordBtn];
    
    //完成录制
    _sureBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _sureBtn.center = CGPointMake(300, 600);
    _sureBtn.bounds = CGRectMake(0, 0, 80, 60);
    [_sureBtn setTitle:@"点不着我"  forState:UIControlStateNormal];
    _sureBtn.userInteractionEnabled = NO;
    [_sureBtn addTarget:self action:@selector(sureBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_sureBtn];
 

    
}
-(void)play
{
    JYPlayVideo *playVideoVC=[[JYPlayVideo alloc]init];
    playVideoVC.fileURL=_finashURL;
    [self.navigationController pushViewController:playVideoVC animated:YES];
  
    
}

#pragma mark - BtnClick

-(void)touchUp
{
    
    [_movieFileOutput stopRecording];
    [self stopCountDurTimer];
    
}
-(void)sureBtnClick
{
    
    [SVProgressHUD showWithStatus:@"请稍等..."];
    [self mergeAndExportVideosAtFileURLs:self.files];
    
}
-(void)longTouch
{
    
    NSURL *fileURL = [NSURL fileURLWithPath:[[self class] getVideoSaveFilePathString]];
    
    [self.files addObject:fileURL];
    
    [_movieFileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
    
    
}
-(void)lightBtn
{
   
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (![device hasTorch]) {
        NSLog(@"no torch");
    }else{
        [device lockForConfiguration:nil];
        if (!on) {
            [device setTorchMode: AVCaptureTorchModeOn];
            on = YES;
        }
        else
        {
            [device setTorchMode: AVCaptureTorchModeOff];
            on = NO;
        }
        
        [device unlockForConfiguration];
    }

   
    
    
}

-(void)cameraBtn
{
  
    NSArray *inputs = self.captureSession.inputs;
    
    for ( AVCaptureDeviceInput *input in inputs )
    {
        AVCaptureDevice *device = input.device;
        
        if ( [device hasMediaType:AVMediaTypeVideo] )
        {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront)
            {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            }
            else{
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            }
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
           
            [self.captureSession beginConfiguration];
            
            [self.captureSession removeInput:input];
            [self.captureSession addInput:newInput];
            
   
            [self.captureSession commitConfiguration];
            break;
        }
    }
  
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}
-(void)cancelBtnClick
{

    [self.navigationController popViewControllerAnimated:YES];
}
-(void)backBtn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 获取视频大小及时长

//此方法可以获取文件的大小，返回的是单位是KB。
- (CGFloat) getFileSize:(NSString *)path
{
    NSFileManager *fileManager = [[NSFileManager alloc] init] ;
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path])
    {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }
    return filesize;
}
//此方法可以获取视频文件的时长
- (CGFloat) getVideoLength:(NSURL *)URL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    return second;
}

#pragma mark - 创建视频目录及文件


+ (NSString *)getVideoSaveFilePathString
{
    
    NSString *path =[NSString stringWithFormat:@"%@/tmp/",NSHomeDirectory()];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    formatter.dateFormat = @"yyyyMMddHHmmss";
    
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mp4"];
    
    return fileName;
    
}

+ (BOOL)createVideoFolderIfNotExist
{
    // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path =[NSString stringWithFormat:@"%@/tmp/",NSHomeDirectory()];
    
    //[paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建图片文件夹失败");
            return NO;
        }
        return YES;
    }
    return YES;
}


#pragma mark - 合成文件
- (void)mergeAndExportVideosAtFileURLs:(NSArray *)fileURLArray
{
    NSError *error = nil;
    
    CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime totalDuration = kCMTimeZero;
    
    //先去assetTrack 也为了取renderSize
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    
    
    for (NSURL *fileURL in fileURLArray)
    {
        
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        
        if (!asset) {
            continue;
        }
        NSLog(@"%@---%@",asset.tracks,[asset tracksWithMediaType:@"vide"]);
        
        [assetArray addObject:asset];
        
        
        AVAssetTrack *assetTrack = [[asset tracksWithMediaType:@"vide"] objectAtIndex:0];
        
        [assetTrackArray addObject:assetTrack];
        
        renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.height);
        renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.width);
    }
    
    
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    
    for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
        
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
      
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:([[asset tracksWithMediaType:AVMediaTypeAudio] count]>0)?[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]:nil atTime:totalDuration error:nil];
        
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetTrack
                             atTime:totalDuration
                              error:&error];
        
        //fix orientationissue
        AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        
        CGFloat rate;
        rate = renderW / MIN(assetTrack.naturalSize.width, assetTrack.naturalSize.height);
        
        CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
        layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0));//向上移动取中部影响
        layerTransform = CGAffineTransformScale(layerTransform, rate, rate);//放缩，解决前后摄像结果大小不对称
        
        [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
        [layerInstruciton setOpacity:0.0 atTime:totalDuration];
        
        //data
        [layerInstructionArray addObject:layerInstruciton];
    }
    
    //get save path
    NSString *filePath = [[self class] getVideoMergeFilePathString];
    
    NSURL *mergeFileURL = [NSURL fileURLWithPath:filePath];
    
    //export
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
       dispatch_async(dispatch_get_main_queue(), ^{
            
            _finashURL=mergeFileURL;
            [SVProgressHUD dismiss];
              [self play];
           //保存到相册
           // UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
      
             //           if ([_delegate respondsToSelector:@selector(videoRecorder:didFinishMergingVideosToOutPutFileAtURL:)]) {
            //                [_delegate videoRecorder:self didFinishMergingVideosToOutPutFileAtURL:mergeFileURL];
            //            }
        });
      
    }];
}

+ (NSString *)getVideoMergeFilePathString
{
   // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //  NSLog(@"",);
    NSString *path =[NSString stringWithFormat:@"%@/tmp/",NSHomeDirectory()];
    // [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mp4"];
    
    return fileName;
}
#pragma mark - 计时器操作

- (void)startCountDurTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:COUNT_DUR_TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

- (void)onTimer:(NSTimer *)timer
{
    
    _float_totalDur+=COUNT_DUR_TIMER_INTERVAL;
    
    NSLog(@"%lf ----  %lf",_float_totalDur,self.progressView.progress);
    
    self.progressView.progress = _float_totalDur/MAX_VIDEO_DUR ;
    if (self.progressView.progress >0.04)
    {
        _sureBtn.userInteractionEnabled = YES;
       [_sureBtn setTitle:@"可以点了"  forState:UIControlStateNormal];
    }
    if(self.progressView.progress==1)
    {
        [self touchUp];
        [self performSelector:@selector(sureBtnClick) withObject:nil afterDelay:1];
        
    }
    
    
}
- (void)stopCountDurTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - AVCaptureFileOutputRecordignDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    [self startCountDurTimer];
    NSLog(@"didStartRecordingToOutputFileAtURL");
    
    //    self.currentFileURL = fileURL;
    //
    //    self.currentVideoDur = 0.0f;
    //    [self startCountDurTimer];
    //
    //    if ([_delegate respondsToSelector:@selector(videoRecorder:didStartRecordingToOutPutFileAtURL:)]) {
    //        [_delegate videoRecorder:self didStartRecordingToOutPutFileAtURL:fileURL];
    //    }
}
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    
    NSLog(@"-------&-------%@",videoPath);
    
    NSLog(@"&&&error:%@",error);
    
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    
    NSLog(@"didFinishRecordingToOutputFileAtURL---%lf",_float_totalDur);
    //    self.totalVideoDur += _currentVideoDur;
    //    NSLog(@"本段视频长度: %f", _currentVideoDur);
    //    NSLog(@"现在的视频总长度: %f", _totalVideoDur);
    //
    //    if (!error) {
    //        SBVideoData *data = [[SBVideoData alloc] init];
    //        data.duration = _currentVideoDur;
    //        data.fileURL = outputFileURL;
    //
    //        [_videoFileDataArray addObject:data];
    //    }
    //
    //    if ([_delegate respondsToSelector:@selector(videoRecorder:didFinishRecordingToOutPutFileAtURL:duration:totalDur:error:)]) {
    //        [_delegate videoRecorder:self didFinishRecordingToOutPutFileAtURL:outputFileURL duration:_currentVideoDur totalDur:_totalVideoDur error:error];
    //    }
}
//- (UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}
- (BOOL)prefersStatusBarHidden//for iOS7.0
{
    return YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end

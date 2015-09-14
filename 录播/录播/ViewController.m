//
//  ViewController.m
//  录播
//
//  Created by JY on 15/9/14.
//  Copyright (c) 2015年 JY. All rights reserved.
//

#import "ViewController.h"
#import "JYPlayVideo.h"
#import "JYTakeVideo.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)录制:(id)sender {
    
    JYTakeVideo *vc= [[JYTakeVideo  alloc]init];
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
    
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    window.rootViewController =nav;
    
    
}

@end

//
//  JYPlayVideo.h
//  NRT
//
//  Created by JY on 15/9/14.
//  Copyright (c) 2015年 JY. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JYTakeVideo;

@interface JYPlayVideo : UIViewController
{
    NSArray *_musicarray;
    UIScrollView *_scrollView;
    UIImageView * imageView;
}
@property(nonatomic,strong)NSURL   *fileURL;

@end

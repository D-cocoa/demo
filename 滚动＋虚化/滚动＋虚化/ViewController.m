//
//  ViewController.m
//  滚动＋虚化
//
//  Created by JY on 15/9/7.
//
//

#import "ViewController.h"
#import "iCarousel.h"
#import "UIImageView+LBBlurredImage.h"
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
@interface ViewController ()<iCarouselDataSource, iCarouselDelegate>
{
    NSArray *_arname;
}
@property(nonatomic,strong)UIImageView *imgview;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _arname = [NSArray arrayWithObjects:@"125.jpg",@"126.jpg",@"127.jpg",@"128.jpg",@"129.jpg",@"130.jpg", nil];
    
    _imgview = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT)];
    
    [self.view addSubview:_imgview];
    
    
    [self.imgview setImageToBlur:[UIImage imageNamed:@"125.jpg"]
                      blurRadius:kLBBlurredImageDefaultBlurRadius
                 completionBlock:^(){
                     NSLog(@"The blurred image has been set");
                 }];
    
    
    iCarousel * ic = [[iCarousel alloc]initWithFrame:CGRectMake(110, 64, 100, 100)];
    ic.delegate =self;
    ic.dataSource =self;
    ic.type = iCarouselTypeRotary;
    [self.view addSubview:ic];
}

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    return 6;
}
- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    UIImageView  *img = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 120.0f, 120.0f)];
    img.image = [UIImage imageNamed:_arname[index]];
    view.contentMode = UIViewContentModeCenter;
    return img;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    if (option == iCarouselOptionSpacing)
    {
        return value * 1.2;
    }
    return value;
}
- (void)carouselDidEndDecelerating:(iCarousel *)carousel
{
    NSLog(@"%ld",(long)carousel.currentItemIndex);
    
    [self.imgview setImageToBlur:[UIImage imageNamed:_arname[carousel.currentItemIndex]]
                      blurRadius:kLBBlurredImageDefaultBlurRadius
                 completionBlock:^(){
                     NSLog(@"The blurred image has been set2");
                 }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

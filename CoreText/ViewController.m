//
//  ViewController.m
//  CoreText
//
//  Created by 黄敬 on 2018/8/20.
//  Copyright © 2018年 hj. All rights reserved.
//

#import "ViewController.h"
#import "CoreTextView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = [UIColor lightGrayColor].CGColor;
    layer.frame = CGRectMake(0, 84, 320, 200);
    [self.view.layer addSublayer:layer];
    
    CoreTextView *coreView = [[CoreTextView alloc] initWithFrame:CGRectMake(0, 84, 320, 200)];
    coreView.layer.borderColor = [UIColor redColor].CGColor;
    coreView.layer.borderWidth = 1;
    coreView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:coreView];
    coreView.font = [UIFont systemFontOfSize:20];
    coreView.lineSpace = 10;
    coreView.alignment = NSTextAlignmentCenter;
    coreView.colorRangeArray = @[NSStringFromRange(NSMakeRange(4, 5)),NSStringFromRange(NSMakeRange(10, 3)),NSStringFromRange(NSMakeRange(19, 2))];
    coreView.text = @"1[微笑]测试是爱上你的罚款放到那房间看电视烦恼四大皆空发那束带结发十多年福建省对方能接受的[白眼]看法对方迪士尼开发商的耐腐蚀大嫁风尚带你飞九点十分年历史的烦恼";
//    CGSize size = [coreView suggestSize];
//    coreView.frame = CGRectMake(0, 84, size.width, size.height);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

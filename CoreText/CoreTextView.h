//
//  CoreTextView.h
//  CoreText
//
//  Created by 黄敬 on 2018/8/20.
//  Copyright © 2018年 hj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreTextView : UIView

@property (nonatomic, strong, readonly) NSMutableAttributedString *attributedString;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) UIFont *font;

@property (nonatomic, assign) NSTextAlignment alignment;

@property (nonatomic, assign) NSLineBreakMode lineBreakMode;

@property (nonatomic, assign) CGFloat lineSpace;

@property (nonatomic, strong) NSArray <NSString *>*colorRangeArray;

- (CGSize)suggestSize;
@end

//
//  CoreTextView.m
//  CoreText
//
//  Created by 黄敬 on 2018/8/20.
//  Copyright © 2018年 hj. All rights reserved.
//

#import "CoreTextView.h"
#import <CoreText/CoreText.h>

@interface CoreTextView()
{
    CTFramesetterRef _framesetter;
    CTFrameRef _frameRef;
}
@property (nonatomic, strong) NSMutableArray *touchBackgroundRangeArray;
@end

@implementation CoreTextView

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)setText:(NSString *)text
{
    _text = text;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_text];
    _attributedString = attributedString;
    [self refreshAttributedStringStyle];
    [self refreshFramesetter];
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    [self refreshFont];
    [self refreshFramesetter];
    [self setNeedsDisplay];
}

- (void)setAlignment:(NSTextAlignment)alignment
{
    _alignment = alignment;
    [self refreshParagraphStyle];
    [self refreshFramesetter];
    [self setNeedsDisplay];
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    _lineBreakMode = lineBreakMode;
    [self refreshParagraphStyle];
    [self refreshFramesetter];
    [self setNeedsDisplay];
}

- (void)setLineSpace:(CGFloat)lineSpace
{
    _lineSpace = lineSpace;
    [self refreshParagraphStyle];
    [self refreshFramesetter];
    [self setNeedsDisplay];
}

- (void)setColorRangeArray:(NSArray<NSString *> *)colorRangeArray
{
    _colorRangeArray = colorRangeArray;
    [self refreshColorRange];
    [self refreshFramesetter];
    [self setNeedsDisplay];
}

#pragma mark - draw

- (void)drawRect:(CGRect)rect
{
    if (_text.length) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        /*翻转坐标*/
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, rect);
        CTFrameRef frameRef = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, _text.length), path, NULL);
        _frameRef = frameRef;
        [self drawTouchBackground:context];
       
        CTFrameDraw(frameRef, context);
        CGContextRestoreGState(context);
    }
}

- (void)drawTouchBackground:(CGContextRef)context
{
    if (!_touchBackgroundRangeArray.count) {
        return;
    }

    CFArrayRef lines = CTFrameGetLines(_frameRef);
    CGPoint lineOrigins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, 0), lineOrigins);

    for (NSString *rangeStr in self.touchBackgroundRangeArray) {
        NSRange range = NSRangeFromString(rangeStr);
        for (int i = 0; i < CFArrayGetCount(lines); i++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
             CGPoint lineOrigin = lineOrigins[i];
            for (id glyphRun in (__bridge NSArray *)CTLineGetGlyphRuns(line)) {
                CGFloat runAscent;
                CGFloat runDescent;
                CGFloat runLeading;
               
                CTRunRef run = (__bridge CTRunRef)(glyphRun);
                CFRange glyphRange = CTRunGetStringRange(run);
                CGRect runRect;
                runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, &runLeading);
                runRect = CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y, runRect.size.width, runAscent + runDescent + runLeading);
                if (glyphRange.location >= range.location && glyphRange.location + glyphRange.length <= range.location + range.length) {
                    /*
                    CGContextSetLineJoin(context, kCGLineJoinRound);
                    CGContextSetFillColorWithColor(context,[UIColor yellowColor].CGColor);
                    CGContextFillRect(context , runRect);
                     */
                    CGPathRef path = [[UIBezierPath bezierPathWithRoundedRect:runRect cornerRadius:3] CGPath];
                    CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
                    CGContextAddPath(context, path);
                    CGContextFillPath(context);
                }
            }
        }
    }
}

- (void)refreshAttributedStringStyle
{
    [self refreshFont];
    [self refreshColorRange];
    [self refreshParagraphStyle];
}

- (void)refreshFont
{
    if (_font) {
        [_attributedString addAttribute:NSFontAttributeName value:_font range:NSMakeRange(0, _attributedString.string.length)];
    }
}

- (void)refreshColorRange
{
    if (_colorRangeArray.count) {
        for (NSString *rangeStr in _colorRangeArray) {
            [_attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSRangeFromString(rangeStr)];
        }
    }
}

- (void)refreshParagraphStyle
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = _alignment;
    paragraphStyle.lineSpacing = _lineSpace;
    paragraphStyle.lineBreakMode = _lineBreakMode;
    [_attributedString addAttribute:NSParagraphStyleAttributeName
                              value:paragraphStyle
                              range:NSMakeRange(0, _attributedString.string.length)];
}

- (void)refreshFramesetter
{
    CTFramesetterRef framesetter =  CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attributedString);
    _framesetter = framesetter;
}

#pragma mark - touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    [self touches:touches];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
{

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_touchBackgroundRangeArray.count) {
        [_touchBackgroundRangeArray removeAllObjects];
        [self setNeedsDisplay];
    }
}

- (void)touches:(NSSet<UITouch *> *)touches
{
    CGPoint location = [[touches anyObject] locationInView:self];
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    
    CGPoint origins[CFArrayGetCount(lines)];
    //获取每行的原点坐标
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, 0), origins);

    CTLineRef line = NULL;
    CGPoint lineOrigin = CGPointZero;
    for (int i = 0; i < CFArrayGetCount(lines); i++)
    {
        CGPoint origin = origins[i];
        CGPathRef path = CTFrameGetPath(_frameRef);
        CGRect rect = CGPathGetBoundingBox(path);
        CGFloat y = rect.origin.y + rect.size.height - origin.y;
        if ((location.y <= y) && (location.x >= origin.x)) {
            line = CFArrayGetValueAtIndex(lines, i);
            lineOrigin = origin;
            break;
        }
    }
//    location.x -= lineOrigin.x;
    CFIndex index = CTLineGetStringIndexForPosition(line, location);
    
    NSLog(@"%d",(int)index);
    
    for (NSString *rangeStr in _colorRangeArray) {
        NSRange range = NSRangeFromString(rangeStr);
        if (NSLocationInRange(index - 1,range)) {
            if (![self.touchBackgroundRangeArray containsObject:rangeStr]) {
                [self.touchBackgroundRangeArray addObject:rangeStr];
                [self setNeedsDisplay];
            }
            break;
        }
    }
}

- (CGSize)suggestSize
{
    CGSize targetSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter, CFRangeMake(0, (CFIndex)(_text.length)), NULL, targetSize, NULL);
    return suggestedSize;
}

#pragma mark - getter
- (NSMutableArray *)touchBackgroundRangeArray
{
    if (!_touchBackgroundRangeArray) {
        _touchBackgroundRangeArray = [[NSMutableArray alloc] init];
    }
    return _touchBackgroundRangeArray;
}

@end

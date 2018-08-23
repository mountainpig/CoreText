//
//  CoreTextView.m
//  CoreText
//
//  Created by 黄敬 on 2018/8/20.
//  Copyright © 2018年 hj. All rights reserved.
//

#import "CoreTextView.h"
#import <CoreText/CoreText.h>

NSString *const kCustomGlyphAttributeImageName = @"CustomGlyphAttributeImageName";

@interface CoreTextView()
{
    CTFramesetterRef _framesetter;
    CTFrameRef _frameRef;
}
@property (nonatomic, strong) NSMutableArray *touchBackgroundRangeArray;
@property (nonatomic, strong) NSDictionary *imageDictionary;
@property (nonatomic, strong) NSString *imagePatternString;
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
    [self insertImageAttributedString];
    [self refreshAttributedStringStyle];
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    [self refreshFont];
    [self setNeedsDisplay];
}

- (void)setAlignment:(NSTextAlignment)alignment
{
    _alignment = alignment;
    [self refreshParagraphStyle];
    [self setNeedsDisplay];
}

- (void)setLineSpace:(CGFloat)lineSpace
{
    _lineSpace = lineSpace;
    [self refreshParagraphStyle];
    [self setNeedsDisplay];
}

- (void)setColorRangeArray:(NSArray<NSString *> *)colorRangeArray
{
    _colorRangeArray = colorRangeArray;
    [self refreshColorRange];
    [self setNeedsDisplay];
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    _lineBreakMode = lineBreakMode;
    [self setNeedsDisplay];
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    _numberOfLines = numberOfLines;
    [self setNeedsDisplay];
}

#pragma mark - attribute

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
    [_attributedString addAttribute:NSParagraphStyleAttributeName
                              value:paragraphStyle
                              range:NSMakeRange(0, _attributedString.string.length)];
}

typedef struct CustomGlyphMetrics {
    CGFloat ascent;
    CGFloat descent;
    CGFloat width;
} CustomGlyphMetrics, *CustomGlyphMetricsRef;

static CGFloat ascentCallback(void *refCon) {
    CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
    return metrics->ascent;
}

static CGFloat descentCallback(void *refCon) {
    CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
    return metrics->descent;
}

static CGFloat widthCallback(void *refCon) {
    CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
    return metrics->width;
}


- (void)insertImageAttributedString
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:self.imagePatternString options:kNilOptions error:NULL];
    NSArray<NSTextCheckingResult *> *emoticonResults = [regex matchesInString:_text options:kNilOptions range:NSMakeRange(0, _text.length)];
    
    NSUInteger emoClipLength = 0;
    for (NSTextCheckingResult *emo in emoticonResults) {
        CTRunDelegateCallbacks callBacks;
        memset(&callBacks,0,sizeof(CTRunDelegateCallbacks));
        callBacks.version = kCTRunDelegateVersion1;
        callBacks.getAscent = ascentCallback;
        callBacks.getDescent = descentCallback;
        callBacks.getWidth = widthCallback;
        
        CustomGlyphMetricsRef metrics = malloc(sizeof(CustomGlyphMetrics));
        metrics->width = 20 * 13/14;
        metrics->ascent = 18;
        metrics->descent = 2;
        CTRunDelegateRef delegate = CTRunDelegateCreate(&callBacks, metrics);
        unichar placeHolder = 0xFFFC;
        NSString * placeHolderStr = [NSString stringWithCharacters:&placeHolder length:1];
        
        NSRange replaceRange = NSMakeRange(emo.range.location + emoClipLength, emo.range.length);
        [_attributedString replaceCharactersInRange:replaceRange withAttributedString:[[NSAttributedString alloc] initWithString:placeHolderStr]];
        CFAttributedStringSetAttribute((CFMutableAttributedStringRef)_attributedString, CFRangeMake(replaceRange.location, 1), kCTRunDelegateAttributeName, delegate);
        
        NSString *value = self.imageDictionary[[_text substringWithRange:emo.range]];
        if (value) {
            [_attributedString addAttribute:kCustomGlyphAttributeImageName
                                      value:value
                                      range:NSMakeRange(replaceRange.location, 1)];
        }
        emoClipLength += emo.range.length;
    }
}


#pragma mark - draw

- (void)drawRect:(CGRect)rect
{
    if (_attributedString) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        /*翻转坐标*/
 
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);

        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, rect);
        
        CTFramesetterRef framesetter =  CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attributedString);
        _framesetter = framesetter;
        CTFrameRef frameRef = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, _attributedString.string.length), path, NULL);
        _frameRef = frameRef;
        [self drawTouchBackground:context];
        [self drawImage:context];
        [self drawText:context];
        CGContextRestoreGState(context);
    }
}

- (void)drawImage:(CGContextRef)context
{
    NSArray * arrLines = (NSArray *)CTFrameGetLines(_frameRef);
    NSInteger count = [arrLines count];
    CGPoint points[count];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, 0), points);

    NSInteger lineCount = count;
    if (_numberOfLines > 0) {
        lineCount = MIN(_numberOfLines, lineCount);
    }
    for (int i = 0; i < lineCount; i ++) {
        CTLineRef line = (__bridge CTLineRef)arrLines[i];
        NSArray * arrGlyphRun = (NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < arrGlyphRun.count; j ++) {
            CTRunRef run = (__bridge CTRunRef)arrGlyphRun[j];
            NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (delegate == nil) {
                continue;
            }
            NSString *imageName = [attributes valueForKey:kCustomGlyphAttributeImageName];
            CGPoint point = points[i];
            CGFloat ascent;
            CGFloat descent;
            CGRect boundsRun;
            boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            boundsRun.size.height = ascent + descent;
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
            boundsRun.origin.x = point.x + xOffset;
            boundsRun.origin.y = point.y - descent;
            CGPathRef path = CTFrameGetPath(_frameRef);
            CGRect colRect = CGPathGetBoundingBox(path);
            CGRect imageBounds = CGRectOffset(boundsRun, colRect.origin.x, colRect.origin.y);
            UIImage * image = [UIImage imageNamed:imageName];
            CGContextDrawImage(context,imageBounds, image.CGImage);
        }
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
        NSInteger lineCount = CFArrayGetCount(lines);
        if (_numberOfLines > 0) {
            lineCount = MIN(_numberOfLines, lineCount);
        }
        for (int i = 0; i < lineCount; i++) {
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

- (void)drawText:(CGContextRef)context
{
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    CGPoint lineOrigins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, 0), lineOrigins);
    NSInteger drawCount = (NSInteger)CFArrayGetCount(lines);
    if (_numberOfLines > 0 && _numberOfLines < drawCount) {
        drawCount = _numberOfLines;
        for (int i = 0; i < drawCount; i++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            CGPoint lineOrigin = lineOrigins[i];
            //                CGRect bounds = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
            CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
            if (i == drawCount - 1 && _lineBreakMode == NSLineBreakByTruncatingTail) {
                NSAttributedString *truncatedString = [[NSAttributedString alloc] initWithString:@"\u2026"];
                CTLineRef token = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncatedString);
                CFRange lastLineRange = CTLineGetStringRange(line);
                NSMutableAttributedString *subAttributedString = [[_attributedString attributedSubstringFromRange:NSMakeRange((NSUInteger)lastLineRange.location, (NSUInteger)lastLineRange.length)] mutableCopy];
                [subAttributedString appendAttributedString:truncatedString];
                line = CTLineCreateTruncatedLine(CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)subAttributedString), self.frame.size.width, kCTLineTruncationEnd, token);
            }
            CTLineDraw(line, context);
        }
    } else {
        if (_lineBreakMode == NSLineBreakByTruncatingTail) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, drawCount - 1);
            CFRange lastLineRange = CTLineGetStringRange(line);
            NSMutableAttributedString *tempAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:_attributedString];
            
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineBreakMode = _lineBreakMode;
            [tempAttributedString addAttribute:NSParagraphStyleAttributeName
                                         value:paragraphStyle
                                         range:NSMakeRange(lastLineRange.location, lastLineRange.length)];
            CTFramesetterRef framesetter =  CTFramesetterCreateWithAttributedString((CFAttributedStringRef)tempAttributedString);
            CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, tempAttributedString.string.length), CTFrameGetPath(_frameRef), NULL);
            CTFrameDraw(frameRef, context);
        } else {
            CTFrameDraw(_frameRef, context);
        }
    }
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
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter, CFRangeMake(0, (CFIndex)(_attributedString.string.length)), NULL, targetSize, NULL);
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

- (NSDictionary *)imageDictionary
{
    if (!_imageDictionary) {
        _imageDictionary = @{@"[微笑]":@"weixiao.gif",@"[白眼]":@"baiyan.gif"};
    }
    return _imageDictionary;
}

- (NSString *)imagePatternString
{
    if (!_imagePatternString) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        [self.imageDictionary.allKeys enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
            NSString *temp = [str stringByReplacingOccurrencesOfString:@"]" withString:@""];
            temp = [NSString stringWithFormat:@"\\%@\\]",temp];
            [arr addObject:temp];
        }];
        _imagePatternString = [arr componentsJoinedByString:@"|"];
    }
    return _imagePatternString;
}
@end

//
//  HeliumMarqueeLabel.mm
//  Helium
//
//  Danmaku-style horizontal scroller built on top of UILabel.
//  The label itself stays a plain fixed-size view, the text is drawn with a
//  moving offset inside its bounds, so the scrolling window is exactly the
//  label frame (controlled by the widget set's scale / scaleY / anchor).
//

#import "HeliumMarqueeLabel.h"

#include <math.h>

/// Shared clock so the label and its mask twin stay in phase.
static NSTimeInterval gHeliumMarqueeClock = 0;

@implementation HeliumMarqueeLabel {
    NSTimer *_frameTimer;
    NSAttributedString *_cachedDrawString;
    CGSize _cachedDrawSize;
    NSString *_cachedCacheKey;
}

#pragma mark - Clock

+ (void)resetMarqueeClock
{
    gHeliumMarqueeClock = CACurrentMediaTime();
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _marqueeEnabled = NO;
        _marqueeSpeed = 30.0;
        _marqueeGap = 24.0;
        _marqueeDirection = 0;
        _cachedDrawSize = CGSizeZero;
    }
    return self;
}

- (void)dealloc
{
    [_frameTimer invalidate];
    _frameTimer = nil;
}

#pragma mark - Configuration

- (void)configureMarqueeEnabled:(BOOL)enabled
                          speed:(CGFloat)speed
                            gap:(CGFloat)gap
                      direction:(NSInteger)direction
{
    BOOL needsRedraw = NO;

    if (_marqueeEnabled != enabled) {
        _marqueeEnabled = enabled;
        needsRedraw = YES;
    }
    if (fabs(_marqueeSpeed - speed) > 0.01) {
        _marqueeSpeed = speed;
        needsRedraw = YES;
    }
    if (fabs(_marqueeGap - gap) > 0.01) {
        _marqueeGap = gap;
        needsRedraw = YES;
    }
    if (_marqueeDirection != direction) {
        _marqueeDirection = direction;
        needsRedraw = YES;
    }

    if (_marqueeEnabled) {
        if (gHeliumMarqueeClock <= 0) {
            gHeliumMarqueeClock = CACurrentMediaTime();
        }
        [self startFrameTimer];
    } else {
        [self stopFrameTimer];
    }

    if (needsRedraw) {
        [self setNeedsDisplay];
    }
}

#pragma mark - Frame driver

- (void)startFrameTimer
{
    if (_frameTimer) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    _frameTimer = [NSTimer timerWithTimeInterval:(1.0 / 30.0)
                                         repeats:YES
                                           block:^(NSTimer *timer) {
        HeliumMarqueeLabel *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (!strongSelf.marqueeEnabled || strongSelf.hidden || strongSelf.window == nil) {
            return;
        }
        [strongSelf setNeedsDisplay];
    }];
    [[NSRunLoop mainRunLoop] addTimer:_frameTimer forMode:NSRunLoopCommonModes];
}

- (void)stopFrameTimer
{
    if (!_frameTimer) {
        return;
    }
    [_frameTimer invalidate];
    _frameTimer = nil;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (self.window && self.marqueeEnabled) {
        [self startFrameTimer];
    } else {
        [self stopFrameTimer];
    }
}

#pragma mark - Cache

- (void)invalidateMarqueeCache
{
    _cachedDrawString = nil;
    _cachedCacheKey = nil;
    _cachedDrawSize = CGSizeZero;
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self invalidateMarqueeCache];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self invalidateMarqueeCache];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self invalidateMarqueeCache];
}

/// Returns the string that should be measured / drawn, with the label font
/// applied when the attributed string does not carry one.
- (NSAttributedString *)marqueeDrawString
{
    NSAttributedString *attr = self.attributedText;
    if (attr.length == 0) {
        return attr;
    }
    UIFont *font = self.font ?: [UIFont systemFontOfSize:12.0];
    NSString *key = [NSString stringWithFormat:@"%lu|%@|%.2f",
                     (unsigned long)attr.length,
                     font.fontName ?: @"",
                     font.pointSize];
    if (_cachedDrawString && _cachedCacheKey && [_cachedCacheKey isEqualToString:key]) {
        return _cachedDrawString;
    }

    NSAttributedString *result = attr;
    id fontAttribute = [attr attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    if (!fontAttribute) {
        NSMutableAttributedString *copy = [attr mutableCopy];
        [copy addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, copy.length)];
        result = copy;
    }

    CGRect bounds = [result boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                         options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                         context:nil];
    _cachedDrawSize = CGSizeMake(ceil(bounds.size.width) + 2.0, ceil(bounds.size.height));
    _cachedDrawString = result;
    _cachedCacheKey = key;
    return result;
}

#pragma mark - Drawing

- (void)drawTextInRect:(CGRect)rect
{
    NSAttributedString *attr = self.attributedText;
    if (!self.marqueeEnabled || attr.length == 0) {
        [super drawTextInRect:rect];
        return;
    }

    NSAttributedString *drawString = [self marqueeDrawString];
    CGSize contentSize = _cachedDrawSize;
    if (contentSize.width <= 0 || rect.size.width <= 0) {
        [super drawTextInRect:rect];
        return;
    }

    // Text fits entirely -> nothing to scroll, keep native rendering.
    if (contentSize.width <= rect.size.width + 0.5) {
        [super drawTextInRect:rect];
        return;
    }

    CGFloat gap = MAX(self.marqueeGap, 0.0);
    CGFloat period = contentSize.width + gap;
    if (period <= 0) {
        [super drawTextInRect:rect];
        return;
    }

    if (gHeliumMarqueeClock <= 0) {
        gHeliumMarqueeClock = CACurrentMediaTime();
    }
    NSTimeInterval elapsed = CACurrentMediaTime() - gHeliumMarqueeClock;
    if (elapsed < 0) {
        elapsed = 0;
    }

    CGFloat speed = MAX(self.marqueeSpeed, 1.0);
    CGFloat offset = (CGFloat)fmod((double)speed * (double)elapsed, (double)period);

    CGFloat startX = (self.marqueeDirection == 1) ? (offset - period) : (-offset);
    CGFloat y = rect.origin.y + (rect.size.height - contentSize.height) * 0.5;
    if (y < rect.origin.y) {
        y = rect.origin.y;
    }

    CGFloat rightEdge = rect.origin.x + rect.size.width;
    CGFloat x = rect.origin.x + startX;
    NSInteger guard = 0;
    while (x < rightEdge && guard < 64) {
        @autoreleasepool {
            [drawString drawAtPoint:CGPointMake(x, y)];
        }
        x += period;
        guard++;
    }
}

@end
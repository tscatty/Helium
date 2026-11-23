//
//  HeliumMarqueeLabel.h
//  Helium
//
//  A UILabel subclass that scrolls its text horizontally inside its own
//  bounds, like a danmaku / marquee. The scroll window is the label frame
//  itself, so the visible range is controlled by the widget set's
//  scale / scaleY / anchor values.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HeliumMarqueeLabel : UILabel

/// YES when the text should scroll. NO makes the label behave like a normal UILabel.
@property (nonatomic, assign) BOOL marqueeEnabled;
/// Scroll speed in points per second.
@property (nonatomic, assign) CGFloat marqueeSpeed;
/// Blank gap inserted between two copies of the text.
@property (nonatomic, assign) CGFloat marqueeGap;
/// 0 = right to left (default), 1 = left to right.
@property (nonatomic, assign) NSInteger marqueeDirection;

/// Configure all marquee options at once. Safe to call on every refresh tick.
- (void)configureMarqueeEnabled:(BOOL)enabled
                          speed:(CGFloat)speed
                            gap:(CGFloat)gap
                      direction:(NSInteger)direction;

/// Restart the shared clock so every label in the HUD starts from the same phase.
+ (void)resetMarqueeClock;

@end

NS_ASSUME_NONNULL_END
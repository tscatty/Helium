//
//  HeliumImageView.h
//  Helium
//
//  Displays a user picked image inside the widget set frame.
//  The visible size and position are the frame itself (scale / scaleY /
//  anchor / offsets of the widget set), the image is scaled to fill or fit.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HeliumImageContentMode) {
    HeliumImageContentModeFill = 0,   // aspect fill, crops the overflow
    HeliumImageContentModeFit = 1,    // aspect fit, letterboxed
};

@interface HeliumImageView : UIView

@property (nonatomic, assign) HeliumImageContentMode imageContentMode;
@property (nonatomic, assign) CGFloat cornerRadiusValue;
@property (nonatomic, assign) BOOL circular;

- (void)configureWithFile:(NSString *)fileName
              contentMode:(HeliumImageContentMode)contentMode
             cornerRadius:(CGFloat)cornerRadius
                 circular:(BOOL)circular;

/// Directory (inside the app container) that keeps the picked images.
+ (NSString *)imagesDirectory;
/// Absolute path for a stored image file name.
+ (nullable NSString *)pathForImageFile:(NSString *)fileName;
/// Drops the in-memory image cache.
+ (void)clearImageCache;

@end

NS_ASSUME_NONNULL_END
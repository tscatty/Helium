//
//  HeliumImageView.mm
//  Helium
//
//  Static image renderer for the HUD. Images live in Documents/HeliumImages
//  so the HUD process (same container as the settings app) can read them.
//  Loading is cached: the file is only re-read when the file name changes.
//

#import "HeliumImageView.h"

static NSString * const kHeliumImageFolder = @"HeliumImages";
static NSCache<NSString *, UIImage *> *gImageCache = nil;

@interface HeliumImageView ()
+ (nullable UIImage *)cachedImageForFile:(NSString *)fileName;
@end

@implementation HeliumImageView {
    UIImageView *_imageView;
    NSString *_currentFileName;
}

#pragma mark - Storage helpers

+ (NSString *)imagesDirectory
{
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (documents.length == 0) {
        return nil;
    }
    NSString *directory = [documents stringByAppendingPathComponent:kHeliumImageFolder];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    return directory;
}

+ (NSString *)pathForImageFile:(NSString *)fileName
{
    if (fileName.length == 0) {
        return nil;
    }
    NSString *directory = [self imagesDirectory];
    if (directory.length == 0) {
        return nil;
    }
    return [directory stringByAppendingPathComponent:fileName];
}

+ (void)clearImageCache
{
    [gImageCache removeAllObjects];
}

+ (UIImage *)cachedImageForFile:(NSString *)fileName
{
    if (fileName.length == 0) {
        return nil;
    }
    if (!gImageCache) {
        gImageCache = [[NSCache alloc] init];
        gImageCache.countLimit = 8;
    }
    UIImage *cached = [gImageCache objectForKey:fileName];
    if (cached) {
        return cached;
    }
    NSString *path = [self pathForImageFile:fileName];
    if (path.length == 0) {
        return nil;
    }
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (image) {
        [gImageCache setObject:image forKey:fileName];
    }
    return image;
}

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;

        _imageContentMode = HeliumImageContentModeFill;
        _cornerRadiusValue = 0.0;
        _circular = NO;

        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _imageView.frame = self.bounds;
    [self applyCornerRadius];
}

- (void)applyCornerRadius
{
    CGFloat radius = self.circular ? MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2.0
                                   : MAX(self.cornerRadiusValue, 0.0);
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = YES;
    _imageView.layer.cornerRadius = radius;
    _imageView.layer.masksToBounds = YES;
    if (self.circular) {
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

#pragma mark - Configuration

- (void)configureWithFile:(NSString *)fileName
              contentMode:(HeliumImageContentMode)contentMode
             cornerRadius:(CGFloat)cornerRadius
                 circular:(BOOL)circular
{
    self.imageContentMode = contentMode;
    self.cornerRadiusValue = cornerRadius;
    self.circular = circular;

    _imageView.contentMode = (self.circular || contentMode == HeliumImageContentModeFill)
        ? UIViewContentModeScaleAspectFill
        : UIViewContentModeScaleAspectFit;

    if (![fileName isEqualToString:_currentFileName ?: @""]) {
        _currentFileName = [fileName copy];
        UIImage *image = [[self class] cachedImageForFile:fileName];
        _imageView.image = image;
    } else if (_imageView.image == nil && fileName.length > 0) {
        _imageView.image = [[self class] cachedImageForFile:fileName];
    }

    [self applyCornerRadius];
}

@end
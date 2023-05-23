#import "InCallQualityView.h"

@interface InCallQualityView ()

@property (strong) UIView* greenBar;
@property (strong) UIView* redBar;

@end

@implementation InCallQualityView
{
    NSInteger _quality;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _quality = -1;

        _greenBar = [[UIView alloc] initWithFrame:CGRectZero];
        _redBar = [[UIView alloc] initWithFrame:CGRectZero];
        
        _greenBar.backgroundColor = [UIColor greenColor];
        _redBar.backgroundColor = [UIColor redColor];
        
        [self addSubview:_greenBar];
        [self addSubview:_redBar];
    }
    return self;
}

- (void) setQuality:(NSInteger)quality
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_quality = quality;
        [self setNeedsLayout];
        [UIView animateWithDuration:0.5 animations:^{
            [self layoutIfNeeded];
        }];
    });
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGSize size = self.frame.size;
    CGFloat width = size.width;
    CGFloat height = size.height;

    CGFloat greenWidth = (_quality == -1 ? 0 : width * (self.quality / 100.0));
    CGFloat redWidth = (_quality == -1 ? 0 : width - greenWidth);

    self.greenBar.frame = CGRectMake(0, 0, greenWidth, height);
    self.redBar.frame = CGRectMake(greenWidth, 0, redWidth, height);
}

@end

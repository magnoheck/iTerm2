//
//  iTermStatusBarMemoryUtilizationComponent.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 7/21/18.
//

#import "iTermStatusBarMemoryUtilizationComponent.h"

#import "iTermMemoryUtilization.h"

#import "NSDictionary+iTerm.h"
#import "NSStringITerm.h"
#import "NSView+iTerm.h"

static const NSInteger iTermStatusBarMemoryUtilizationComponentMaximumNumberOfSamples = 60;
static const CGFloat iTermMemoryUtilizationWidth = 120;

NS_ASSUME_NONNULL_BEGIN

@implementation iTermStatusBarMemoryUtilizationComponent {
    NSMutableArray<NSNumber *> *_samples;
}

- (instancetype)initWithConfiguration:(NSDictionary<iTermStatusBarComponentConfigurationKey,id> *)configuration {
    self = [super initWithConfiguration:configuration];
    if (self) {
        _samples = [NSMutableArray array];
        __weak __typeof(self) weakSelf = self;
        [[iTermMemoryUtilization sharedInstance] addSubscriber:self block:^(long long value) {
            [weakSelf update:value];
        }];
    }
    return self;
}

- (NSString *)statusBarComponentShortDescription {
    return @"Memory Utilization";
}

- (NSString *)statusBarComponentDetailedDescription {
    return @"Shows current memory utilization.";
}

- (id)statusBarComponentExemplar {
    return @"3.1 GB ▂▃▃▅ RAM";
}

- (BOOL)statusBarComponentCanStretch {
    return NO;
}

- (NSTimeInterval)statusBarComponentUpdateCadence {
    return 1;
}

- (CGFloat)statusBarComponentMinimumWidth {
    return iTermMemoryUtilizationWidth;
}

- (CGFloat)statusBarComponentPreferredWidth {
    return iTermMemoryUtilizationWidth;
}

- (NSArray<NSNumber *> *)values {
    return _samples;
}

- (long long)currentEstimate {
    return  _samples.lastObject.doubleValue * [[iTermMemoryUtilization sharedInstance] availableMemory];
}

- (void)drawTextWithRect:(NSRect)rect
                    left:(NSString *)left
                   right:(NSString *)right
               rightSize:(CGSize)rightSize {
    NSRect textRect = rect;
    textRect.size.height = rightSize.height;
    textRect.origin.y = (self.view.bounds.size.height - rightSize.height) / 2.0;
    [left drawInRect:textRect withAttributes:self.leftAttributes];
    [right drawInRect:textRect withAttributes:self.rightAttributes];
}

- (NSRect)graphRectForRect:(NSRect)rect
                  leftSize:(CGSize)leftSize
                 rightSize:(CGSize)rightSize {
    NSRect graphRect = rect;
    const CGFloat margin = 4;
    CGFloat rightWidth = rightSize.width + margin;
    CGFloat leftWidth = leftSize.width + margin;
    graphRect.origin.x += leftWidth;
    graphRect.size.width -= (leftWidth + rightWidth);
    graphRect = NSInsetRect(graphRect, 0, [self.view retinaRound:-self.font.descender]);

    return graphRect;
}

- (NSFont *)font {
    static NSFont *font;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        font = [NSFont fontWithName:@"Menlo" size:12];
    });
    return font;
}

- (NSDictionary *)leftAttributes {
    static NSDictionary *leftAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *leftAlignStyle =
        [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [leftAlignStyle setAlignment:NSTextAlignmentLeft];
        [leftAlignStyle setLineBreakMode:NSLineBreakByTruncatingTail];

        leftAttributes = @{ NSParagraphStyleAttributeName: leftAlignStyle,
                            NSFontAttributeName: self.font,
                            NSForegroundColorAttributeName: [NSColor blackColor] };
    });
    return leftAttributes;
}

- (NSDictionary *)rightAttributes {
    static NSDictionary *rightAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *rightAlignStyle =
        [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [rightAlignStyle setAlignment:NSTextAlignmentRight];
        [rightAlignStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        rightAttributes = @{ NSParagraphStyleAttributeName: rightAlignStyle,
                             NSFontAttributeName: self.font,
                             NSForegroundColorAttributeName: [NSColor blackColor] };
    });
    return rightAttributes;
}

- (CGSize)rightSize {
    return [self.rightText sizeWithAttributes:self.rightAttributes];
}

- (NSString *)leftText {
    return [NSString it_formatBytes:self.currentEstimate];
}

- (NSString *)rightText {
    return @"RAM";
}

- (void)drawRect:(NSRect)rect {
    CGSize rightSize = self.rightSize;

    [self drawTextWithRect:rect
                      left:self.leftText
                     right:self.rightText
                 rightSize:rightSize];

    NSRect graphRect = [self graphRectForRect:rect
                                     leftSize:[self.leftText sizeWithAttributes:self.leftAttributes]
                                    rightSize:rightSize];

    [super drawRect:graphRect];
}

#pragma mark - Private

- (void)update:(double)value {
    double available = [[iTermMemoryUtilization sharedInstance] availableMemory];
    [_samples addObject:@(value / available)];
    while (_samples.count > iTermStatusBarMemoryUtilizationComponentMaximumNumberOfSamples) {
        [_samples removeObjectAtIndex:0];
    }
    [self invalidate];
}

@end

NS_ASSUME_NONNULL_END

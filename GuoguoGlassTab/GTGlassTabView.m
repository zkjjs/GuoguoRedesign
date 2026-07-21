#import "GTGlassTabView.h"

#import "Layout/GTLayout.h"

@interface GTBottomMaskView : UIView
@property (nonatomic, assign) CGRect cutoutRect;
@end

@implementation GTBottomMaskView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)setCutoutRect:(CGRect)cutoutRect {
    _cutoutRect = cutoutRect;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }

    CGFloat bandTop = MAX(0.0, CGRectGetMinY(self.cutoutRect) - 10.0);
    CGRect bottomBand = CGRectMake(0.0, bandTop, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - bandTop);
    CGContextSetFillColorWithColor(context, UIColor.blackColor.CGColor);
    CGContextFillRect(context, bottomBand);

    CGContextSetBlendMode(context, kCGBlendModeClear);
    UIBezierPath *hole = [UIBezierPath bezierPathWithRoundedRect:self.cutoutRect cornerRadius:CGRectGetHeight(self.cutoutRect) / 2.0];
    [hole fill];
}

@end


@interface GTGlassTabView ()
@property (nonatomic, strong) GTBottomMaskView *bottomMaskView;
@property (nonatomic, strong) UIVisualEffectView *materialView;
@property (nonatomic, strong) NSArray<UIImageView *> *iconViews;
@property (nonatomic, strong) NSArray<UILabel *> *titleLabels;
@property (nonatomic, copy) NSArray<NSString *> *regularSymbols;
@property (nonatomic, copy) NSArray<NSString *> *selectedSymbols;
@property (nonatomic, readwrite) CGRect capsuleFrame;
@end

@implementation GTGlassTabView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.backgroundColor = UIColor.clearColor;
    self.opaque = NO;
    self.userInteractionEnabled = NO;
    self.accessibilityElementsHidden = YES;

    _bottomMaskView = [[GTBottomMaskView alloc] initWithFrame:self.bounds];
    [self addSubview:_bottomMaskView];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    _materialView = [[UIVisualEffectView alloc] initWithEffect:blur];
    _materialView.userInteractionEnabled = NO;
    _materialView.clipsToBounds = YES;
    _materialView.layer.borderWidth = 0.5;
    _materialView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    _materialView.layer.shadowColor = UIColor.blackColor.CGColor;
    _materialView.layer.shadowOpacity = 0.28;
    _materialView.layer.shadowRadius = 18.0;
    _materialView.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    _materialView.layer.masksToBounds = NO;
    [self addSubview:_materialView];

    UIView *tintView = [[UIView alloc] initWithFrame:CGRectZero];
    tintView.translatesAutoresizingMaskIntoConstraints = NO;
    tintView.backgroundColor = [UIColor colorWithWhite:0.04 alpha:0.42];
    tintView.userInteractionEnabled = NO;
    [_materialView.contentView addSubview:tintView];
    [NSLayoutConstraint activateConstraints:@[
        [tintView.leadingAnchor constraintEqualToAnchor:_materialView.contentView.leadingAnchor],
        [tintView.trailingAnchor constraintEqualToAnchor:_materialView.contentView.trailingAnchor],
        [tintView.topAnchor constraintEqualToAnchor:_materialView.contentView.topAnchor],
        [tintView.bottomAnchor constraintEqualToAnchor:_materialView.contentView.bottomAnchor],
    ]];

    NSArray<NSString *> *titles = @[@"发现", @"频道", @"任务", @"我的"];
    _regularSymbols = @[@"safari", @"play.rectangle", @"checkmark.square", @"person"];
    _selectedSymbols = @[@"safari.fill", @"play.rectangle.fill", @"checkmark.square.fill", @"person.fill"];

    NSMutableArray<UIImageView *> *icons = [NSMutableArray arrayWithCapacity:4];
    NSMutableArray<UILabel *> *labels = [NSMutableArray arrayWithCapacity:4];
    for (NSInteger index = 0; index < 4; index++) {
        UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectZero];
        icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:19.0 weight:UIImageSymbolWeightMedium];
        [_materialView.contentView addSubview:icon];
        [icons addObject:icon];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.text = titles[index];
        label.font = [UIFont systemFontOfSize:10.5 weight:UIFontWeightSemibold];
        label.textAlignment = NSTextAlignmentCenter;
        label.adjustsFontForContentSizeCategory = YES;
        [_materialView.contentView addSubview:label];
        [labels addObject:label];
    }
    _iconViews = icons;
    _titleLabels = labels;
    _selectedIndex = 0;
    [self refreshSelectionAnimated:NO];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.bottomMaskView.frame = self.bounds;

    UIEdgeInsets safe = self.safeAreaInsets;
    GTRect layout = GTContainerRect(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds), safe.bottom);
    self.capsuleFrame = CGRectMake(layout.x, layout.y, layout.width, layout.height);
    self.bottomMaskView.cutoutRect = self.capsuleFrame;
    self.materialView.frame = self.capsuleFrame;
    self.materialView.layer.cornerRadius = CGRectGetHeight(self.capsuleFrame) / 2.0;
    if (@available(iOS 13.0, *)) {
        self.materialView.layer.cornerCurve = kCACornerCurveContinuous;
    }

    CGFloat itemWidth = CGRectGetWidth(self.materialView.bounds) / 4.0;
    for (NSInteger index = 0; index < 4; index++) {
        CGFloat originX = itemWidth * index;
        self.iconViews[index].frame = CGRectMake(originX + (itemWidth - 24.0) / 2.0, 9.0, 24.0, 24.0);
        self.titleLabels[index].frame = CGRectMake(originX, 36.0, itemWidth, 17.0);
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    NSInteger clamped = MIN(3, MAX(0, selectedIndex));
    if (_selectedIndex == clamped && animated) {
        return;
    }
    _selectedIndex = clamped;
    [self refreshSelectionAnimated:animated];
}

- (void)refreshSelectionAnimated:(BOOL)animated {
    void (^changes)(void) = ^{
        for (NSInteger index = 0; index < 4; index++) {
            BOOL selected = index == self.selectedIndex;
            UIColor *color = selected ? UIColor.systemBlueColor : UIColor.secondaryLabelColor;
            NSString *symbol = selected ? self.selectedSymbols[index] : self.regularSymbols[index];
            self.iconViews[index].image = [[UIImage systemImageNamed:symbol] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.iconViews[index].tintColor = color;
            self.titleLabels[index].textColor = color;
            self.iconViews[index].transform = selected ? CGAffineTransformMakeScale(1.04, 1.04) : CGAffineTransformIdentity;
        }
    };

    if (animated && !UIAccessibilityIsReduceMotionEnabled()) {
        [UIView animateWithDuration:0.28 delay:0.0 usingSpringWithDamping:0.86 initialSpringVelocity:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:changes completion:nil];
    } else {
        changes();
    }
}

- (NSInteger)tabIndexForPoint:(CGPoint)point {
    if (!CGRectContainsPoint(self.capsuleFrame, point)) {
        return NSNotFound;
    }
    CGFloat localX = point.x - CGRectGetMinX(self.capsuleFrame);
    return GTTabIndexForX(localX, CGRectGetWidth(self.capsuleFrame));
}

@end


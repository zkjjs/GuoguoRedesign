#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GTGlassTabView : UIView

@property (nonatomic, readonly) CGRect capsuleFrame;
@property (nonatomic, assign) NSInteger selectedIndex;

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated;
- (NSInteger)tabIndexForPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END


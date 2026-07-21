#import <UIKit/UIKit.h>

#import "GTGlassTabView.h"

static const NSInteger GTGlassOverlayTag = 0x47544754;
static __weak GTGlassTabView *GTActiveOverlay;

static BOOL GTIsFLEXObject(id object) {
    NSString *name = NSStringFromClass([object class]);
    return [name rangeOfString:@"FLEX" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static void GTHideFLEXWindows(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (GTIsFLEXObject(window) || GTIsFLEXObject(window.rootViewController)) {
                window.hidden = YES;
            }
        }
    }
}

static GTGlassTabView *GTInstallOverlay(UIViewController *controller) {
    GTGlassTabView *overlay = (GTGlassTabView *)[controller.view viewWithTag:GTGlassOverlayTag];
    if (![overlay isKindOfClass:GTGlassTabView.class]) {
        overlay = [[GTGlassTabView alloc] initWithFrame:controller.view.bounds];
        overlay.tag = GTGlassOverlayTag;
        overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [controller.view addSubview:overlay];
    }
    overlay.frame = controller.view.bounds;
    [controller.view bringSubviewToFront:overlay];
    GTActiveOverlay = overlay;
    return overlay;
}

%hook FlutterViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    GTInstallOverlay((UIViewController *)self);
    GTHideFLEXWindows();
}

- (void)viewDidLayoutSubviews {
    %orig;
    GTGlassTabView *overlay = GTInstallOverlay((UIViewController *)self);
    [overlay setNeedsLayout];
    [overlay layoutIfNeeded];
}

%end

%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    %orig;

    GTGlassTabView *overlay = GTActiveOverlay;
    if (!overlay || overlay.hidden || event.type != UIEventTypeTouches) {
        return;
    }

    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseEnded) {
            continue;
        }
        CGPoint point = [touch locationInView:overlay];
        NSInteger index = [overlay tabIndexForPoint:point];
        if (index != NSNotFound) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [overlay setSelectedIndex:index animated:YES];
            });
        }
    }
}

%end

%hook UIWindow

- (void)setHidden:(BOOL)hidden {
    if (GTIsFLEXObject(self) || GTIsFLEXObject(self.rootViewController)) {
        %orig(YES);
        return;
    }
    %orig(hidden);
}

- (void)makeKeyAndVisible {
    if (GTIsFLEXObject(self) || GTIsFLEXObject(self.rootViewController)) {
        self.hidden = YES;
        return;
    }
    %orig;
}

%end

%ctor {
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.example.dongmangongheguo"]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        GTHideFLEXWindows();
    });
}

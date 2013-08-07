#import <UIKit/UIKit.h>
#import "SpringBoard/SBAwayView.h"
#import "SpringBoard/SpringBoard-Class.h"
#import <QuartzCore/QuartzCore2.h>
#import "SpringBoard/SBUIController.h"
#import "SpringBoard/SBWallpaperView.h"
#import "SpringBoard/SBAwayController.h"
#import "SpringBoard/SBIconController.h"
#import "SettingsHandler.h"
#import "SpringBoard/SBIconListView.h"

#define unlockPlistPath @"/var/mobile/Library/BlurredLockScreen/UnlockPatterns.plist"
#define LOCKSCREEN_IMAGE_VIEW_TAG 19342

SettingsHandler *settings;

@interface SBAwayView (BlurredLockScreen)
-(void)incrementDownWithTime:(float)time;
-(void)animateDown;
@end

//dev vars
BOOL shouldUnlock = NO;

BOOL hasBegunUnlocking;

BOOL unlockCalled;

BOOL locked = YES; // checks if the device is locked

CGPoint currentTouch;
CGPoint lastTouch;
BOOL alreadyFixedBlur;

//user prefs
float animationTime;
float filterValue = 5.0f;

float defaultBlurIntensity;

BOOL enabled;
BOOL hideBottomBar;
BOOL hideClock;

BOOL changeBlurByTouch;
float lockScreenWallpaperAlpha;

//colorization vars

BOOL colorEnabled;
float red;
float green;
float blue;
float alpha;

BOOL hideChargingScreen;
BOOL hideAlbumArtwork;

BOOL canUnlockWithTap;

%hook SBAwayView

#pragma mark Setup

-(id)initWithFrame:(CGRect)frame{
    UIView *orig = %orig;
    alpha = 0.0f;
    if(enabled){
        alreadyFixedBlur = NO;
        [orig setBackgroundColor:[UIColor clearColor]];
        if(hideBottomBar){
            [MSHookIvar<UIView*>(orig, "_lockBar") setHidden:YES]; // for iPhone/iPod
            [MSHookIvar<UIView*>(orig, "_lockBar") setAlpha:0.0f];
            // [MSHookIvar<UIView*>(orig, "_lockBar") removeFromSuperview];
        }
        
        UIImageView *lockScreenImage = [[UIImageView alloc] init];
        [lockScreenImage setUserInteractionEnabled:YES];
        [lockScreenImage setTag:LOCKSCREEN_IMAGE_VIEW_TAG];
        lockScreenImage.layer.shouldRasterize = YES;
        for(unsigned x = 0; x < [[orig subviews] count]; x++){
            if([[NSString stringWithFormat:@"%s",class_getName([[[orig subviews] objectAtIndex:x] class])] isEqualToString:@"SBWallpaperView"]){
                [lockScreenImage setImage:[(SBWallpaperView*)[[orig subviews] objectAtIndex:x] image]];
                [lockScreenImage setFrame:[(SBWallpaperView*)[[orig subviews] objectAtIndex:x] frame]];
                [lockScreenImage.layer setOpacity:lockScreenWallpaperAlpha];
                [self insertSubview:lockScreenImage aboveSubview:[[orig subviews] objectAtIndex:x]];
                [[[orig subviews] objectAtIndex:x] removeFromSuperview];
            }
            else if([[NSString stringWithFormat:@"%s",class_getName([[[orig subviews] objectAtIndex:x] class])] isEqualToString:@"UIWebBrowserView"]){
                [[[orig subviews] objectAtIndex:x] setOpaque:NO];
                [[[orig subviews] objectAtIndex:x] setBackgroundColor:[UIColor clearColor]];
                [[[orig subviews] objectAtIndex:x] setUserInteractionEnabled:NO];
            }
        }
        
        UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
        filterValue = defaultBlurIntensity;
        [filter setValue:[NSNumber numberWithFloat:filterValue] forKey:@"inputRadius"];
        [arr addObject:filter];
        if(colorEnabled){
            CAFilter *colorFilter = [CAFilter filterWithName:@"colorAdd"];
            NSMutableArray *colorArr = [NSMutableArray array];
            [colorArr addObject:[NSNumber numberWithFloat:red]];
            [colorArr addObject:[NSNumber numberWithFloat:green]];
            [colorArr addObject:[NSNumber numberWithFloat:blue]];
            [colorArr addObject:[NSNumber numberWithFloat:alpha]];
            [colorFilter setValue:colorArr forKey:@"inputColor"];
            [arr addObject:colorFilter];
        }
        rootView.layer.filters = arr;
        [arr release];
        [rootView.layer setRasterizationScale:[[UIScreen mainScreen] scale]];
        [rootView.layer setShouldRasterize:YES];
        // [rootView removeFromSuperview];
        currentTouch = CGPointMake(0,0);
        lastTouch = CGPointMake(0,0);
        hasBegunUnlocking = NO;
        unlockCalled = NO;
        shouldUnlock = NO;
    }
    return orig;
}

- (void)didAddSubview:(UIView *)subview{
    %orig;
    if(!enabled)
        return;
    if(([[NSString stringWithFormat:@"%s",class_getName([subview class])] isEqualToString:@"TPLCDView"] && hideClock)){
        [subview removeFromSuperview];
    }
    else if([[NSString stringWithFormat:@"%s",class_getName([subview class])] isEqualToString:@"SBAwayChargingView"] && hideChargingScreen){
        [subview removeFromSuperview];
    }
    else if([[NSString stringWithFormat:@"%s",class_getName([subview class])] isEqualToString:@"UIView"] && hideAlbumArtwork){
        for(UIView *v in subview.subviews){
            if([[NSString stringWithFormat:@"%s",class_getName([v class])] isEqualToString:@"NowPlayingReflectionView"]){
                [subview removeFromSuperview];
                break;

            }
        }
    }
}

#pragma mark TouchHandling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    %orig;
    if(enabled && !hasBegunUnlocking && canUnlockWithTap){
        [self lockBarStartedTracking:nil];
        UITouch *touch = [touches anyObject];
        lastTouch = [touch locationInView:self];
        shouldUnlock = YES;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    %orig;
    if(enabled && changeBlurByTouch && !hasBegunUnlocking){
        UITouch *touch = [touches anyObject];
        currentTouch = [touch locationInView:self];
        float diff = currentTouch.y - lastTouch.y;
        diff*=0.2;
        
        filterValue += diff;
        if(filterValue < 2.0){
            filterValue = 2.0;
        }
        if(filterValue > 20){
            filterValue = 20;
        }
        UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
        
        CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
        [filter setValue:[NSNumber numberWithFloat:filterValue] forKey:@"inputRadius"];
        rootView.layer.filters = [NSArray arrayWithObject:filter];
        
        lastTouch = currentTouch;
    }
    shouldUnlock = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    %orig;
    if(enabled && canUnlockWithTap){
        [self lockBarStoppedTracking:nil];
        // if([[objc_getClass("SBAwayController") sharedAwayController] isPasswordProtected])
        //     [self lockBarUnlocked:nil];
        if(shouldUnlock && !hasBegunUnlocking){
            alreadyFixedBlur = YES;
            UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
            [rootView.layer setShouldRasterize:NO];
            [self incrementDownWithTime:animationTime];
        }
    }
}

#pragma mark HandleUnlock

-(void)lockBarUnlocked:(id)unlocked{
    if(!alreadyFixedBlur && enabled /*&& ![[objc_getClass("SBAwayController") sharedAwayController] isPasswordProtected]*/){
        [self incrementDownWithTime:animationTime];
        alreadyFixedBlur = YES;
    }
    else
        %orig;
}

%new -(void)incrementDownWithTime:(float)time{
    if(!hasBegunUnlocking){
        hasBegunUnlocking = YES;
        UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
        
        CALayer *layer = rootView.layer;
        
        NSMutableArray *animArray = [[NSMutableArray alloc] init];
        NSMutableArray *newFilter = [[NSMutableArray alloc] init];
        
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"filters.gaussianBlur.inputRadius"];
        anim.fromValue = [NSNumber numberWithFloat:filterValue];
        anim.toValue = [NSNumber numberWithFloat:0.0f];
        
        CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
        [filter setValue:[NSNumber numberWithFloat:0.0f] forKey:@"inputRadius"];
        [newFilter addObject:filter];
        
        [animArray addObject:anim];
        
        if(colorEnabled){
            CAFilter *colorFilter = [CAFilter filterWithName:@"colorAdd"];
            NSMutableArray *colorArrs = [NSMutableArray array];
            [colorArrs addObject:[NSNumber numberWithFloat:0.0f]];
            [colorArrs addObject:[NSNumber numberWithFloat:0.0f]];
            [colorArrs addObject:[NSNumber numberWithFloat:0.0f]];
            [colorArrs addObject:[NSNumber numberWithFloat:0.0f]];
            [colorFilter setValue:colorArrs forKey:@"inputColor"];
            [newFilter addObject:colorFilter];
            
            
            NSMutableArray *colorArr = [NSMutableArray array];
            [colorArr addObject:[NSNumber numberWithFloat:red]];
            [colorArr addObject:[NSNumber numberWithFloat:green]];
            [colorArr addObject:[NSNumber numberWithFloat:blue]];
            [colorArr addObject:[NSNumber numberWithFloat:alpha]];
            
            NSMutableArray *blankArr = [NSMutableArray array];
            [blankArr addObject:[NSNumber numberWithFloat:0.0f]];
            [blankArr addObject:[NSNumber numberWithFloat:0.0f]];
            [blankArr addObject:[NSNumber numberWithFloat:0.0f]];
            [blankArr addObject:[NSNumber numberWithFloat:0.0f]];
            
            CABasicAnimation *colorAnim = [CABasicAnimation animationWithKeyPath:@"filters.colorAdd.inputColor"];
            colorAnim.fromValue = colorArr;
            colorAnim.toValue = blankArr;
            [animArray addObject:colorAnim];
        }
        if(lockScreenWallpaperAlpha > 0.0){
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
            anim.fromValue = [NSNumber numberWithFloat:lockScreenWallpaperAlpha];
            anim.toValue = [NSNumber numberWithFloat:0.0f];
            anim.duration = time;
            [[[self viewWithTag:LOCKSCREEN_IMAGE_VIEW_TAG] layer] addAnimation:anim forKey:@"Opacity"];
            [[[self viewWithTag:LOCKSCREEN_IMAGE_VIEW_TAG] layer] setOpacity:0.0f];
        }
        
        CAAnimationGroup *animGroup = [CAAnimationGroup animation];
        animGroup.animations = animArray;
        animGroup.duration = time;
        animGroup.removedOnCompletion = NO;
        [animGroup setDelegate:self];
        [layer addAnimation:animGroup forKey:@"Filters"];
        
        [layer setFilters:newFilter];
        [newFilter release];
        
        [animArray release];
    }
}

%new - (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag{
    UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
    [rootView.layer setShouldRasterize:NO];
    if(!unlockCalled)
        [self lockBarUnlocked:nil];
}

%end

%hook SBAwayController

-(void)_sendToDeviceLockOwnerDeviceUnlockSucceeded{
    %orig;
    if(!alreadyFixedBlur && enabled){
        unlockCalled = YES;
        [MSHookIvar<SBAwayView*>(self,"_awayView") incrementDownWithTime:animationTime];
        alreadyFixedBlur = YES;
    }
}

%end

#pragma mark Prevent icons from moving

%hook SBUIController

- (void)_deviceLockStateChanged:(id)arg{
    NSDictionary *infoDict = [(NSNotification*)arg userInfo];
    BOOL l = [[infoDict objectForKey:@"kSBNotificationKeyState"] boolValue]; //whether or not the device is locked  
    %orig;
    if(enabled && l){
        locked = YES;
        [[self rootView] setAlpha:1.0f];
        int finalIndex = [[[self.rootView superview] subviews] count] - 1;
        [[[[self.rootView superview] subviews] objectAtIndex:finalIndex] setAlpha:0];
        UIScrollView *iconScrollView = [[objc_getClass("SBIconController") sharedInstance] scrollView];
        CGFloat pageWidth = iconScrollView.frame.size.width;
        int page = floor((iconScrollView.contentOffset.x - pageWidth / 2) / pageWidth) - 1;
        if(page != -1){
            if([objc_getClass("SBIconListView") respondsToSelector:@selector(unscatterWithDuration:delay:)]){
                [(SBIconListView*)[iconScrollView.subviews objectAtIndex:page] unscatterWithDuration:0 delay:0];
            }
            else{
                [(SBIconListView*)[iconScrollView.subviews objectAtIndex:page] unscatterWithDuration:0 startTime:0];
            }
        }
        UIView *wallpaperView = MSHookIvar<UIView*>(self, "_wallpaperView");
        UIView *iconsView = MSHookIvar<UIView*>(self, "_iconsView");
        if(!wallpaperView.superview){
            [[self contentView] addSubview:MSHookIvar<UIView*>(self, "_wallpaperView")];
            wallpaperView.alpha = 1.0f;
        }
        if(!iconsView.superview)
            [[self contentView] addSubview:MSHookIvar<UIView*>(self, "_iconsView")];
        [self restoreIconListAnimated:NO animateWallpaper:NO keepSwitcher:NO];
    }
}

-(void)tearDownIconListAndBar{
    if(!enabled)
        %orig;
}

- (void)scatterIconListAndBar:(BOOL)arg1 fade:(BOOL)arg2 animateWallpaper:(BOOL)arg3{
    if(!locked){
        %orig;
    }
    else if(!enabled)
        %orig;
}

- (void)scatterIconListAndBar:(BOOL)arg1{
    if(!locked){
        %orig;
    }
    else if(!enabled)
        %orig;
}

- (void)restoreIconListAnimated:(BOOL)arg1 animateWallpaper:(BOOL)arg2 keepSwitcher:(BOOL)arg3{
    if(locked && enabled){
        %orig(NO,NO,arg3);
    }
    else{
        %orig;
    }
    // locked = NO;
}

%end

%hook SBAwayBulletinListView

-(void)setFrame:(CGRect)frame{
    if(hideClock && enabled)
        %orig(CGRectMake(frame.origin.x,20,frame.size.width,frame.size.height));
    else
        %orig;
}

%end

#pragma mark TweakSetup

static void LoadSettings() {
    [settings updateSettings];
    enabled = [[settings.settingsDict objectForKey:@"kEnabled"] boolValue];
    hideBottomBar = [[settings.settingsDict objectForKey:@"kHideBottomBar"] boolValue];
    hideClock = [[settings.settingsDict objectForKey:@"kHideClock"] boolValue];
    animationTime = [[settings.settingsDict objectForKey:@"kAnimationTime"] floatValue];
    defaultBlurIntensity = [[settings.settingsDict objectForKey:@"kDefaultBlurIntensity"] floatValue];
    changeBlurByTouch = [[settings.settingsDict objectForKey:@"kChangeBlurByTouch"] boolValue];
    lockScreenWallpaperAlpha = [[settings.settingsDict objectForKey:@"kLockScreenWallpaperAlpha"] floatValue];
    colorEnabled = [[settings.settingsDict objectForKey:@"kColorsEnabled"] boolValue];
    red = [[settings.settingsDict objectForKey:@"kRedColor"] floatValue];
    green = [[settings.settingsDict objectForKey:@"kGreenColor"] floatValue];
    blue = [[settings.settingsDict objectForKey:@"kBlueColor"] floatValue];
    hideChargingScreen = [[settings.settingsDict objectForKey:@"kHideChargingScreen"] boolValue];
    hideAlbumArtwork = [[settings.settingsDict objectForKey:@"kHideAlbumArtwork"] boolValue];
    canUnlockWithTap = [[settings.settingsDict objectForKey:@"kUnlockWithTap"] boolValue];
}

static void SettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    LoadSettings();
}

%ctor{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    %init;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, SettingsChanged, CFSTR("com.chancehudson.blurredlockscreen/updated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    settings = [[SettingsHandler alloc] init];
    [settings setPlistPath:@"/var/mobile/Library/Preferences/com.chancehudson.blurredlockscreensettings.plist"];
    LoadSettings();
    [pool drain];
}

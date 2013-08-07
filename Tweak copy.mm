#import <UIKit/UIKit.h>
#import "SpringBoard/SBAwayView.h"
#import "SpringBoard/SpringBoard-Class.h"
#import <QuartzCore/QuartzCore2.h>
#import "SpringBoard/SBUIController.h"
#import "SpringBoard/SBWallpaperView.h"
#import "SettingsHandler.h"

SettingsHandler *settings;



@interface SBAwayView (mine)
-(void)incrementDownWithTime:(float)time;
-(void)animateDown;
@end

//dev vars
BOOL shouldUnlock = NO;

BOOL locked = YES; // checks if the device is locked

BOOL addedViews = NO;

CGPoint currentTouch;
CGPoint lastTouch;
BOOL alreadyFixedBlur;
CADisplayLink *timer;
float incrementValue;
float alphaIncrementValue;
int cycleCount;

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

%hook SBAwayView

-(id)initWithFrame:(CGRect)frame{
    UIView *orig = %orig;
    if(enabled){
        alreadyFixedBlur = NO;
        [orig setBackgroundColor:[UIColor clearColor]];
        if(hideBottomBar){
            [MSHookIvar<UIView*>(orig, "_lockBar") setHidden:YES]; // for iPhone/iPod
            [MSHookIvar<UIView*>(orig, "_lockBar") setAlpha:0.0f];
            [MSHookIvar<UIView*>(orig, "_lockBar") removeFromSuperview];
        }
        
        for(unsigned x = 0; x < [[orig subviews] count]; x++){
            if([[NSString stringWithFormat:@"%s",class_getName([[[orig subviews] objectAtIndex:x] class])] isEqualToString:@"SBWallpaperView"]){
                [[[orig subviews] objectAtIndex:x] removeFromSuperview];
            }
        }
        
        UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
        
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
        filterValue = defaultBlurIntensity;
        [filter setValue:[NSNumber numberWithFloat:filterValue] forKey:@"inputRadius"];
        [arr addObject:filter];
        if(colorEnabled){
            /*CAFilter *colorFilter = [CAFilter filterWithName:@"colorAdd"];
            NSMutableArray *colorArr = [NSMutableArray array];
            [colorArr addObject:[NSNumber numberWithFloat:red]];
            [colorArr addObject:[NSNumber numberWithFloat:green]];
            [colorArr addObject:[NSNumber numberWithFloat:blue]];
            [colorArr addObject:[NSNumber numberWithFloat:alpha]];
            [colorFilter setValue:colorArr forKey:@"inputColor"];
            [arr addObject:colorFilter];
             */
            UIView *colorView = [[UIView alloc] initWithFrame:rootView.frame];
            [colorView setBackgroundColor:[UIColor colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha]];
            [colorView setTag:78192];
            [rootView addSubview:colorView];
            [rootView bringSubviewToFront:colorView];
            [colorView release];
        }
        rootView.layer.filters = arr;
        [arr release];
        [rootView.layer setRasterizationScale:1.0f];
       // [rootView.layer setShouldRasterize:YES];
        currentTouch = CGPointMake(0,0);
        lastTouch = CGPointMake(0,0);
    }
    return orig;
}

-(void)addSubview:(id)view{
    if(![[NSString stringWithFormat:@"%s",class_getName([view class])] isEqualToString:@"TPLCDView"] || !hideClock){
        %orig;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    %orig;
    if(enabled){
        [self lockBarStartedTracking:nil];
        UITouch *touch = [touches anyObject];
        lastTouch = [touch locationInView:self];
        shouldUnlock = YES;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    %orig;
    if(enabled && changeBlurByTouch){
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
    if(enabled){
        [self lockBarStoppedTracking:nil];
        if(shouldUnlock){
            [self incrementDownWithTime:animationTime];
            alreadyFixedBlur = YES;
        }
    }
}

-(void)lockBarUnlocked:(id)unlocked{
    %orig;
    if(!alreadyFixedBlur && enabled){
        [self incrementDownWithTime:animationTime];
        alreadyFixedBlur = YES;
    }
}

%new-(void)incrementDownWithTime:(float)time{
    /*incrementValue = filterValue/(time/(1.0f/60.0f));
    if(colorEnabled){
        cycleCount = 0;
        alphaIncrementValue = 1.0f/(time/(1.0f/60.0f));
    }
    if(timer){
        [timer invalidate];
        timer = nil;
    }
    UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
    [rootView.layer setShouldRasterize:NO];
    timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(animateDown)];
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
     */
    UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
    CALayer *layer = rootView.layer;
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"filters.gaussianBlur.inputRadius"];
    
    anim.duration = time;
    
    anim.fromValue = [NSNumber numberWithFloat:filterValue];
    
    anim.toValue = [NSNumber numberWithFloat:0.0f];
    
    [layer addAnimation:anim forKey:@"filterAnimate"];
    
    CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
    [filter setValue:[NSNumber numberWithFloat:0.0f] forKey:@"inputRadius"];
    layer.filters = [NSArray arrayWithObject:filter];

}

%new-(void)animateDown{
    filterValue -= incrementValue;
    UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
    if(filterValue >= 0){
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
        [filter setValue:[NSNumber numberWithFloat:filterValue] forKey:@"inputRadius"];
        [arr addObject:filter];
        if(colorEnabled){
            cycleCount++;
            /*
            CAFilter *colorFilter = [CAFilter filterWithName:@"colorAdd"];
            NSMutableArray *colorArr = [NSMutableArray array];
            [colorArr addObject:[NSNumber numberWithFloat:red-(redIncrementValue*(float)cycleCount)]];
            [colorArr addObject:[NSNumber numberWithFloat:green-(greenIncrementValue*(float)cycleCount)]];
            [colorArr addObject:[NSNumber numberWithFloat:blue-(blueIncrementValue*(float)cycleCount)]];
            [colorArr addObject:[NSNumber numberWithFloat:alpha]];
            [colorFilter setValue:colorArr forKey:@"inputColor"];
            [arr addObject:colorFilter];
             */
            [[rootView viewWithTag:78192] setAlpha:1.0f-(alphaIncrementValue*cycleCount)];
        }
        rootView.layer.filters = arr;
        [arr release];
    }
    if(filterValue <= 0){
        if(timer){
            [timer invalidate];
            timer = nil;
        }
        if(colorEnabled){
            [[rootView viewWithTag:78192] removeFromSuperview];
        }
        UIView *rootView = [[objc_getClass("SBUIController") sharedInstance] rootView];
        CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
        [filter setValue:[NSNumber numberWithFloat:0.0f] forKey:@"inputRadius"];
        rootView.layer.filters = [NSArray arrayWithObject:filter];
        [self lockBarUnlocked:nil];
    }
}

%end

%hook SBAwayController

-(void)_sendToDeviceLockOwnerDeviceUnlockSucceeded{
    %orig;
    if(!alreadyFixedBlur && enabled){
        [MSHookIvar<SBAwayView*>(self,"_awayView") incrementDownWithTime:animationTime];
        alreadyFixedBlur = YES;
    }
}

%end

%hook SBUIController

- (void)scatterIconListAndBar:(BOOL)arg1 fade:(BOOL)arg2 animateWallpaper:(BOOL)arg3{
    if(!locked){
        %orig;
    }
}

- (void)restoreIconListAnimated:(BOOL)arg1 animateWallpaper:(BOOL)arg2 keepSwitcher:(BOOL)arg3{
    if(locked){
        %orig(NO,NO,arg3);
    }
    else{
        %orig;
    }
    locked = NO;
}

-(void)lockFromSource:(int)source{
    if(enabled){
        [[self rootView] setAlpha:1.0f];
        if([[[self contentView] subviews] count] == 0){
            [[self contentView] addSubview:MSHookIvar<UIView*>(self, "_iconsView")];
            [[self contentView] addSubview:MSHookIvar<UIView*>(self, "_wallpaperView")];
            [MSHookIvar<SBWallpaperView*>(self, "_wallpaperView") setViewAlpha:1.0f];
            [MSHookIvar<SBWallpaperView*>(self, "_wallpaperView") setAlpha:1.0f];
            addedViews = YES;
        }
        [self restoreIconListAnimated:NO animateWallpaper:NO keepSwitcher:NO];
    }
    %orig;
    locked = YES;
}

%end

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
    alpha = [[settings.settingsDict objectForKey:@"kAlphaColor"] floatValue];
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
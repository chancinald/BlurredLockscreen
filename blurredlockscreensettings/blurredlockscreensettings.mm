#import <Preferences/Preferences.h>

@interface blurredlockscreensettingsListController: PSListController {
}
@property(nonatomic,retain)PSSpecifier *slideToUnlock;
@property(nonatomic,retain)PSSpecifier *tapToUnlock;
@end

@implementation blurredlockscreensettingsListController
@synthesize slideToUnlock,tapToUnlock;
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"blurredlockscreensettings" target:self] retain];
        NSLog(@"%@",_specifiers);
        for (PSSpecifier *spec in _specifiers) {
            if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"hideSlideToUnlock"]) {
                self.slideToUnlock = spec;
            }
            if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"hideTapToUnlock"]) {
                self.tapToUnlock = spec;
            }
        }
	}
	return _specifiers;
}

-(void)setValue:(id)something forSpecifier:(PSSpecifier*)spec{
    if([[[spec properties] objectForKey:@"id"] isEqualToString:@"hideSlideToUnlock"]){
        if([(NSNumber*)something boolValue]){
            [self setPreferenceValue:[NSNumber numberWithBool:YES] specifier:self.tapToUnlock];
        }
    }
    else{
        if(![(NSNumber*)something boolValue]){
            [self setPreferenceValue:[NSNumber numberWithBool:NO] specifier:self.slideToUnlock];
        }
    }
    [self setPreferenceValue:something specifier:spec];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reloadSpecifier:self.tapToUnlock animated:YES];
    [self reloadSpecifier:self.slideToUnlock animated:YES];
}
@end

// vim:ft=objc

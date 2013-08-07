//#import <Preferences/PSListController.h>
//#import <Preferences/PSControlTableCell.h>
//#import <Preferences/PSSpecifier.h>
#import <Preferences/Preferences.h>
#import <objc/runtime.h>

@interface blurredlockscreensettingsColorsController: PSListController {
    PSSpecifier *redSpecifier;
    PSSpecifier *greenSpecifier;
    PSSpecifier *blueSpecifier;
    PSSpecifier *alphaSpecifier;
    PSSpecifier *colorDisplaySpecifier;
}

@property(nonatomic,retain)PSSpecifier *redSpecifier;
@property(nonatomic,retain)PSSpecifier *greenSpecifier;
@property(nonatomic,retain)PSSpecifier *blueSpecifier;
@property(nonatomic,retain)PSSpecifier *alphaSpecifier;
@property(nonatomic,retain)PSSpecifier *colorDisplaySpecifier;

@end

@implementation blurredlockscreensettingsColorsController

@synthesize redSpecifier,greenSpecifier,blueSpecifier,alphaSpecifier,colorDisplaySpecifier;

- (id)specifiers {
	if(_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"blurredlockscreensettingscolors" target:self]];
        
        for (PSSpecifier *spec in specs) {
            // NSLog(@"Meh0. %@", [[spec properties] objectForKey:@"id"]);
            if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"redColor"]) {
                
                self.redSpecifier = spec;
            }
            if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"greenColor"]) {
                
                self.greenSpecifier = spec;
            }
            if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"blueColor"]) {
                
                self.blueSpecifier = spec;
            }
            if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"alphaColor"]) {
                
                self.alphaSpecifier = spec;
                
            }
            if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"colorDisplay"]) {
                
                self.colorDisplaySpecifier = spec;
                
                PSTableCell *tableCellColorDisplay = [self.colorDisplaySpecifier.properties objectForKey:@"cellObject"];
                [(UIView*)tableCellColorDisplay setUserInteractionEnabled:NO];
                [(UIView*)tableCellColorDisplay setAlpha:0.2f];
            }
        }
        
        _specifiers = [specs copy];
	}
	return _specifiers;
}
@end

// vim:ft=objc

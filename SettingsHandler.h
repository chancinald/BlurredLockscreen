#import <UIKit/UIKit.h>

@interface SettingsHandler : NSObject {
    BOOL plistPathIsSet;
    NSString *plistPath;
    NSMutableDictionary *settingsDict;
}

@property(nonatomic, retain)NSMutableDictionary *settingsDict;

-(void)updateSettings;
-(void)setPlistPath:(NSString*)str;

@end
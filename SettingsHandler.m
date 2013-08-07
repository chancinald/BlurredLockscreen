#import "SettingsHandler.h"

@implementation SettingsHandler

@synthesize settingsDict;

-(void)setPlistPath:(NSString*)str{
    if([[NSFileManager defaultManager] fileExistsAtPath:str] && [[NSFileManager defaultManager] isReadableFileAtPath:str]){
        plistPath = str;
        plistPathIsSet = YES;
        [self updateSettings];
    }
}

-(void)updateSettings{
    if(plistPathIsSet)
        self.settingsDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
     
}

@end
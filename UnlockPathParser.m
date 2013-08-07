//
//  UnlockPathParser.m
//  
//
//  Created by Chance Hudson on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UnlockPathParser.h"

@implementation UnlockPathParser

+(NSArray*)parseArrayOfRects:(NSMutableArray*)arr{
    NSMutableArray *returnArr = [NSMutableArray array];
    for(int x = 0; x < [arr count]; x++){
        NSString *s = [arr objectAtIndex:x];
        CGRect r;
        NSRange r1 = [s rangeOfString:@"x"];
        NSRange r2 = [s rangeOfString:@"y"];
        NSRange r3 = [s rangeOfString:@"w"];
        NSRange r4 = [s rangeOfString:@"h"];
        r.origin.x = [[s substringWithRange:(NSRange){r1.location+1,r2.location-(r1.location+1)}] intValue];
        r.origin.y = [[s substringWithRange:(NSRange){r2.location+1,r3.location-(r2.location+1)}] intValue];
        r.size.width = [[s substringWithRange:(NSRange){r3.location+1,r4.location-(r3.location+1)}] intValue];
        r.size.height = [[s substringWithRange:(NSRange){r4.location+1,[s length]-(r4.location+1)}] intValue];
        [returnArr addObject:[NSValue valueWithCGRect:r]];
    }
    return returnArr;
}

@end

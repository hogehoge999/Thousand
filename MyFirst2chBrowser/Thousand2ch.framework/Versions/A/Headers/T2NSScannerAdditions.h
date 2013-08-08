//
//  T2NSScannerAdditions.h
//  Thousand
//
//  Created by R. Natori on 平成 19/11/16.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSScanner (THNSScannerAdditions)
-(BOOL)scanUpAndThroughString:(NSString *)string intoString:(NSString **)intoString ;
-(BOOL)scanTokenString:(NSString **)intoString ;
@end

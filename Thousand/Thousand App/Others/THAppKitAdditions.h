//
//  THAppKitAdditions.h
//  Thousand
//
//  Created by R. Natori on  07/09/24.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWindow (THAppKitAdditions)
- (BOOL)writeWindowImageToJPEGFile:(NSString *)filepath compressionFactor:(float)compressionFactor ;
@end

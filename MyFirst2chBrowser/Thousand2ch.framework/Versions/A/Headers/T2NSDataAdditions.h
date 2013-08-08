//
//  T2NSDataAdditions.h
//  Thousand
//
//  Created by R. Natori on 06/01/12.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "zlib.h"


@interface NSData (T2NSDataAdditions)

// NSData <-> .gz file
+(id)dataWithContentsOfGZipFile:(NSString *)path ;
-(BOOL)writeToGZipFile:(NSString *)path ;
@end

@interface NSMutableData (T2NSMutableDataAdditions)

// NSData <- .gz file
+(id)dataWithContentsOfGZipFile:(NSString *)path ;
@end

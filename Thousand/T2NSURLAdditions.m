//
//  T2NSURLAdditions.m
//  Thousand
//
//  Created by R. Natori on 11/07/09.
//  Copyright 2011 R. Natori. All rights reserved.
//

#import "T2NSURLAdditions.h"


@implementation NSURL (T2NSURLAdditions)
-(NSString *)filePath {
	CFStringRef filePathString = CFURLCopyFileSystemPath((CFURLRef)self, kCFURLPOSIXPathStyle);
	return [(NSString *)filePathString autorelease];
}
@end

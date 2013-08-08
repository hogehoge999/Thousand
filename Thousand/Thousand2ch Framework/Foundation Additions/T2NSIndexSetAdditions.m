//
//  T2NSIndexSetAdditions.m
//  Thousand
//
//  Created by R. Natori on 06/04/02.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2NSIndexSetAdditions.h"

static NSCharacterSet *__decimalDigitCharacterSet = nil;

@implementation NSIndexSet (T2NSIndexSetAdditions)
+(id)indexSetWithString:(NSString *)string {
	if (!__decimalDigitCharacterSet)
		__decimalDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] retain];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSScanner *scanner = [NSScanner scannerWithString:[[string copy] autorelease]];
	
	NSMutableIndexSet *resultIndexSet = [NSMutableIndexSet indexSet];
	int index = -1, prevIndex = 0;
	NSString *separator = nil, *prevSeparator = nil;
	
	
	while (![scanner isAtEnd]) {
		if ([scanner scanInt:&index] && index > -1 && index < NSNotFound) {
			if (prevSeparator == @"-" && index > prevIndex) {
				[resultIndexSet addIndexesInRange:NSMakeRange(prevIndex, index-prevIndex+1)];
			} else {
				[resultIndexSet addIndex:index];
			}
			prevIndex = index;
		}
		[scanner scanUpToCharactersFromSet:__decimalDigitCharacterSet intoString:&separator];
		if (separator && [separator isEqualToString:@"-"]) {
			prevSeparator = @"-";
		} else {
			prevSeparator = nil;
		}
	}
	NSIndexSet *result = [resultIndexSet copy];
	[pool release];
	[result autorelease];
	if ([result count]>0) {
		return result;
	}
	return nil;
}

+(id)shiftedIndexSetWithString:(NSString *)string {
	if (!__decimalDigitCharacterSet)
		__decimalDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] retain];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSScanner *scanner = [NSScanner scannerWithString:[[string copy] autorelease]];
	
	NSMutableIndexSet *resultIndexSet = [NSMutableIndexSet indexSet];
	int index = -1, prevIndex = 0;
	NSString *separator = nil, *prevSeparator = nil;
	
	
	while (![scanner isAtEnd]) {
		if ([scanner scanInt:&index] && index > 0 && index < NSNotFound) {
			index--;
			if (prevSeparator == @"-" && index > prevIndex) {
				[resultIndexSet addIndexesInRange:NSMakeRange(prevIndex, index-prevIndex+1)];
			} else {
				[resultIndexSet addIndex:index];
			}
			prevIndex = index;
		}
		[scanner scanUpToCharactersFromSet:__decimalDigitCharacterSet intoString:&separator];
		if (separator && [separator isEqualToString:@"-"]) {
			prevSeparator = @"-";
		} else {
			prevSeparator = nil;
		}
	}
	NSIndexSet *result = [resultIndexSet copy];
	[pool release];
	[result autorelease];
	if ([result count]>0) {
		return result;
	}
	return nil;
}
@end

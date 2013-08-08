//
//  T2NSScannerAdditions.m
//  Thousand
//
//  Created by R. Natori on 平成 19/11/16.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "T2NSScannerAdditions.h"

@implementation NSScanner (THNSScannerAdditions)
-(BOOL)scanUpAndThroughString:(NSString *)string intoString:(NSString **)intoString {
	if ([self scanString:string intoString:NULL]) {
		intoString = NULL;
		return YES;
	}
	BOOL result = [self scanUpToString:string intoString:intoString];
	[self scanString:string intoString:NULL];
	return result;
}

-(BOOL)scanTokenString:(NSString **)intoString {
	[self scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
					 intoString:NULL];
	BOOL result;
	
	NSCharacterSet *characterSet = [self charactersToBeSkipped];
	[self setCharactersToBeSkipped:[NSCharacterSet illegalCharacterSet]];
	
	if ([self scanString:@"\"" intoString:NULL]) {
		result = [self scanUpToString:@"\"" intoString:intoString] && [self scanString:@"\"" intoString:NULL];
		
	}
	else if ([self scanString:@"'" intoString:NULL]) {
		result = [self scanUpToString:@"'" intoString:intoString] && [self scanString:@"'" intoString:NULL];
		
	}
	else {
		result = [self scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
									  intoString:intoString];
	}
	if (!result)
		*intoString = nil;
	
	[self setCharactersToBeSkipped:characterSet];
	
	return result;
}
@end

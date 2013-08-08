//
//  T2NSCalendarDateAdditions.m
//  Thousand
//
//  Created by R. Natori on 05/12/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2NSCalendarDateAdditions.h"

static NSString *__RFC1123Format = @"%a, %d %b %Y %H:%M:%S %z";
static NSString *__RFC1123GMTFormat = @"%a, %d %b %Y %H:%M:%S GMT";

@implementation NSCalendarDate (T2NSCalendarDateAdditions)
+(NSCalendarDate *)dateWithRFC1123String:(NSString *)aString {
	NSCalendarDate *resultDate = nil;
	if ([aString hasSuffix:@"GMT"])
		resultDate = [NSCalendarDate dateWithString:aString calendarFormat:__RFC1123GMTFormat];
	else
		resultDate = [NSCalendarDate dateWithString:aString calendarFormat:__RFC1123Format];
	if (!resultDate)
		resultDate = [NSCalendarDate dateWithNaturalLanguageString:aString];
	return resultDate;
}

-(NSString *)descriptionWithRFC1123 {
	return [self descriptionWithCalendarFormat:__RFC1123Format];
}
@end

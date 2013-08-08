//
//  T2KeyValueReplace.m
//  Thousand
//
//  Created by R. Natori on 平成 19/11/18.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "T2KeyValueReplace.h"

static NSString *__atIfStart = @"<!--@if";
static NSString *__atIfEnd = @"-->";
static NSCharacterSet *__controlCharSet = nil;

@implementation T2KeyValueReplace

+(void)initialize {
	if (__controlCharSet) return;
	__controlCharSet = [[NSCharacterSet controlCharacterSet] retain];
}

+(id)keyReplaceWithTemplateString:(NSString *)aString {
	if ([aString rangeOfString:__atIfStart].location != NSNotFound) {
		return [[[T2KeyValueReplaceConditional alloc] initWithTemplateString:aString] autorelease];
	
	} else if ([aString rangeOfString:@"@("].location != NSNotFound) {
		return [[[T2KeyValueReplace alloc] initWithTemplateString:aString] autorelease];
		
	}
	return [[[T2KeyValueReplaceNoReplace alloc] initWithTemplateString:aString] autorelease];
}

-(id)initWithTemplateString:(NSString *)aString {
	self = [super init];
	
	NSMutableArray *parts = [NSMutableArray array];
	NSMutableArray *keys = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:aString];
	[scanner setCharactersToBeSkipped:__controlCharSet];
	NSString *partString, *key;
	while ([scanner scanUpToString:@"@(" intoString:&partString]
		   && [scanner scanString:@"@(" intoString:NULL]
		   && [scanner scanUpToString:@")" intoString:&key]
		   && [scanner scanString:@")" intoString:NULL]) {
		if (!partString) partString = @"";
		[parts addObject:partString];
		//capacity += [partString length];
		if (!key) key = @"";
		[keys addObject:key];
	}
	if (!partString) partString = @"";
	[parts addObject:partString];
	
	_keys = [keys copy];
	_parts = [parts copy];
	_capacity = [aString length];
	return self;
}
-(void)dealloc {
	[_parts release];
	[_keys release];
	[super dealloc];
}
-(NSString *)replacedStringUsingObject:(NSObject *)anObject {
	NSMutableString *resultString = [[[NSMutableString alloc] initWithCapacity:_capacity] autorelease];
	
	unsigned i, imax = [_keys count];
	[resultString appendString:[_parts objectAtIndex:0]];
	NSString *value;
	
	for (i=0; i< imax; i++) {
		value = [anObject valueForKey:[_keys objectAtIndex:i]];
		if (value)
			[resultString appendString:value];
		[resultString appendString:[_parts objectAtIndex:i+1]];
	}
	return resultString;
}
@end

@implementation T2KeyValueReplaceConditional
-(id)initWithTemplateString:(NSString *)aString {
	self = [super initWithTemplateString:aString];
	
	NSArray *oldParts = [[_parts copy] autorelease];
	NSMutableArray *newParts = [NSMutableArray array];
	NSMutableArray *directions = [NSMutableArray array];
	unsigned i, max = [oldParts count];
	BOOL isInConditional = NO;
	for (i=0; i<max; i++) {
		NSString *part = [oldParts objectAtIndex:i];
		NSRange atIfStartRange = [part rangeOfString:__atIfStart];
		NSRange atIfEndRange = [part rangeOfString:__atIfEnd];
		
		if (atIfStartRange.location != NSNotFound && atIfEndRange.location == NSNotFound) {
			[newParts addObjectsFromArray:[part componentsSeparatedByString:__atIfStart]];
			[directions addObject:[NSNumber numberWithInt:T2KeyValueReplaceDirectionConditionalStart]];
			isInConditional = YES;
			
		} else if (atIfEndRange.location != NSNotFound && atIfStartRange.location == NSNotFound
				   && isInConditional) {
			[newParts addObjectsFromArray:[part componentsSeparatedByString:__atIfEnd]];
			int prevDirection = [[directions lastObject] intValue];
			[directions removeLastObject];
			[directions addObject:[NSNumber numberWithInt:prevDirection | T2KeyValueReplaceDirectionConditionalEnd]];
			isInConditional = NO;
			
		} else if (atIfEndRange.location < atIfStartRange.location
				   && isInConditional) {
			NSArray *tempParts = [part componentsSeparatedByString:__atIfEnd];
			if ([tempParts count] == 2) {
				NSArray *tempParts2 = [[tempParts objectAtIndex:1] componentsSeparatedByString:__atIfStart];
				[newParts addObject:[tempParts objectAtIndex:0]];
				[newParts addObjectsFromArray:tempParts2];
				int prevDirection = [[directions lastObject] intValue];
				[directions removeLastObject];
				[directions addObject:[NSNumber numberWithInt:prevDirection | T2KeyValueReplaceDirectionConditionalEnd]];
				[directions addObject:[NSNumber numberWithInt:T2KeyValueReplaceDirectionConditionalStart]];
			}
		} else {
			[newParts addObject:part];
			if (isInConditional)
				[directions addObject:[NSNumber numberWithInt:T2KeyValueReplaceDirectionConditional]];
			else
				[directions addObject:[NSNumber numberWithInt:T2KeyValueReplaceDirectionNotConditional]];
			
		}
	}
	
	unsigned j, jmax = [directions count];
	int *directionsPtr = calloc(jmax, sizeof(int));
	for (j=0; j<jmax; j++) {
		directionsPtr[j] = [(NSNumber *)[directions objectAtIndex:j] intValue];
	}
	
	_directionsPtr = directionsPtr;
	[_parts release];
	_parts = [newParts copy];
	
	return self;
}
-(void)dealloc {
	if (_directionsPtr) {
		free(_directionsPtr);
	}
	[super dealloc];
}
-(NSString *)replacedStringUsingObject:(NSObject *)anObject {
	NSMutableString *resultString = [[[NSMutableString alloc] initWithCapacity:_capacity] autorelease];
	NSMutableString *conditionalString = [[[NSMutableString alloc] initWithCapacity:0] autorelease];
	
	unsigned i,j=1, imax = [_keys count];
	[resultString appendString:[_parts objectAtIndex:0]];
	NSString *value;
	
	for (i=0; i< imax; i++) {
		if (_directionsPtr[i] == T2KeyValueReplaceDirectionNotConditional) { // Not Conditional
			value = [anObject valueForKey:[_keys objectAtIndex:i]];
			if (value)
				[resultString appendString:value];
			[resultString appendString:[_parts objectAtIndex:j]];
			j++;
			
		} else { // Conditional
			value = [anObject valueForKey:[_keys objectAtIndex:i]];
			if (value) {
				if (_directionsPtr[i] & T2KeyValueReplaceDirectionConditionalStart) {
					[conditionalString setString:@""];
					[conditionalString appendString:[_parts objectAtIndex:j]];
					j++;
				}
				[conditionalString appendString:value];
				[conditionalString appendString:[_parts objectAtIndex:j]];
				j++;
				if (_directionsPtr[i] & T2KeyValueReplaceDirectionConditionalEnd) {
					[conditionalString appendString:[_parts objectAtIndex:j]];
					[resultString appendString:conditionalString];
					j++;
				}
			} else {
				if (_directionsPtr[i] & T2KeyValueReplaceDirectionConditionalStart) {
					j++;
				}
				j++;
				while (_directionsPtr[i] == T2KeyValueReplaceDirectionConditional) {
					i++;
					j++;
				}
				if (_directionsPtr[i] & T2KeyValueReplaceDirectionConditionalEnd) {
					[resultString appendString:[_parts objectAtIndex:j]];
					j++;
				}
			}
		}
	}
	return resultString;
}
@end

@implementation T2KeyValueReplaceNoReplace
-(id)initWithTemplateString:(NSString *)aString {
	self = [super init];
	_templateString = [aString copy];
	return self;
}
-(void)dealloc {
	[_templateString release];
	[super dealloc];
}

-(NSString *)replacedStringUsingObject:(NSObject *)anObject {
	return _templateString;
}
@end
//
//  THT2ThreadListAdditions.m
//  Thousand
//
//  Created by R. Natori on 08/08/25.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "THT2ThreadListAdditions.h"


@implementation T2ThreadList (THT2ThreadListAdditions) 

-(void)setVariableKey:(NSString *)variableKey {
	NSMutableDictionary *extraInfo = [[[self extraInfo] mutableCopy] autorelease];
	if (!extraInfo) extraInfo = [NSMutableDictionary dictionary];
	[extraInfo setObject:variableKey forKey:@"variableKey"];
	[self setExtraInfo:extraInfo];
}
-(NSString *)variableKey {
	NSDictionary *extraInfo = [self extraInfo];
	if (extraInfo) {
		NSString *variableKey = [extraInfo objectForKey:@"variableKey"];
		if (variableKey)
			return variableKey;
	}
	return @"voidProperty";
}
@end

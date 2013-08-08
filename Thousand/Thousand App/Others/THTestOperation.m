//
//  THTestOperation.m
//  Thousand
//
//  Created by R. Natori on 08/11/17.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "THTestOperation.h"


@implementation THTestOperation
-(id)init {
	self = [super init];
	[self setName:@"Test"];
	return self;
}
-(void)main {
	unsigned i, maxCount = 10;
	for(i=0; i<= maxCount; i++) {
		if ([self isCancelled]) return;
		NSDate *date = [NSDate date];
		date = [date addTimeInterval:1.0];
		[NSThread sleepUntilDate:date];
		[self setProgress:(float)i/(float)maxCount];
		[self setStatusString:[NSString stringWithFormat:@"Progress: %d / %d", i, maxCount]];
	}
}

-(BOOL)visible { return YES; }
@end

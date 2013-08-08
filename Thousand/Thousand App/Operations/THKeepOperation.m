//
//  THkeepOperation.m
//  Thousand
//
//  Created by R. Natori on 平成 21/04/07.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import "THKeepOperation.h"

static THKeepOperation *__sharedOperation = nil;
static NSMutableArray *__objectsToKeep = nil;

@implementation THKeepOperation

+(id)keepOperationWithObjects:(NSArray *)objects {
	
	if (!__objectsToKeep)
		__objectsToKeep = [[NSMutableArray alloc] init];
	
	@synchronized(__objectsToKeep) {
		[__objectsToKeep addObjectsFromArray:objects];
	}
	
	if (__sharedOperation) {
		return __sharedOperation;
	}
	
	__sharedOperation = [[self alloc] init];
	return __sharedOperation;

}
+(id)keepOperationWithObject:(T2IdentifiedObject *)object {
	[self keepOperationWithObjects:[NSArray arrayWithObject:object]];
}
+(void)keepOnMainThread {
	@synchronized(__objectsToKeep) {
		[__objectsToKeep release];
		__objectsToKeep = nil;
	}
}

-(id)init {
	self = [super init];
	[self setName:@"THKeepOperation"];
	return self;
}
-(void)main {
	@synchronized(__objectsToKeep) {
		[__objectsToKeep release];
		__objectsToKeep = nil;
	}
}

-(BOOL)visible { return NO; }


@end

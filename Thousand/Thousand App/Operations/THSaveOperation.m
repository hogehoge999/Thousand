//
//  THSaveOperation.m
//  Thousand
//
//  Created by R. Natori on 平成 21/03/26.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import "THSaveOperation.h"

static THSaveOperation *__sharedOperation = nil;
static NSMutableArray *__objectsToSave = nil;

@implementation THSaveOperation

+(id)saveOperationWithIdentifiedObjects:(NSArray *)objects {
	if (!__objectsToSave)
		__objectsToSave = [[NSMutableArray alloc] init];
	
	@synchronized(__objectsToSave) {
		[__objectsToSave addObjectsFromArray:objects];
	}
	
	if (__sharedOperation) {
		return __sharedOperation;
	}
	
	__sharedOperation = [[self alloc] init];
	return __sharedOperation;
	
}
+(id)saveOperationWithIdentifiedObject:(T2IdentifiedObject *)object {
	[self saveOperationWithIdentifiedObjects:[NSArray arrayWithObject:object]];
}
+(void)saveOnMainThread {
	@synchronized(__objectsToSave) {
		while ([__objectsToSave count] > 0) {
			
			T2IdentifiedObject *object = [__objectsToSave objectAtIndex:0];
			[object saveToFile];
			[__objectsToSave removeObjectAtIndex:0];
		}
	}
}

-(id)init {
	self = [super init];
	[self setName:@"THSaveOperation"];
	return self;
}
-(void)main {
	@synchronized(__objectsToSave) {
		//NSDate *date = [NSDate date];
		while ([__objectsToSave count] > 0) {
			
			T2IdentifiedObject *object = [__objectsToSave objectAtIndex:0];
			[object saveToFile];
			[__objectsToSave removeObjectAtIndex:0];
		}
		//NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:date];
		//NSLog(@"%f Seconds taken in saving.", timeInterval);
	}
}

-(BOOL)visible { return NO; }

@end

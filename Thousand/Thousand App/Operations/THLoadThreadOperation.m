//
//  THLoadThreadOperation.m
//  Thousand
//
//  Created by R. Natori on 平成 21/04/07.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import "THLoadThreadOperation.h"


@implementation THLoadThreadOperation

+(id)loadOperationWithThreadFaces:(NSArray *)threadFaces {
	return [[[self alloc] initWithThreadFaces:threadFaces] autorelease];
}
+(id)loadOperationWithThreadFace:(T2ThreadFace *)threadFace {
	return [[[self alloc] initWithThreadFaces:[NSArray arrayWithObject:threadFace]] autorelease];
}

-(id)initWithThreadFaces:(NSArray *)threadFaces {
	self = [super init];
	_threadFaces = [threadFaces copy];
	_threads = [[NSMutableArray alloc] initWithCapacity:[_threadFaces count]];
	return self;
}
-(void)dealloc {
	[_threadFaces release];
	[_threads release];
	[super dealloc];
}

-(void)main {
	@synchronized([self class]) {
		T2ThreadFace *threadFace;
		NSEnumerator *threadFaceEnumerator = [_threadFaces objectEnumerator];
		while (threadFace = [threadFaceEnumerator nextObject]) {
			T2Thread *thread = [threadFace thread];
			[_threads addObject:thread];
		}
		//NSLog(@"Prefetched: %@", _threads);
	}
}

-(BOOL)visible { return NO; }

-(NSArray *)threads {
	if (![self isExecuting])
		return _threads;
	return nil;
}
@end

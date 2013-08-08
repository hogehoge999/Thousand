//
//  T2AddMissingThreadOperation.m
//  Thousand
//
//  Created by R. Natori on 08/12/10.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2AddMissingThreadOperation.h"
#import "T2ListFace.h"
#import "T2ThreadFace.h"
#import "T2ThreadList.h"

@implementation T2AddMissingThreadOperation

+(T2Operation *)addMissingThreadOperationWithThreadFace:(T2ThreadFace *)threadFace threadListFace:(T2ListFace *)threadListFace {
	return [[[self alloc] initWithThreadFace:threadFace threadListFace:threadListFace] autorelease];
}

+(T2Operation *)addMissingThreadOperationWithThreadFace:(T2ThreadFace *)threadFace {
	return [[[self alloc] initWithThreadFace:threadFace threadListFace:nil] autorelease];
}

-(T2Operation *)initWithThreadFace:(T2ThreadFace *)threadFace threadListFace:(T2ListFace *)threadListFace {
	if (![threadFace internalPath]) {
		[self autorelease];
		return nil;
	}
	
	self = [super init];
	_threadFace = [threadFace retain];
	_threadListFace = [threadListFace retain];
	return self;
}

-(T2Operation *)initWithThreadFace:(T2ThreadFace *)threadFace {
	return [self initWithThreadFace:threadFace threadListFace:nil];
}
-(void)dealloc {
	[_threadFace release];
	[_threadListFace release];
	[super dealloc];
}
-(void)main {
	if (!_threadListFace) {
		_threadListFace = [T2ListFace availableObjectWithInternalPath:[[_threadFace internalPath] stringByDeletingLastPathComponent]];
	}
	T2ThreadList *threadList = [T2ThreadList listWithListFace:_threadListFace];
	NSArray *objects = [threadList objects];
	if (![objects containsObject:_threadFace]) {
		objects = [objects arrayByAddingObject:_threadFace];
		[threadList setObjects:objects];
	}
}
@end

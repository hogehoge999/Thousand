//
//  THLoadListOperation.m
//  Thousand
//
//  Created by R. Natori on 平成 21/04/07.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import "THLoadListOperation.h"


@implementation THLoadListOperation

+(id)loadOperationWithListFaces:(NSArray *)listFaces {
	return [[[self alloc] initWithListFaces:listFaces] autorelease];
}
+(id)loadOperationWithListFace:(T2ListFace *)listFace {
	return [[[self alloc] initWithListFaces:[NSArray arrayWithObject:listFace]] autorelease];
}

-(id)initWithListFaces:(NSArray *)listFaces {
	self = [super init];
	_listFaces = [listFaces copy];
	_lists = [[NSMutableArray alloc] initWithCapacity:[_listFaces count]];
	return self;
}
-(void)dealloc {
	[_listFaces release];
	[_lists release];
	[super dealloc];
}

-(void)main {
	@synchronized(_listFaces) {
		T2ListFace *listFace;
		NSEnumerator *listFaceEnumerator = [_listFaces objectEnumerator];
		while (listFace = [listFaceEnumerator nextObject]) {
			T2List *list = [listFace list];
			[_lists addObject:list];
		}
	}
}

-(BOOL)visible { return NO; }

-(NSArray *)lists {
	if (![self isExecuting])
		return _lists;
	return nil;
}
@end

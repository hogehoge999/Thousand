//
//  T2NSArrayAdditions.m
//  Thousand
//
//  Created by R. Natori on 06/04/17.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2NSArrayAdditions.h"


@implementation NSArray (T2NSArrayAdditions)

-(NSArray *)objectsAtIndexes_panther:(NSIndexSet *)indexSet {
	unsigned index = [indexSet firstIndex];
	unsigned count = [self count];
	NSMutableArray *resultArray;
	if ([indexSet lastIndex] < count)
		resultArray = [NSMutableArray arrayWithCapacity:[indexSet count]];
	else
		resultArray = [NSMutableArray array];
	while (index < count) {
		[resultArray addObject:[self objectAtIndex:index]];
		index = [indexSet indexGreaterThanIndex:index];
	}
	if ([resultArray count] == 0) resultArray = nil;
	return resultArray;
}
@end

@implementation NSMutableArray (T2NSMutableArrayAdditions)

+(NSMutableArray *)mutableArrayWithoutRetainingObjects {
	CFArrayCallBacks arrayCallBacks = kCFTypeArrayCallBacks;
	arrayCallBacks.retain = NULL;
	arrayCallBacks.release = NULL;
	return [(NSMutableArray *)CFArrayCreateMutable(NULL,
												   0,
												   &arrayCallBacks) autorelease];
}

- (void)removeObjectsAtIndexes_panther:(NSIndexSet *)indexes {
	if ([indexes count]==0) return;
	unsigned i = [indexes lastIndex];
	while (i != NSNotFound) {
		[self removeObjectAtIndex:i];
		i = [indexes indexLessThanIndex:i];
	}
}

- (void)insertObjects_panther:(NSArray *)objects atIndexes:(NSIndexSet *)indexes {
	if ([indexes count]==0) return;
	NSEnumerator *objectEnumerator = [objects objectEnumerator];
	id object;
	unsigned i = [indexes firstIndex];
	while (i != NSNotFound) {
		if (!(object = [objectEnumerator nextObject])) return;
		if (i>=[self count]) {
			[self addObject:object];
		} else {
			[self insertObject:object atIndex:i];
			i = [indexes indexGreaterThanIndex:i];
		}
	}
}
@end
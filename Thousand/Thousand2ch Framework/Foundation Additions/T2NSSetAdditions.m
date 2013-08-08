//
//  T2NSSetAdditions.m
//  Thousand
//
//  Created by R. Natori on 平成 20/01/17.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "T2NSSetAdditions.h"


@implementation NSMutableSet (T2NSSetAdditions)
+(NSMutableSet *)mutableSetWithoutRetainingObjects {
	CFSetCallBacks setCallBacks = kCFTypeSetCallBacks;
	setCallBacks.retain = NULL;
	setCallBacks.release = NULL;
	return [(NSMutableSet *)CFSetCreateMutable(NULL,
											   0,
											   &setCallBacks) autorelease];
}
@end

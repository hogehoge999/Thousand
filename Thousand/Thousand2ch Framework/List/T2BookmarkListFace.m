//
//  T2BookmarkListFace.m
//  Thousand
//
//  Created by R. Natori on 06/09/30.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2BookmarkListFace.h"
#import "T2BookmarkList.h"

static NSImage *__classDefaultImage = nil;

@implementation T2BookmarkListFace
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"internalPath",
		@"title",
		@"list", nil];
}

+(id)bookmarkListFace {
	return [[[self alloc] init] autorelease];
}

-(id)init {
	self = [super init];
	[self setList:[T2BookmarkList bookmarkList]];
	[self setImage:__classDefaultImage];
	return self;
}

-(void)dealloc {
	[_list setListFace:nil];
	[_list autorelease];
	_list = nil;
	[super dealloc];
}

-(BOOL)allowsEditingTitle { return YES; }

-(void)setList:(T2BookmarkList *)list {
	setObjectWithRetain(_list, list);
	[_list setListFace:self];
}
-(T2List *)list { return _list; }

-(BOOL)isLeaf { return YES; }

-(void)setImageByListImporter {
	[self setImage:__classDefaultImage];
}

+(void)setClassDefaultImage:(NSImage *)image {
	setObjectWithRetain(__classDefaultImage, image);
}
+(NSImage *)classDefaultImage { return __classDefaultImage; }
@end

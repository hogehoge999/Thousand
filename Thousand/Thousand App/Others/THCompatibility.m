//
//  THCompatibility.m
//  Thousand
//
//  Created by R. Natori on 06/09/30.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "THCompatibility.h"

@implementation T2List (THCompatibility)
-(void)setList:(NSArray *)anArray {
	[self setObjects:anArray];
}
-(NSArray *)list {
	return [self objects];
}
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	if (use == T2DictionaryDecoding) {
		return [NSArray arrayWithObjects:@"title",
			@"internalPath",
			@"list",
			@"objects",
			@"extraInfo", nil];
	}
	if (_internalPath)
		return [NSArray arrayWithObjects:@"title",
			@"internalPath", nil];
	else
		return [NSArray arrayWithObjects:@"title",
			@"objects",
			@"extraInfo", nil];
}
@end

@implementation T2ListHolder
-(id)initWithEncodedDictionary:(NSDictionary *)dic {
	[self autorelease];
	NSString *title = [dic objectForKey:@"title"];
	NSString *internalPath = [dic objectForKey:@"internalPath"];
	return [[T2ListFace alloc] initWithInternalPath:internalPath
											  title:title
											  image:nil];
}
@end

@implementation T2ThreadListHolder
-(id)initWithEncodedDictionary:(NSDictionary *)dic {
	[self autorelease];
	NSString *title = [dic objectForKey:@"title"];
	NSString *internalPath = [dic objectForKey:@"internalPath"];
	return [[T2ListFace alloc] initWithInternalPath:internalPath
											  title:title
											  image:nil];
}
@end

@implementation T2BookmarkListHolder
-(id)initWithEncodedDictionary:(NSDictionary *)dic {
	[self autorelease];
	NSString *title = [dic objectForKey:@"title"];
	NSArray *objects = [NSObject objectWithDictionary:[dic objectForKey:@"list"]];
	T2BookmarkListFace *bookmarkListFace = [[T2BookmarkListFace bookmarkListFace] retain];
	[bookmarkListFace setTitle:title];
	[[bookmarkListFace list] setObjects:objects];
	return bookmarkListFace;
}
@end

@implementation T2ThreadListItem
-(id)initWithEncodedDictionary:(NSDictionary *)dic {
	[self autorelease];
	return [[T2ThreadFace alloc] initWithEncodedDictionary:dic];
}
@end

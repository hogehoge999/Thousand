//
//  T2BookmarkListFace.h
//  Thousand
//
//  Created by R. Natori on 06/09/30.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2ListFace.h"

@class T2BookmarkList;

@interface T2BookmarkListFace : T2ListFace {
	T2BookmarkList *_list;
}

#pragma mark -
#pragma mark Factory and Init
+(id)bookmarkListFace ;
-(id)init ;

#pragma mark -
#pragma mark Accessors
-(void)setList:(T2BookmarkList *)list ;
-(T2List *)list ;

+(void)setClassDefaultImage:(NSImage *)image ;
+(NSImage *)classDefaultImage ;
@end

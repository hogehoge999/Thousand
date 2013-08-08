//
//  T2BookmarkList.h
//  Thousand
//
//  Created by R. Natori on 06/02/18.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2ThreadList.h"

@interface T2BookmarkList : T2ThreadList {
	T2List 			*_loadingList;
	NSMutableArray 	*_loadingListHolders;
	unsigned 		_loadingListHoldersCount;
	NSArray			*_loadingListContentObjects;
	NSTimer 		*_timer;
}
//+(void)loadAll ;
//+(NSArray *)allBookmarkLists ;
+(id)bookmarkList ;
-(id)init ;
//-(id)initWithoutRegistering ;


-(void)loadPartWithTimer:(NSTimer *)timer ;
-(void)partLoaded ;
@end

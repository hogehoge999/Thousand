//
//  T2SourceList.h
//  Thousand
//
//  Created by R. Natori on 06/10/15.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2List.h"

@interface T2SourceList : T2List {
	unsigned _firstBookmarkIndex;
}
+(id)sharedSourceList ;
-(unsigned)firstBookmarkIndex ;
-(BOOL)hasBookmarkedThreadFace:(T2ThreadFace *)threadFace ;
-(NSArray *)bookmarkListFacesContainThreadFace:(T2ThreadFace *)threadFace ;
-(void)removeBookmarkedThreadFace:(T2ThreadFace *)threadFace ;
-(void)replaceBookmarkedThreadFace:(T2ThreadFace *)oldThreadFace withThreadFace:(T2ThreadFace *)newThreadFace ;
@end

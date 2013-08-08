//
//  T2ThreadList.h
//  Thousand
//
//  Created by R. Natori on 05/07/03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2List.h"

@interface T2ThreadList : T2List {
	BOOL		_shouldSavePList;
	
	NSString	*_sortDescriptorKey;
	BOOL		_sortDescriptorAscending;
	NSString	*_webBrowserURLString;
}

#pragma mark -
#pragma mark Accessors
-(void)setSortDescriptorKey:(NSString *)aString ;
-(NSString *)sortDescriptorKey ;
-(void)setSortDescriptorAscending:(BOOL)aBool ;
-(BOOL)sortDescriptorAscending ;
-(void)setSortDescriptor:(NSSortDescriptor *)sortDescriptor ;
-(NSSortDescriptor *)sortDescriptor ;

-(void)setWebBrowserURLString:(NSString *)urlString ;
-(NSString *)webBrowserURLString ;

#pragma mark -
#pragma mark Getting Posting
-(T2Posting *)postingWithFirstRes:(T2Res *)res threadTitle:(NSString *)title ;

#pragma mark -
#pragma mark Automaticaly Saving & Loading
+(void)setExtensions:(NSArray *)extensions ;
+(NSArray *)extensions ;
-(NSString *)filePath ;

#pragma mark -
#pragma mark Repair
-(unsigned)repairWithLogFolderContents ;

#pragma mark -
#pragma mark Deprecated
//-(void)setShouldSavePList:(BOOL)aBool ;
//-(BOOL)shouldSavePList ;
	/*Use setShouldSaveFile: (T2IdentifiedObject) instead.*/
@end


@interface NSObject (T2ThreadListObserver)
-(void)updatedThreadListOfInternalPath:(NSString *)internalPath ;
@end

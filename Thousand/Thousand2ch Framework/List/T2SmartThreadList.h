//
//  T2SmartThreadList.h
//  Thousand
//
//  Created by R. Natori on 平成 20/01/15.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2ThreadList"

@interface T2SmartThreadList : T2ThreadList {
	NSArray	*_sourceThreadListInternalPaths;
	NSArray	*_conditions;
}
-(void)setSourceThreadListInternalPaths:(NSArray *)internalPaths ;
-(NSArray *)sourceThreadListInternalPaths ;
-(void)setSourceThreadLists:(NSArray *)threadLists
-(NSArray *)sourceThreadLists ;

-(void)setConditions:(NSArray *)conditions ;
-(NSArray *)conditions ;
@end
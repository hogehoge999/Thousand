//
//  T2SplitView.h
//  Thousand
//
//  Created by R. Natori on  07/03/17.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THSplitView : NSSplitView {
	BOOL _usingOnePixDivider;
	NSString *_positionAutoSaveName;
}

-(void)setUsingOnePixDivider:(BOOL)usingOnePixDivider ;
-(BOOL)usingOnePixDivider;

-(void)savePositionUsingName:(NSString *)name ;
-(void)setPositionUsingName:(NSString *)name ;

-(void)setPositionAutosaveName:(NSString *)name ;
-(NSString *)positionAutosaveName ;
 

-(void)replaceWithSubView:(NSView *)view ;
@end

typedef enum {
	T2SplitViewPositionLeft,
	T2SplitViewPositionRight,
	T2SplitViewPositionTop,
	T2SplitViewPositionBottom
} T2SplitViewPosition ;

@interface NSView (T2SplitView)
-(THSplitView *)splitByAddingView:(NSView *)view onPosition:(T2SplitViewPosition)position ;
@end
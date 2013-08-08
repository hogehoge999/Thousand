//
//  THLabelButton.h
//  Thousand
//
//  Created by R. Natori on 平成 20/03/19.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>
#import "THImagePopUpButton.h"


@interface THLabelButton : THImagePopUpButton <T2Labeling> {
}

+(id)labelButtonForToolBar:(NSToolbar *)toolBar ;

-(void)sharedInitialize ;
-(void)setLabel:(int)label ;
-(int)label ;
-(void)updateLabelMenuWithNotification:(NSNotification *)notification ;
@end


@interface THLabelButtonCell : THImagePopUpButtonCell <T2Labeling> {
	int _label;
}

-(void)updateLabelMenu ;
//-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView ;
-(void)updateLabelImage ;
-(void)setLabel:(int)label ;
-(int)label ;
@end

//
//  THImagePopUpButton.h
//  Thousand
//
//  Created by R. Natori on 平成 20/04/02.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THImagePopUpButton : NSPopUpButton {
	NSToolbar *_toolBar;
	BOOL _originFixed;
}
+(id)imagePopUpButtonForToolBar:(NSToolbar *)toolBar ;
-(void)setToolBar:(NSToolbar *)toolBar ;
-(NSToolbar *)toolBar ;
-(void)setImage:(NSImage *)anImage ;
-(NSImage *)image ;
@end

@interface THImagePopUpButtonCell : NSPopUpButtonCell <NSCoding> {
	NSImage *_imageForPopUpButtonCell;
}
-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView ;
-(void)setImageForPopUpButtonCell:(NSImage *)anImage ;
-(NSImage *)imageForPopUpButtonCell ;
@end

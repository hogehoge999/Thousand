//
//  THLabelButton.m
//  Thousand
//
//  Created by R. Natori on 平成 20/03/19.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "THLabelButton.h"


@implementation THLabelButton


+ (Class)cellClass {
	return [THLabelButtonCell class];
}


+(id)labelButtonForToolBar:(NSToolbar *)toolBar {
	THLabelButton *labelButton = [super imagePopUpButtonForToolBar:toolBar];
	[labelButton setLabel:0];
	return labelButton;
}

-(id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	[self sharedInitialize];
	return self;
}

-(id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	[self sharedInitialize];
	return self;
}

-(void)sharedInitialize {
	[(THLabelButtonCell *)[self cell] setMenu:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateLabelMenuWithNotification:)
												 name:T2LabelColorsChangedNotification
											   object:nil];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:T2LabelColorsChangedNotification
												  object:nil];
	[super dealloc];
}

-(void)setLabel:(int)label {
	if (label < 0) {
		[self setEnabled:NO];
	} else {
		[self setEnabled:YES];
	}
	THLabelButtonCell *cell = [self cell];
	[cell setLabel:label];
}
-(int)label {
	THLabelButtonCell *cell = [self cell];
	return [cell label];
}

-(void)updateLabelMenuWithNotification:(NSNotification *)notification {
	[(THLabelButtonCell *)[self cell] setMenu:nil];
}


@end



@implementation THLabelButtonCell

-(void)updateLabelMenu {
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Label", nil)] autorelease];
	[menu addItem:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Label", nil)
											  action:NULL
									   keyEquivalent:@""] autorelease]];
	NSArray *labelMenuItems = [[T2LabeledCellManager sharedManager] menuItems];
	NSEnumerator *menuItemEnumerator = [labelMenuItems objectEnumerator];
	NSMenuItem *menuItem;
	while (menuItem = [menuItemEnumerator nextObject]) {
		[menu addItem:menuItem];
	}
	[self setMenu:menu];
}

- (NSMenu *)menu {
	if (![super menu])
		[self updateLabelMenu];
	return [super menu];
}
/*
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	NSImage *image = [[T2LabeledCellManager sharedManager] popUpImageForLabel:_label];
	NSSize imageSize = [image size];
	float ratio = imageSize.width / imageSize.height;
	
	NSRect destinationRect = cellFrame;
	destinationRect.size.width = (int)(cellFrame.size.height * ratio);
	destinationRect.origin.x += (int)((cellFrame.size.width - destinationRect.size.width)/2);
	
	if ([self isHighlighted]) {
		[image drawInRect:destinationRect
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeXOR
				 fraction:1.0];
		[image drawInRect:destinationRect
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeSourceOver
				 fraction:0.5];
	} else if ([self isEnabled]) {
		[image drawInRect:destinationRect
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
	} else {
		[image drawInRect:destinationRect
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeSourceOver
				 fraction:0.5];
	}
}
 */


-(void)updateLabelImage {
	[self setImageForPopUpButtonCell:[[T2LabeledCellManager sharedManager] popUpImageForLabel:_label]];
}

-(void)setLabel:(int)label {
	_label = label;
	[self setImageForPopUpButtonCell:[[T2LabeledCellManager sharedManager] popUpImageForLabel:_label]];
}
-(int)label {
	return _label;
}

@end


//
//  THTableHeaderView.m
//  Thousand
//
//  Created by R. Natori on 05/10/23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "THTableHeaderView.h"


@implementation THTableHeaderView

/*
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		//
    }
    return self;
}
*/

-(void)setPopUpButton:(NSPopUpButton *)popUpButton {
	//[popUpButton retain];
	[self addSubview:popUpButton];
	[_sorterPopUpButton removeFromSuperview];
	[_sorterPopUpButton release];
	
	_sorterPopUpButton = popUpButton;
	[self fitPopUpButton];
}
-(NSPopUpButton *)popUpButton { return _sorterPopUpButton; }

-(void)fitPopUpButton {
	if (_sorterPopUpButton) {
		NSTableView *tableView = [self tableView];
		int lastColumnIndex = [tableView columnWithIdentifier:@"__variable__"];
		if (lastColumnIndex > -1) {
			NSRect lastColumnRect = [self headerRectOfColumn:lastColumnIndex];
			if (lastColumnRect.size.width > 16) lastColumnRect.size.width -= 16;
			[_sorterPopUpButton setFrame:lastColumnRect];
			[_sorterPopUpButton setHidden:NO];
		} else {
			[_sorterPopUpButton setHidden:YES];
		}
	}
}

- (void)drawRect:(NSRect)rect {
	[self fitPopUpButton];
	[super drawRect:rect];
}

/*
-(IBAction)selectLastColumn:(id)sender {
	NSEvent *dammyEvent = [NSApp currentEvent];
	
	NSTableView *tableView = [self tableView];
	int lastColumnIndex = [[tableView tableColumns] count]-1;
	
	NSArray *sortDescriptors = [tableView sortDescriptors];
	if (sortDescriptors && [sortDescriptors count] > 0) {
		if ([[(NSSortDescriptor *)[sortDescriptors objectAtIndex:0] key] isEqualToString:@"score"]) {
			[tableView setSortDescriptors:[NSArray arrayWithObject:[sortDescriptors objectAtIndex:0]]];
			return;
		}
	}
	
	NSRect lastColumnRect = [self headerRectOfColumn:lastColumnIndex];
	NSPoint dammyPoint = [[[self window] contentView] convertPoint:lastColumnRect.origin fromView:self];
	dammyPoint.x += lastColumnRect.size.width - 8;
	NSEvent *downEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
											 location:dammyPoint
										modifierFlags:0
											timestamp:[dammyEvent timestamp]
										 windowNumber:[dammyEvent windowNumber]
											  context:[dammyEvent context]
										  eventNumber:[dammyEvent eventNumber]+1
										   clickCount:1 pressure:1.0];
	NSEvent *upEvent = [NSEvent mouseEventWithType:NSLeftMouseUp
											location:dammyPoint
									   modifierFlags:0
										   timestamp:[dammyEvent timestamp]
										windowNumber:[dammyEvent windowNumber]
											 context:[dammyEvent context]
										 eventNumber:[dammyEvent eventNumber]+2
										  clickCount:1 pressure:1.0];
	[NSApp postEvent:upEvent atStart:NO];
	[NSApp postEvent:downEvent atStart:YES];
	
}
*/
@end

//
//  T2BrowserMatrix.m
//  Thousand
//
//  Created by R. Natori on 05/08/13.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2BrowserMatrix.h"
#import "T2Browser.h"

@implementation T2BrowserMatrix
- (void)mouseDown:(NSEvent *)event
{
	int row, col;
	
	if ([self getRow: &row column: &col
			forPoint:[self convertPoint:[event locationInWindow] 
							   fromView: nil]]) {
		[self selectCellAtRow: row column: col];
		[self sendAction];
	}
}

-(void)mouseDragged:(NSEvent *)event
{
	
	if ([[NSApplication sharedApplication] currentEvent] != event) return;
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	
	T2Browser *browser = nil;
	NSView *view = self;
	while (view = [view superview]) {
		if ([view isKindOfClass:[T2Browser class]]) {
			browser = (T2Browser *)view;
			break;
		}
	}
	
	if (browser) {
		int column = [browser columnOfMatrix:self];
		int row = [self selectedRow];
		[browser dragWillStartFromColumn:column row:row];
	}
	
	NSCell *draggingCell = [self selectedCell];
	if (!draggingCell) return;
	
	int row = [self selectedRow], col = [self selectedColumn];
	//NSPoint dragPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	//[self getRow: &row column: &col forPoint:dragPoint];
	NSRect cellRect = [self cellFrameAtRow:row column:col];
	NSPoint cellPoint = cellRect.origin;
	cellPoint.y += cellRect.size.height;
	//NSSize offsetSize = (NSSize){cellPoint.x - dragPoint.x, cellPoint.y - dragPoint.y};
	NSImage *draggingImage = [[self imageForCell:draggingCell] copy];
	
	[self dragImage:draggingImage at:cellPoint offset:NSZeroSize 
			  event:event pasteboard:pboard source:self slideBack:YES];
	
	[draggingImage release];
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

#pragma mark -
#pragma mark NSDraggingInfo Informal Protocol
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	if (isLocal) return NSDragOperationEvery;
	else return NSDragOperationNone;
}

#pragma mark -
#pragma mark Utilities
-(NSImage *)imageForCell:(NSCell *)aCell {
    NSImage *image = nil;
    NSBitmapImageRep *bits = nil;
	
    NSRect textFrame;
	
    textFrame.size = [aCell cellSize];
    textFrame.origin = NSZeroPoint;
	
    image = [[NSImage alloc] initWithSize:textFrame.size];
    [image setBackgroundColor:[NSColor blueColor]];
	
    [image lockFocus];
    [aCell drawInteriorWithFrame:textFrame inView:[NSView focusView]];
    bits = [[NSBitmapImageRep alloc] initWithFocusedViewRect:textFrame];
    [image unlockFocus];
	
	
    [bits release];
    return [image autorelease];
}
@end

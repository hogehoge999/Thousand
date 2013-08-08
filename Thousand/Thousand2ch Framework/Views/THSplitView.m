//
//  T2SplitView.m
//  Thousand
//
//  Created by R. Natori on  07/03/17.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "THSplitView.h"

static NSString *__defaultName = @"T2SplitView Position ";

@implementation THSplitView

-(void)dealloc {
	
	if (_positionAutoSaveName) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[self savePositionUsingName:_positionAutoSaveName];
		[_positionAutoSaveName release];
	}
	
	[super dealloc];
}


-(void)setUsingOnePixDivider:(BOOL)usingOnePixDivider {
	_usingOnePixDivider = usingOnePixDivider;
	[self adjustSubviews];
}
-(BOOL)usingOnePixDivider { return _usingOnePixDivider; }

-(float)dividerThickness {
	if (_usingOnePixDivider) return 1.0;
	return [super dividerThickness];
}

- (void)drawDividerInRect:(NSRect)aRect {
	if (_usingOnePixDivider) {
		[[NSColor grayColor] set];
		NSRectFill(aRect);
	} else {
		[super drawDividerInRect:aRect];
	}
}

-(void)savePositionUsingName:(NSString *)name {
	NSArray *subViews = [self subviews];
	if ([subViews count] == 2 && name) {
		NSSize size0 = [[subViews objectAtIndex:0] frame].size ;
		NSSize size1 = [[subViews objectAtIndex:1] frame].size ;
		NSArray *sizes = [NSArray arrayWithObjects:
			NSStringFromSize(size0),
			NSStringFromSize(size1),
			nil];
		[[NSUserDefaults standardUserDefaults] setObject:sizes
												  forKey:[__defaultName stringByAppendingString:name]];
	}
}
-(void)setPositionUsingName:(NSString *)name {
	NSArray *subViews = [self subviews];
	NSArray *sizes = [[NSUserDefaults standardUserDefaults] objectForKey:[__defaultName stringByAppendingString:name]];
	if (!sizes) return;
	if ([subViews count] == 2 && [sizes count] == 2 && name) {
		NSSize size0 = NSSizeFromString([sizes objectAtIndex:0]);
		NSSize size1 = NSSizeFromString([sizes objectAtIndex:1]);
		[[subViews objectAtIndex:0] setFrameSize:size0];
		[[subViews objectAtIndex:1] setFrameSize:size1];
		[self adjustSubviews];
	}
}


-(void)setPositionAutosaveName:(NSString *)name {
	[self setPositionUsingName:name];
	setObjectWithRetain(_positionAutoSaveName, name);
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(splitViewDidResizeSubviews:)
												 name:NSSplitViewDidResizeSubviewsNotification
											   object:nil];
}
-(NSString *)positionAutosaveName { return _positionAutoSaveName; }

	
-(void)splitViewDidResizeSubviews:(NSNotification *)notification {
	if (_positionAutoSaveName)
		[self savePositionUsingName:_positionAutoSaveName];
}
-(void)replaceWithSubView:(NSView *)view {
	NSArray *subViews = [[[self subviews] copy] autorelease];
	NSEnumerator *subViewEnumerator = [subViews objectEnumerator];
	NSView *subView;
	while (subView = [subViewEnumerator nextObject]) {
		[subView removeFromSuperview];
	}
	NSRect frame = [self frame];
	NSView *superView = [self superview];
	[view setFrame:frame];
	[superView replaceSubview:self with:view];
}
@end

@implementation NSView (T2SplitView)
-(THSplitView *)splitByAddingView:(NSView *)view onPosition:(T2SplitViewPosition)position {
	NSRect frame = [self frame];
	THSplitView *splitView = [[[THSplitView alloc] initWithFrame:frame] autorelease];
	if (position == T2SplitViewPositionRight || position == T2SplitViewPositionLeft) {
		[splitView setVertical:YES];
	} else {
		[splitView setVertical:NO];
	}
	
	NSView *superview = [self superview];
	[[self retain] autorelease];
	[superview replaceSubview:self with:splitView];
	
	[self removeFromSuperview];
	if (position == T2SplitViewPositionRight || position == T2SplitViewPositionBottom) {
		[splitView addSubview:self];
		[splitView addSubview:view];
	} else {
		[splitView addSubview:view];
		[splitView addSubview:self];
	}
	return splitView;
}
@end

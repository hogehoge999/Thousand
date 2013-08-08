//
//  T2Browser.m
//  Thousand
//
//  Created by R. Natori on 08/08/12.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "T2Browser.h"
#import "T2BrowserMatrix.h"

NSString *T2BrowserRowPboardType = @"T2BrowserRowPboardType";

@implementation T2Browser


-(void)dealloc {
	if (_T2Browser_scrollView) {
		[_T2Browser_scrollView removeObserver:self forKeyPath:@"borderType"];
	}
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
					   context:(void *)context {
	if (_T2Browser_scrollView) {
		if ([_T2Browser_scrollView borderType] != _T2Browser_borderType) {
			[_T2Browser_scrollView removeObserver:self forKeyPath:@"borderType"];
			[_T2Browser_scrollView setBorderType:_T2Browser_borderType];
			[_T2Browser_scrollView addObserver:self forKeyPath:@"borderType" options:0 context:NULL];
		}
	}
}

- (void)setBorderType:(NSBorderType)borderType {
	_T2Browser_borderType = borderType;
	
	if (_T2Browser_scrollView) {
		if ([_T2Browser_scrollView borderType] != _T2Browser_borderType) {
			[_T2Browser_scrollView removeObserver:self forKeyPath:@"borderType"];
			[_T2Browser_scrollView setBorderType:_T2Browser_borderType];
			[_T2Browser_scrollView addObserver:self forKeyPath:@"borderType" options:0 context:NULL];
		}
	} else {
		NSArray *subviews = [self subviews];
		NSView *subView;
		unsigned i;
		for (i=0; i<[subviews count]; i++) {
			subView = [subviews objectAtIndex:i];
			
			if ([subView isKindOfClass:[NSScrollView class]]) {
				_T2Browser_scrollView = (NSScrollView *)subView;
				[_T2Browser_scrollView setBorderType:_T2Browser_borderType];
				[_T2Browser_scrollView addObserver:self forKeyPath:@"borderType" options:0 context:NULL];
			}
			
		}
	}
}
- (NSBorderType)borderType { 
	return _T2Browser_borderType;
}

-(void)setRowFont:(NSFont *)font {
	setObjectWithRetain(_rowFont, font);
	
	NSCell *browserCell = [self cellPrototype];
	[browserCell setFont:font];
	[self setCellPrototype:browserCell];
	
	unsigned i;
	int lastColumn = [self lastColumn];
	if (lastColumn<0 || lastColumn == NSNotFound) return;
	for (i=0; i<=lastColumn; i++) {
		NSMatrix *matrix = [self matrixInColumn:i];
		
		NSArray *cells = [matrix cells];
		NSEnumerator *cellEnumerator = [cells objectEnumerator];
		NSCell *cell;
		while (cell = [cellEnumerator nextObject]) {
			[cell setFont:font];
		}
	}
	
	[self setNeedsDisplay:YES];
}
-(NSFont *)rowFont {
	return _rowFont;
}
-(void)setRowHeight:(float)height {
	_rowHeight = height;
	
	unsigned i;
	int lastColumn = [self lastColumn];
	if (lastColumn<0 || lastColumn == NSNotFound) return;
	for (i=0; i<=lastColumn; i++) {
		NSMatrix *matrix = [self matrixInColumn:i];
		NSSize cellSize = [matrix cellSize];
		cellSize.height = _rowHeight;
		[matrix setCellSize:cellSize];
		[matrix sizeToCells];
	}
	
	[self setNeedsDisplay:YES];
	
}
-(float)rowHeight {
	return _rowHeight;
}

- (void)reloadColumn:(int)column {
	[super reloadColumn:column];
	
	NSMatrix *matrix = [self matrixInColumn:column];
	NSSize cellSize = [matrix cellSize];
	cellSize.height = _rowHeight;
	[matrix setCellSize:cellSize];
	[matrix sizeToCells];
}

- (void)loadColumnZero {
	[super loadColumnZero];
	
	NSMatrix *matrix = [self matrixInColumn:0];
	NSSize cellSize = [matrix cellSize];
	cellSize.height = _rowHeight;
	[matrix setCellSize:cellSize];
	[matrix sizeToCells];
}

-(void)dragWillStartFromColumn:(int)column row:(int)row {
	NSNumber *columnNumber = [NSNumber numberWithInt:column];
	NSNumber *rowNumber = [NSNumber numberWithInt:row];
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								columnNumber, @"column",
								rowNumber, @"row",
								nil];
	
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[pboard declareTypes:[NSArray arrayWithObject:T2BrowserRowPboardType]
				   owner:self];
	[pboard setPropertyList:dictionary forType:T2BrowserRowPboardType];
}
@end

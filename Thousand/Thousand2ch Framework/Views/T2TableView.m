//
//  T2TableView.m
//  Thousand
//
//  Created by R. Natori on 05/09/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2TableView.h"

@interface T2TableView (T2TableViewPriVate)
-(void)storeInitialTableColumns ;
@end

@implementation T2TableView

-(id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	[self storeInitialTableColumns];
	return self;
}

-(void)dealloc {
	[_tableColumnsDictionary release];
	[super dealloc];
}

-(void)storeInitialTableColumns {
	NSArray *initialTableColumns = [[[self tableColumns] copy] autorelease];
	NSEnumerator *enumerator = [initialTableColumns objectEnumerator];
	NSTableColumn *tableColumn ;
	if (!_tableColumnsDictionary) {
	
		if (!initialTableColumns) return;
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
		
		while (tableColumn = [enumerator nextObject]) {
			NSString *identifier = [tableColumn identifier];
			if (identifier) {
				[dictionary setObject:tableColumn forKey:identifier];
			}
		}
		
		_tableColumnsDictionary = [dictionary copy];
	}
}
-(NSArray *)initialTableColumns {
	return [_tableColumnsDictionary allValues];
}


-(void)setTableColumnSettings:(NSArray *)columnSettings {
	// Leopard Resize Style
	BOOL runnningOnTiger = NO;
	int style = 0;
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
		if (MacVersion >= 0x1040){
			runnningOnTiger = YES;
			style = [self columnAutoresizingStyle];
			[self setColumnAutoresizingStyle:0];
		}
	}
	//[self tableColumns]
	NSEnumerator *columnEnumerator = [[self tableColumns] reverseObjectEnumerator];
	//NSTableColumn *tempColumn = nil;
    // ここでエクセプションでてるようなので一時的にコメントアウト
    // 逆順で消せたよう？これの存在意義がよくわからない
    // 消さないとスレッド一覧のタブが増え続ける

    //	while (tempColumn = [columnEnumerator nextObject]) {
//
//        NSLog(@"id = %@", [tempColumn valueForKey:@"identifier"]);
//        
//		[self removeTableColumn:tempColumn];
//	}
	for (NSTableColumn *tempColumn in columnEnumerator)
    {
		[self removeTableColumn:tempColumn];
	}
	
	NSEnumerator *dictionaryEnumerator = [columnSettings objectEnumerator];
	NSDictionary *dictionary = nil;
	while (dictionary = [dictionaryEnumerator nextObject]) {
		NSString *identifier = [dictionary objectForKey:@"identifier"];
		NSNumber *widthNumber = [dictionary objectForKey:@"width"];
		if (identifier) {
			NSTableColumn *tableColumn = [_tableColumnsDictionary objectForKey:identifier];
			if (tableColumn) {
				[self addTableColumn:tableColumn];
				
				if (widthNumber) {
					[tableColumn setWidth:[widthNumber floatValue]];
				}
			}
		}
	}	
	if (runnningOnTiger) {
		[self setColumnAutoresizingStyle:style];
	}
}
-(NSArray *)tableColumnSettings {
	NSMutableArray *tableColumnSettings = [NSMutableArray array];
	
	NSEnumerator *columnEnumerator = [[self tableColumns] objectEnumerator];
	NSTableColumn *tempColumn = nil;
	while (tempColumn = [columnEnumerator nextObject]) {
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
		NSString *identifier = [tempColumn identifier];
		if (identifier) {
			[dictionary setObject:identifier forKey:@"identifier"];
			[dictionary setObject:[NSNumber numberWithFloat:[tempColumn width]] forKey:@"width"];
			[tableColumnSettings addObject:[[dictionary copy] autorelease]];
		}
	}
	return [[tableColumnSettings copy] autorelease];
}

-(void)setVisible:(BOOL)visible ofTableColumnWithIdentifier:(NSString *)tableColumnIdentifier {
	NSArray *tableColumnSettings = [self tableColumnSettings];
	NSArray *identifiers = [tableColumnSettings valueForKey:@"identifier"];
	if (visible) {
		if (![identifiers containsObject:tableColumnIdentifier]) {
			NSDictionary *dictionary = [NSDictionary dictionaryWithObject:tableColumnIdentifier forKey:@"identifier"];
			NSArray *newTableColumnSettings = [tableColumnSettings arrayByAddingObject:dictionary];
			[self setTableColumnSettings:newTableColumnSettings];
		}
	} else {
		NSInteger index = [identifiers indexOfObject:tableColumnIdentifier];
		if (index != NSNotFound) {
			NSMutableArray *newTableColumnSettings = [[tableColumnSettings mutableCopy] autorelease];
			[newTableColumnSettings removeObjectAtIndex:index];
			[self setTableColumnSettings:newTableColumnSettings];
		}
	}
}
-(BOOL)visibleOfTableColumnWithIdentifier:(NSString *)tableColumnIdentifier {
	return ([self columnWithIdentifier:tableColumnIdentifier] != -1);
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	if (isLocal) return [super draggingSourceOperationMaskForLocal:isLocal];
	return NSDragOperationCopy;
}


-(void)setDeleteKeyAction:(SEL)selector { _deleteKeyAction = selector; }
-(SEL)deleteKeyAction { return _deleteKeyAction; }

-(void)setOtherMouseAction:(SEL)selector { _otherMouseAction = selector; }
-(SEL)otherMouseAction { return _otherMouseAction; }

- (void)keyDown:(NSEvent *)anEvent {
	NSString *keyString = [anEvent characters];
	if (![anEvent isARepeat]) {
		id target = [self target];
		switch ([keyString characterAtIndex:0]) {
			case NSDeleteCharacter: {
				if (_deleteKeyAction && [target respondsToSelector:_deleteKeyAction] ) {
					[target performSelector:_deleteKeyAction withObject:self];
					return;
				}
				break;
			}
			case NSCarriageReturnCharacter: {
				SEL doubleAction = [self doubleAction];
				if (doubleAction && [target respondsToSelector:doubleAction] ) {
					[target performSelector:doubleAction withObject:self];
					return;
				}
				break;
			}
		}
	}
	[super keyDown:anEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	
	NSPoint locationInWindow = [theEvent locationInWindow];
	NSPoint locationInSelf = [self convertPoint:locationInWindow fromView:nil];
	NSInteger row = [self rowAtPoint:locationInSelf];
	if (row < 0) return;
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	if ([selectedRowIndexes containsIndex:row]) {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:YES];
	} else {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	}
	
	[super rightMouseDown:theEvent];
}

- (void)otherMouseDown:(NSEvent *)theEvent {
	
	NSPoint locationInWindow = [theEvent locationInWindow];
	NSPoint locationInSelf = [self convertPoint:locationInWindow fromView:nil];
	NSInteger row = [self rowAtPoint:locationInSelf];
	if (row < 0) return;
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	
	
	id target = [self target];
	if (_otherMouseAction && [target respondsToSelector:_otherMouseAction] ) {
		[target performSelector:_otherMouseAction withObject:self];
		return;
	}
}
@end

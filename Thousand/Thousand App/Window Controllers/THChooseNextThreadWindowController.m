//
//  THChooseNextThreadWindowController.m
//  Thousand
//
//  Created by R. Natori on 平成21/09/02.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import "THChooseNextThreadWindowController.h"
#import "THPrefWindowController.h"

static NSMutableSet *__instances = nil;

@implementation THChooseNextThreadWindowController

#pragma mark -
#pragma mark Accessors
-(void)setOldThreadFace:(T2ThreadFace *)oldThreadFace { setObjectWithRetain(_oldThreadFace, oldThreadFace); }
-(T2ThreadFace *)oldThreadFace { return _oldThreadFace; }
-(void)setNewThreadFace:(T2ThreadFace *)newThreadFace { setObjectWithRetain(_newThreadFace, newThreadFace); }
-(T2ThreadFace *)newThreadFace { return _newThreadFace; }
-(void)setNewThreadFaces:(NSArray *)newThreadFaces { setObjectWithRetain(_newThreadFaces, newThreadFaces); }
-(NSArray *)newThreadFaces { return _newThreadFaces; }

-(void)dealloc {
	if (_threadList) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[_threadList cancelLoading];
		[_threadList release];
	}
	[_oldThreadFace release];
	[_newThreadFace release];
	[_threadFaces release];
	[_newThreadFaces release];
	[super dealloc];
}

#pragma mark -
#pragma mark Sheet
+(id)beginSheetModalForWindow:(NSWindow *)docWindow withOldThreadFace:(T2ThreadFace *)oldThreadFace
				newThreadFace:(T2ThreadFace *)newThreadFace delegate:(id)delegate didEndSelector:(SEL)didEndSelector {
	THChooseNextThreadWindowController *winController = 
	[[[self alloc] initSheetModalForWindow:docWindow
						 withOldThreadFace:oldThreadFace
							 newThreadFace:newThreadFace
								  delegate:delegate
							didEndSelector:didEndSelector] autorelease];
	[winController beginSheet];
	return winController;
}
-(id)initSheetModalForWindow:(NSWindow *)docWindow withOldThreadFace:(T2ThreadFace *)oldThreadFace
			   newThreadFace:(T2ThreadFace *)newThreadFace  delegate:(id)delegate didEndSelector:(SEL)didEndSelector {
	if (!newThreadFace) {
		self = [self initWithWindowNibName:@"THChooseNextThreadWindow"];
	} else {
		self = [self initWithWindowNibName:@"THRegisterNextThreadWindow"];
	}
	_docWindow = docWindow;
	_delegate = delegate;
	_didEndSelector = didEndSelector;
	
	_oldThreadFace = [oldThreadFace retain];
	_newThreadFace = [newThreadFace retain];
	
	return self;
}
-(void)beginSheet {
	[NSApp beginSheet:[self window]
	   modalForWindow:_docWindow
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
	if (!__instances) __instances = [[NSMutableSet alloc] init];
	[__instances addObject:self];
}
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
	if (_delegate && _didEndSelector) {
		[_delegate performSelector:_didEndSelector withObject:_newThreadFace];
	}
	[__instances removeObject:self];
}
- (void)windowDidLoad {
	
	if ([_oldThreadFace label] == 0) {
		[_inheritLabelCheckBox setEnabled:NO];
		[_inheritLabelCheckBox setState:NSOffState];
	}
	if (![[T2SourceList sharedSourceList] bookmarkListFacesContainThreadFace:_oldThreadFace]) {
		[_inheritBookmarkCheckBox setEnabled:NO];
		[_replaceBookmarkCheckBox setEnabled:NO];
		[_inheritBookmarkCheckBox setState:NSOffState];
		[_replaceBookmarkCheckBox setState:NSOffState];
	}
	
	
	if (_newThreadFace) {
		[_messageTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Do you want to treat \"%@\" as the next thread of \"%@\" ?", @"ChooseNextThreadWindow"),
										   [_newThreadFace title], [_oldThreadFace title]]];
		
	} else {
	
		NSFont *font = [[THPrefWindowController sharedPrefWindowController] threadListFont];
		float rowHeight = [[THPrefWindowController sharedPrefWindowController] threadTableRowHeight];
		[_tableView setRowHeight:rowHeight];
		NSArray *tableColumns = [_tableView tableColumns];
		NSEnumerator *tableColumnEnumerator = [tableColumns objectEnumerator];
		NSTableColumn *tableColumn;
		while (tableColumn = [tableColumnEnumerator nextObject]) {
			NSCell *dataCell = [tableColumn dataCell];
			[dataCell setFont:font];
			[tableColumn setDataCell:dataCell];
		}
		[_tableView setNeedsDisplay:YES];
		
		T2ListFace *listFace = [_oldThreadFace threadListFace];
		[self willChangeValueForKey:@"threadList"];
		_threadList = [[listFace list] retain];
		[self didChangeValueForKey:@"threadList"];
		_threadFaces = [[_threadList objects] copy];
		
		[_threadList load];
		if ([_threadList isLoading]) {
			
			[_progressIndicator startAnimation:nil];
			[_statusTextField setHidden:NO];
			[_messageTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Loading Board \"%@\"", @"ChooseNextThreadWindow"), [_threadList title]]];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(threadListDidLoad:)
														 name:T2ListDidEndLoadingNotification
													   object:_threadList];
		} else {
			[self threadListDidLoad:nil];
		}
	}
}

- (void)threadListDidLoad:(NSNotification *)notification {
	NSArray *tempThreadFaces = [[[_threadList objects] copy] autorelease];
	if (_threadFaces && [_threadFaces count] >0) {
		[_threadList setObjects:_threadFaces];
		[_threadFaces release];
		_threadFaces = nil;
	}
	
	NSString *oldTitle = [_oldThreadFace title];
	unsigned oldTitleLength = [oldTitle length];
	NSDate *oldDate = [_oldThreadFace createdDate];
	if (!oldDate) {
		oldDate = [NSDate date];
	}
	
	NSMutableArray *newThreadFaceDictionarys = [NSMutableArray arrayWithCapacity:[tempThreadFaces count]];
	NSEnumerator *tempThreadFacesEnumerator = [tempThreadFaces objectEnumerator];
	T2ThreadFace *newThreadFace;
	while (newThreadFace = [tempThreadFacesEnumerator nextObject]) {
		if (_oldThreadFace != newThreadFace) {
			NSString *newTitle = [newThreadFace title];
			unsigned distance = [newTitle distanceFromString:oldTitle];
			//NSLog(@"%d", distance);
			if (distance != NSNotFound) {
				NSNumber *distanceNumber = [NSNumber numberWithInt:distance];
				NSDate *createdDate = [newThreadFace createdDate];
				if (!createdDate) {
					createdDate = oldDate;
				}
				NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
											newThreadFace, @"threadFace",
											distanceNumber, @"distanceNumber",
											createdDate, @"createdDate", nil];
				[newThreadFaceDictionarys addObject:dictionary];
			}
		}
	}
	
	NSSortDescriptor *secondSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"distanceNumber"
																	ascending:YES] autorelease];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"createdDate"
																	ascending:NO] autorelease];
	[newThreadFaceDictionarys sortUsingDescriptors:[NSArray arrayWithObjects:sortDescriptor, secondSortDescriptor, nil]];
	
	NSMutableArray *newThreadFaces = [NSMutableArray array];
	NSEnumerator *newThreadFaceDictionaryEnumerator = [newThreadFaceDictionarys objectEnumerator];
	NSDictionary *newThreadFaceDictionary;
	while (newThreadFaceDictionary = [newThreadFaceDictionaryEnumerator nextObject]) {
		unsigned distance = [(NSNumber *)[newThreadFaceDictionary objectForKey:@"distanceNumber"] intValue];
		if (distance < (oldTitleLength/2)) {
			[newThreadFaces addObject:[newThreadFaceDictionary objectForKey:@"threadFace"]];
		}
	}
	
	[self setNewThreadFaces:newThreadFaces];
	[_arrayController setSelectionIndex:0];
	
	if ([newThreadFaces count] > 0) {
		[_messageTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Choose the next thread of \"%@\"", @"ChooseNextThreadWindow"), [_oldThreadFace title]]];
	} else {
		[_messageTextField setStringValue:NSLocalizedString(@"Threads not found", @"ChooseNextThreadWindow")];
	}
	
	[_progressIndicator stopAnimation:nil];
	[_statusTextField setHidden:YES];
}

#pragma mark -
#pragma mark Actions

- (IBAction)inheritBookmarkAction:(id)sender {
	if ([_inheritBookmarkCheckBox state] == NSOnState) {
		[_replaceBookmarkCheckBox setEnabled:YES];
	} else {
		[_replaceBookmarkCheckBox setEnabled:NO];
	}
}

- (IBAction)cancelAction:(id)sender {
	[self setNewThreadFace:nil];
	[NSApp endSheet:[self window]];
}
- (IBAction)okAction:(id)sender {
	BOOL inheritLabel = (([_inheritLabelCheckBox state] == NSOnState) && [_inheritLabelCheckBox isEnabled]);
	BOOL inheritBookmark = (([_inheritBookmarkCheckBox state] == NSOnState) && [_inheritBookmarkCheckBox isEnabled]);
	BOOL replaceBookmark = (([_replaceBookmarkCheckBox state] == NSOnState) && [_replaceBookmarkCheckBox isEnabled]);
	
	if (!_newThreadFace) {
		T2ThreadFace *newThreadFace = [[_arrayController selectedObjects] lastObject];
		if (!newThreadFace) {
			[NSApp endSheet:[self window]];
			return;
		}
		[self setNewThreadFace:newThreadFace];
	}
	
	if (inheritLabel) {
		[_newThreadFace setLabel:[_oldThreadFace label]];
	}
	
	if (inheritBookmark) {
		T2SourceList *sourceList = [T2SourceList sharedSourceList];
		if (replaceBookmark) {
			[sourceList replaceBookmarkedThreadFace:_oldThreadFace withThreadFace:_newThreadFace];
		} else {
			NSArray *bookmarkListFaces = [sourceList bookmarkListFacesContainThreadFace:_oldThreadFace];
			if (bookmarkListFaces) {
				NSEnumerator *bookmarkListFaceEnumerator = [bookmarkListFaces objectEnumerator];
				T2BookmarkListFace *bookmarkListFace;
				while (bookmarkListFace = [bookmarkListFaceEnumerator nextObject]) {
					T2BookmarkList *bookmarkList = (T2BookmarkList *)[bookmarkListFace list];
					NSMutableArray *newObjects = [[[bookmarkList objects] mutableCopy] autorelease];
					[newObjects addObject:_newThreadFace];
					[bookmarkList setObjects:newObjects];
				}
			}
		}
	}
		
	[NSApp endSheet:[self window]];
}
@end

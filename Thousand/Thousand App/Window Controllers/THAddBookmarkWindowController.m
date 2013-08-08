#import "THAddBookmarkWindowController.h"
#import "THBookmarkController.h"

static NSMutableSet *__instances = nil;

@implementation THAddBookmarkWindowController

#pragma mark -
#pragma mark Accessors
-(NSArray *)allBookmarkLists {
	NSArray *listFaces = [[T2SourceList sharedSourceList] objects];
	NSMutableArray *bookmarkLists = [NSMutableArray array];
	T2ListFace *listFace;
	NSEnumerator *listFaceEnumerator = [listFaces objectEnumerator];
	while (listFace = [listFaceEnumerator nextObject]) {
		if ([listFace isKindOfClass:[T2BookmarkListFace class]]) {
			[bookmarkLists addObject:[listFace list]];
		}
	}
	return bookmarkLists;
}
-(void)setSelectedBookmarkList:(T2BookmarkList *)bookmarkList {
	setObjectWithRetain(_selectedBookmarkList, bookmarkList);
}
-(T2BookmarkList *)selectedBookmarkList { return _selectedBookmarkList; }

#pragma mark -
#pragma mark Sheet
+(id)beginSheetModalForWindow:(NSWindow *)docWindow threadFaces:(NSArray *)threadFaces {
	
	THAddBookmarkWindowController *winController = [[[self alloc] initSheetModalForWindow:docWindow
																		  threadFaces:threadFaces]
		autorelease];
	[winController beginSheet];
	return winController;
}
-(id)initSheetModalForWindow:(NSWindow *)docWindow threadFaces:(NSArray *)threadFaces {
	self = [self initWithWindowNibName:@"THAddBookmarkWindow"];
	_docWindow = docWindow;
	_threadFaces = [threadFaces retain];
	NSArray *allBookmarkLists = [self allBookmarkLists];
	if (allBookmarkLists && [allBookmarkLists count] > 0) {
		_selectedBookmarkList = [[allBookmarkLists objectAtIndex:0] retain];
	}
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
	[__instances removeObject:self];
}

-(void)dealloc {
	[_threadFaces release];
	[_selectedBookmarkList release];
	[super dealloc];
}

#pragma mark -
#pragma mark Actions
- (IBAction)newBookmark:(id)sender {
	[self willChangeValueForKey:@"allBookmarkLists"];
	[THBookmarkController addCustomBookmarkListToSourceList];
	[self didChangeValueForKey:@"allBookmarkLists"];
	[self setSelectedBookmarkList:[[self allBookmarkLists] lastObject]];
}
- (IBAction)cancelAction:(id)sender {
	[NSApp endSheet:[self window]];
}
- (IBAction)okAction:(id)sender {
	if (_selectedBookmarkList && _threadFaces) {
		[_selectedBookmarkList addObjects:_threadFaces];
	}
	[NSApp endSheet:[self window]];
}

@end

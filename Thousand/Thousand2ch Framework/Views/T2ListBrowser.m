//
//  T2ListBrowser.m
//  Thousand
//
//  Created by R. Natori on 08/12/21.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2ListBrowser.h"
#import "T2ListFace.h"
#import "T2List.h"
#import "T2ThreadList.h"
#import "T2NSPasteboardAdditions.h"
#import "T2PluginManager.h"

@interface T2ListBrowserInternalDelegate : NSObject {
	T2List *_rootList;
	NSArray *_listArray;
	
	float _rowHeight;
	
	T2ListBrowser *_listBrowser;
	NSObject *_delegate;
}

-(void)setRootListFace:(T2ListFace *)rootList ;
-(T2ListFace *)rootListFace ;
-(void)setRootList:(T2List *)rootList ;
-(T2List *)rootList ;
-(void)setListArray:(NSArray *)listArray ;
-(NSArray *)listArray ;
-(void)setRowHeight:(float)rowHeight ;
-(float)rowHeight ;
-(void)setListBrowser:(T2ListBrowser *)listBrowser ;
-(T2ListBrowser *)listBrowser ;
-(void)setDelegate:(NSObject *)delegate ;
-(NSObject *)delegate ;
- (BOOL)browserSelectRow:(int)row inColumn:(int)column ;
-(void)listBrowserDragWillStartFromColumn:(int)column row:(int)row ;
@end

@interface T2ListBrowser (T2ListBrowserPrivate)
-(void)initListBrowser ;

@end

@implementation T2ListBrowser

- (id)init {
	self = [super init];
	[self initListBrowser];
	return self;
}
- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	[self initListBrowser];
	return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	[self initListBrowser];
	return self;
}

-(void)initListBrowser {
	if (!_internalDelegate) {
		[self setInternalDelegate:[[[T2ListBrowserInternalDelegate alloc] init] autorelease]];
	}
}

-(void)awakeFromNib {
	if (_listBrowserDelegate)
		[self setListBrowserDelegate:_listBrowserDelegate];
}

-(void)dealloc {
	[self setRootList:nil];
	[self setListBrowserDelegate:nil];
	[self setInternalDelegate:nil];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Methods
-(void)dragWillStartFromColumn:(int)column row:(int)row {
	[_internalDelegate listBrowserDragWillStartFromColumn:column row:row];
}

#pragma mark -
#pragma mark Accessors

-(void)setRootListFace:(T2ListFace *)rootListFace {
	[_internalDelegate setRootListFace:rootListFace];
}
-(T2ListFace *)rootListFace {
	return [_internalDelegate rootListFace];
}

-(void)setRootList:(T2List *)rootList {
	[_internalDelegate setRootList:rootList];
}
-(T2List *)rootList {
	return [_internalDelegate rootList];
}

-(void)setRowHeight:(float)rowHeight {
	[_internalDelegate setRowHeight:rowHeight];
}
-(float)rowHeight {
	return [_internalDelegate rowHeight];
}

-(void)setInternalDelegate:(T2ListBrowserInternalDelegate *)delegate {
	if (_internalDelegate) {
		[_internalDelegate setListBrowser:nil];
	}
	setObjectWithRetain(_internalDelegate, delegate);
	if (_internalDelegate) {
		[_internalDelegate setListBrowser:self];
	}
}
-(T2ListBrowserInternalDelegate *)internalDelegate { return _internalDelegate; }


-(void)setListBrowserDelegate:(NSObject *)delegate {
	[_internalDelegate setDelegate:delegate];
}
-(NSObject *)listBrowserDelegate {
	return [_internalDelegate delegate];
}
@end

@implementation T2ListBrowserInternalDelegate

-(id)init {
	self = [super init];
	_rowHeight = 14;
	return self;
}

-(void)setRootListFace:(T2ListFace *)rootList {
	T2List *list = [rootList list];
	[self setRootList:list];
}
-(T2ListFace *)rootListFace {
	return [_rootList listFace];
}

-(void)setRootList:(T2List *)rootList {
	setObjectWithRetain(_rootList, rootList);
	[self setListArray:[NSArray arrayWithObject:_rootList]];
	[_listBrowser loadColumnZero];
}
-(T2List *)rootList { return _rootList; }

-(void)setListArray:(NSArray *)listArray {
	if (listArray == _listArray) return;
	
	NSEnumerator *enumerator = [_listArray objectEnumerator];
	T2List *list;
	while (list = [enumerator nextObject]) {
		[list removeObserver:self forKeyPath:@"objects"];
	}
	
	setObjectWithCopy(_listArray, listArray);
	
	enumerator = [_listArray objectEnumerator];
	while (list = [enumerator nextObject]) {
		[list addObserver:self forKeyPath:@"objects" options:0 context:NULL];
	}
}
-(NSArray *)listArray { return _listArray; }

-(void)setRowHeight:(float)rowHeight { _rowHeight = rowHeight; }
-(float)rowHeight { return _rowHeight; }

-(void)setListBrowser:(T2ListBrowser *)listBrowser { _listBrowser = listBrowser; }
-(T2ListBrowser *)listBrowser { return _listBrowser; }
-(void)setDelegate:(NSObject *)delegate { _delegate = delegate; }
-(NSObject *)delegate { return _delegate; }

#pragma mark -
#pragma mark NSBrowser delegate methods
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
	T2List *listWillExpand = [_listArray objectAtIndex:column];
	T2ListFace *listFace = [[listWillExpand objects] objectAtIndex:row];
	//T2List *list = [listFace list];
	
	[(NSBrowserCell *)cell setLeaf:[listFace isLeaf]];
	[(NSBrowserCell *)cell setTitle:[listFace title]];
	
}
//- (BOOL)browser:(NSBrowser *)sender selectRow:(int)row inColumn:(int)column {
-(IBAction)selectActionInBrowser:(id)sender {
	int column = [_listBrowser selectedColumn];
	int row = [_listBrowser selectedRowInColumn:column];
	[self browserSelectRow:row inColumn:column];

	[[_listBrowser window] makeFirstResponder:[_listBrowser matrixInColumn:column]];
}
- (BOOL)browserSelectRow:(int)row inColumn:(int)column {
	if (column<0 || row<0) return 0; 
	if ([_listArray count]>(column+1)) {
		// remove far column's lists
		//unsigned i,maxCount = [_listArray count];
		
		NSArray *listArray = [_listArray subarrayWithRange:NSMakeRange(0, column+1)];
		[self setListArray:listArray];
	}
	T2List *currentList = [_listArray objectAtIndex:column];
	T2ListFace *selectedListFace = [[currentList objects] objectAtIndex:row];
	T2List *selectedList = [selectedListFace list];
	
	if (_delegate) {
		if ([_delegate respondsToSelector:@selector(listBrowser:didSelectListFace:)]) {
			[_delegate listBrowser:_listBrowser didSelectListFace:selectedListFace];
		}
	}
	
	if (![selectedList isKindOfClass:[T2ThreadList class]]) {
		NSArray *listArray = [_listArray arrayByAddingObject:selectedList];
		[self setListArray:listArray];
		[_listBrowser validateVisibleColumns];
		[_listBrowser reloadColumn:column+1];
	}

	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	if (![pluginManager isSearchList:selectedList]) {
		[selectedList load];
	}
	return YES;
}
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
	if (column<0) return 0;
	
	if ([_listArray count] > column) {
		int i = [[(T2List *)[_listArray objectAtIndex:column] objects] count];
		return i;
	}
	else return 0;
}
- (BOOL)browser:(NSBrowser *)sender isColumnValid:(int)column {
	if (column<0) return NO; 
	if ([_listArray count] > column) {
		
		NSMatrix *matrix = [_listBrowser matrixInColumn:column];
		NSSize cellSize = [matrix cellSize];
		cellSize.height = _rowHeight;
		[matrix setCellSize:cellSize];
		return YES;
	}
	else return NO;
}

-(void)listBrowserDragWillStartFromColumn:(int)column row:(int)row {
	
	T2List *currentList = [_listArray objectAtIndex:column];
	T2ListFace *selectedListFace = [[currentList objects] objectAtIndex:row];
	
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[pboard declareTypes:[NSArray arrayWithObject:T2IdentifiedListFacesPasteboardType] owner:nil];
	[pboard setIdentifiedListFaces:[NSArray arrayWithObject:selectedListFace]];
}
@end
//
//  T2ThreadListTableView.m
//  Thousand
//
//  Created by R. Natori on 08/12/23.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2ThreadListTableView.h"
#import "T2NSPasteboardAdditions.h"
#import "T2ListFace.h"
#import "T2ThreadList.h"
#import "T2ThreadFace.h"
#import "T2BookmarkList.h"
#import "T2BookmarkListFace.h"
#import "T2FilterArrayController.h"
#import "T2PluginManager.h"


static NSArray *__threadListTableAcceptablePboardTypes = nil;
static id <T2ThreadImporting_v100> __localFileImporter = nil;

@interface T2ThreadListTableViewInternalDelegate : NSObject {
	T2ThreadList *_threadList;
	T2ThreadListTableView *_threadListTableView;
	T2FilterArrayController *_threadFacesController ;
	NSObject *_delegate;
}

-(void)setThreadListFace:(T2ListFace *)threadListFace ;
-(T2ListFace *)threadListFace ;
-(void)setThreadList:(T2ThreadList *)threadList ;
-(T2ThreadList *)threadList ;

-(void)setThreadListTableView:(T2ThreadListTableView *)threadListTableView ;
-(T2ThreadListTableView *)threadListTableView ;
-(void)setDelegate:(NSObject *)delegate ;
-(NSObject *)delegate ;

-(IBAction)threadListTableViewClicked:(id)sender ;
-(IBAction)threadListTableViewDoubleClicked:(id)sender ;
//-(IBAction)threadListTableViewDeleteKeyDown:(id)sender ;
@end

@interface T2ThreadListTableView (T2ThreadListTableViewInternal)
#pragma mark -
#pragma mark Factory and Init
-(void)initThreadListTableView ;
@end


@implementation T2ThreadListTableView

+(void)setClassLocalFileImporter:(id <T2ThreadImporting_v100>)localFileImporter {
	__localFileImporter = localFileImporter;
}

+(void)initialize {
	if (__threadListTableAcceptablePboardTypes) return;
	__threadListTableAcceptablePboardTypes = [[NSArray arrayWithObjects:
											   T2TableRowIndexesPasteboardType,
											   T2IdentifiedThreadFacesPasteboardType,
											   NSFilenamesPboardType, nil] retain];
}

- (id)init {
	self = [super init];
	[self initThreadListTableView];
	return self;
}
- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	[self initThreadListTableView];
	return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	[self initThreadListTableView];
	return self;
}
-(void)initThreadListTableView {
	[self registerForDraggedTypes:__threadListTableAcceptablePboardTypes];
	if (!_internalDelegate) {
		[self setInternalDelegate:[[[T2ThreadListTableViewInternalDelegate alloc] init] autorelease]];
	}
}
-(void)awakeFromNib {
	/*
	if (_sourceListTableViewDelegate)
		[self setSourceListTableViewDelegate:_sourceListTableViewDelegate];
	 */
}

-(void)dealloc {
	[self setInternalDelegate:nil];
	
	[super dealloc];
}

-(void)setThreadListFace:(T2ListFace *)threadListFace {
	[_internalDelegate setThreadListFace:threadListFace];
}
-(T2ListFace *)threadListFace {
	return [_internalDelegate threadListFace];
}
-(void)setThreadList:(T2ThreadList *)threadList {
	[_internalDelegate setThreadList:threadList];
}
-(T2ThreadList *)threadList {
	return [_internalDelegate threadList];
}

-(void)setInternalDelegate:(T2ThreadListTableViewInternalDelegate *)delegate {
	if (_internalDelegate) {
		[_internalDelegate setThreadListTableView:nil];
	}
	setObjectWithRetain(_internalDelegate, delegate);
	if (_internalDelegate) {
		[_internalDelegate setThreadListTableView:self];
	}
	[self setDelegate:delegate];
	[self setDataSource:delegate];
	[self setTarget:delegate];
	[self setAction:@selector(threadListTableViewClicked:)];
	[self setDoubleAction:@selector(threadListTableViewDoubleClicked:)];
	[self setDeleteKeyAction:@selector(threadListTableViewDeleteKeyDown:)];
}
-(T2ThreadListTableViewInternalDelegate *)internalDelegate { return _internalDelegate; }

-(void)setThreadListTableViewDelegate:(NSObject *)delegate {
	[_internalDelegate setDelegate:delegate];
}
-(NSObject *)threadListTableViewDelegate { return [_internalDelegate delegate]; }
@end

@implementation T2ThreadListTableViewInternalDelegate

-(id)init {
	self = [super init];
	_threadFacesController = [[T2FilterArrayController alloc] init];
	[_threadFacesController bind:@"contentArray" toObject:self
					 withKeyPath:@"threadList.objects" options:nil];
	return self;
}
-(void)dealloc {
	[_threadFacesController unbind:@"contentArray"];
	[_threadFacesController release];
	_threadFacesController = nil;
	
	[_threadList release];
	_threadList = nil;
	
	[super dealloc];
}

-(void)setThreadListFace:(T2ListFace *)threadListFace {
	T2ThreadList *threadList = (T2ThreadList *)[threadListFace list];
	[self setThreadList:threadList];
}
-(T2ListFace *)threadListFace {
	return [_threadList listFace];
}
-(void)setThreadList:(T2ThreadList *)threadList {
	setObjectWithRetain(_threadList, threadList);
}
-(T2ThreadList *)threadList { return _threadList; }

-(void)setThreadListTableView:(T2ThreadListTableView *)threadListTableView {
	if (_threadListTableView) {
		NSArray *tableColumns = [[[_threadListTableView tableColumns] copy] autorelease];
		NSEnumerator *tableColumnEnumerator = [tableColumns objectEnumerator];
		NSTableColumn *tableColumn;
		while (tableColumn = [tableColumnEnumerator nextObject]) {
			[tableColumn unbind:@"value"];
		}
	}
	
	_threadListTableView = threadListTableView;
	
	if (_threadListTableView) {
		T2PluginManager *pluginManager = [T2PluginManager sharedManager];
		NSSet *threadFaceScoreKeySet = [NSSet setWithArray:[pluginManager threadFaceScoreKeys]];
		T2ThreadFace *threadFace = [[[T2ThreadFace alloc] init] autorelease];
		
		NSArray *tableColumns = [[[_threadListTableView initialTableColumns] copy] autorelease];
		NSEnumerator *tableColumnEnumerator = [tableColumns objectEnumerator];
		NSTableColumn *tableColumn;
		while (tableColumn = [tableColumnEnumerator nextObject]) {
			NSString *identifier = [tableColumn identifier];
			if (identifier && [identifier length]>0) {
				NSString *identifier2 = [identifier stringByAppendingString:@"String"];
				
				SEL selector2 = NSSelectorFromString(identifier2);
				if ([threadFace respondsToSelector:selector2]
					|| [threadFaceScoreKeySet containsObject:identifier2]) {
					
					NSString *keyPath = [@"arrangedObjects." stringByAppendingString:identifier2];
					[tableColumn bind:@"value" toObject:_threadFacesController
						  withKeyPath:keyPath options:nil];
				} else {
					SEL selector = NSSelectorFromString(identifier);
					if ([threadFace respondsToSelector:selector]
						|| [threadFaceScoreKeySet containsObject:identifier]) {
						
						NSString *keyPath = [@"arrangedObjects." stringByAppendingString:identifier];
						[tableColumn bind:@"value" toObject:_threadFacesController
							  withKeyPath:keyPath options:nil];
					}
				}
				[tableColumn setEditable:NO];
			}
		}		
	}
}
-(T2ThreadListTableView *)threadListTableView { return _threadListTableView; }
-(void)setDelegate:(NSObject *)delegate {
	_delegate = delegate;
}
-(NSObject *)delegate {
	return _delegate;
}

#pragma mark -
#pragma mark NSTableView dataSource methods
- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
	//NSString *pBoardType;
	NSMutableIndexSet *selectedRowIndexes = [NSMutableIndexSet indexSet];
	NSEnumerator *rowNumberEnumerator = [rows objectEnumerator];
	NSNumber *rowNumber;
	while (rowNumber = [rowNumberEnumerator nextObject]) {
		[selectedRowIndexes addIndex:[rowNumber unsignedIntValue]];
	}
	
	//T2TableRowIndexesPasteboardType, T2IdentifiedThreadFacesPasteboardType
	NSArray *draggingThreadFaces = [[_threadFacesController arrangedObjects] objectsAtIndexes_panther:selectedRowIndexes];
	NSMutableArray *pboardTypes = [NSMutableArray arrayWithObjects:
								   T2TableRowIndexesPasteboardType,
								   T2IdentifiedThreadFacesPasteboardType,
								   nil];
	
	//NSFilenamesPboardType
	NSMutableArray *fileNames = [NSMutableArray array];
	NSEnumerator *enumerator = [draggingThreadFaces objectEnumerator];
	T2ThreadFace *threadFace;
	while (threadFace = [enumerator nextObject]) {
		NSString *fileName = [threadFace logFilePath];
		if (fileName) [fileNames addObject:fileName];
	}
	if ([fileNames count] > 0) {
		[pboardTypes addObject:NSFilenamesPboardType];
	} else fileNames = nil;
	
	//THThreadListTableRowPboardType
	
	// write
	[pboard declareTypes:pboardTypes owner:self];
	[pboard setTableRowIndexes:selectedRowIndexes];
	[pboard setIdentifiedThreadFaces:draggingThreadFaces];
	if (fileNames)		[pboard setPropertyList:fileNames forType:NSFilenamesPboardType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
	
	NSPasteboard *draggingPasteboard = [info draggingPasteboard];
	NSArray *types = __threadListTableAcceptablePboardTypes;
	//id draggingSource = [info draggingSource];
	
	if (operation == NSTableViewDropOn || !_threadList) return NSDragOperationNone;
	
	id draggingSource = [info draggingSource];
	if (draggingSource != _threadListTableView) {
		
		NSMutableArray *mutableTypes = [[__threadListTableAcceptablePboardTypes mutableCopy] autorelease];
		[mutableTypes removeObject:T2TableRowIndexesPasteboardType];
		types = [[mutableTypes copy] autorelease];
	}
	
	if ([_threadList allowsEditingObjects] && [[_threadList objects] count] == [[_threadFacesController arrangedObjects] count]) {
		NSString *pBoardType = [draggingPasteboard availableTypeFromArray:types];
		if (pBoardType) return NSDragOperationEvery;
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard *draggingPasteboard = [info draggingPasteboard];
	NSArray *types = __threadListTableAcceptablePboardTypes;
	id draggingSource = [info draggingSource];
	
	if (draggingSource != _threadListTableView) {
		
		NSMutableArray *mutableTypes = [[__threadListTableAcceptablePboardTypes mutableCopy] autorelease];
		[mutableTypes removeObject:T2TableRowIndexesPasteboardType];
		types = [[mutableTypes copy] autorelease];
	}
	//NSArray *sourceListObjects = [_sourceList objects];
	
	
	NSString *pBoardType = [draggingPasteboard availableTypeFromArray:types];
	
	if ([pBoardType isEqualToString:T2TableRowIndexesPasteboardType])
		// Drag from self
	{
		NSIndexSet *draggedRowsIndexSet = [draggingPasteboard tableRowIndexes];
		
		unsigned minDraggedRow = [draggedRowsIndexSet indexLessThanIndex:row];
		while (minDraggedRow != NSNotFound) {
			row--;
			minDraggedRow = [draggedRowsIndexSet indexLessThanIndex:minDraggedRow];
		}
		
		NSArray *movingThreadFaces = [[_threadFacesController arrangedObjects] objectsAtIndexes_panther:draggedRowsIndexSet];
		
		NSMutableArray *tempThreadList = [[[_threadFacesController arrangedObjects] mutableCopy] autorelease];
		[tempThreadList removeObjectsAtIndexes_panther:draggedRowsIndexSet];
		[tempThreadList insertObjects_panther:movingThreadFaces atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [draggedRowsIndexSet count])]];
		[_threadList setObjects:tempThreadList];
		
		[_threadListTableView setSortDescriptors:nil];
		return YES;
		
	} else if ([pBoardType isEqualToString:T2IdentifiedThreadFacesPasteboardType])
		// Drag from Other Thread List
	{
		NSArray *movingThreadFaces = [draggingPasteboard identifiedThreadFaces];
		if (operation == NSTableViewDropAbove) {
			[_threadList insertObjects:movingThreadFaces atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [movingThreadFaces count])]];
			
			[_threadListTableView setSortDescriptors:nil];
			
			return YES;
		}
	}	
	
	
	return NO;
}


#pragma mark -
#pragma mark NSTableView delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if (_delegate) {
		NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
		if ([_delegate respondsToSelector:@selector(threadListTableView:didSelectThreadFaces:)]) {
			[_delegate threadListTableView:_threadListTableView didSelectThreadFaces:selectedThreadFaces];
		}
	}
}

-(IBAction)threadListTableViewClicked:(id)sender {
	if (_delegate) {
		NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
		if ([_delegate respondsToSelector:@selector(threadListTableView:didClickThreadFaces:)]) {
			[_delegate threadListTableView:_threadListTableView didClickThreadFaces:selectedThreadFaces];
		}
	}
}
-(IBAction)threadListTableViewDoubleClicked:(id)sender {
	if (_delegate) {
		NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
		if ([_delegate respondsToSelector:@selector(threadListTableView:didDoubleClickThreadFaces:)]) {
			[_delegate threadListTableView:_threadListTableView didDoubleClickThreadFaces:selectedThreadFaces];
		}
	}
}
/*
-(IBAction)threadListTableViewDeleteKeyDown:(id)sender {
	NSArray *selectedThreadFaces = [[[_threadFacesController selectedObjects] copy] autorelease];
	NSIndexSet *indexes = [_threadFacesController selectionIndexes];
	if (!indexes) return;
	
	unsigned i = [indexes firstIndex];
	unsigned selection = i;
	if (i >= [_sourceList firstBookmarkIndex]) {
		unsigned count = [[_sourceList objects] count];
		if (i >= count-1) selection = i-1;
		else selection = i;
		
		NSMutableArray *objects = [[[_sourceList objects] mutableCopy] autorelease];
		[[[objects objectAtIndex:i] list] cancelLoading];
		[objects removeObjectAtIndex:i];
		
		[_sourceList setObjects:objects];
		[_sourceList saveToFile];
	}
	
	if (_delegate) {
		if ([_delegate respondsToSelector:@selector(threadListTableView:didDeleteThreadFaces:)]) {
			[_delegate threadListTableView:_sourceListTableView didDeleteThreadFaces:selectedThreadFaces];
		}
	}
}
 */
@end

/*
 T2PluginManager *pluginManager = [T2PluginManager sharedManager];
 NSSet *threadFaceScoreKeySet = [NSSet setWithArray:[pluginManager threadFaceScoreKeys]];
 T2ThreadFace *threadFace = [[[T2ThreadFace alloc] init] autorelease];
 
 NSArray *tableColumns = [[[_sourceListTableView tableColumns] copy] autorelease];
 NSEnumerator *tableColumnEnumerator = [tableColumns objectEnumerator];
 NSTableColumn *tableColumn;
 while (tableColumn = [tableColumnEnumerator nextObject]) {
 NSString *identifier = [tableColumn identifier];
 if (identifier && [identifier length]>0) {
 NSString *identifier2 = [identifier stringByAppendingString:@"String"];
 
 SEL selector2 = NSSelectorFromString(identifier2);
 if ([threadFace respondsToSelector:selector2]
 || [threadFaceScoreKeySet containsObject:identifier2]) {
 
 NSString *keyPath = [@"arrangedObjects." stringByAppendingString:identifier2];
 [tableColumn bind:@"value" toObject:_sourcesController
 withKeyPath:keyPath options:nil];
 } else {
 SEL selector = NSSelectorFromString(identifier);
 if ([threadFace respondsToSelector:selector]
 || [threadFaceScoreKeySet containsObject:identifier]) {
 
 NSString *keyPath = [@"arrangedObjects." stringByAppendingString:identifier];
 [tableColumn bind:@"value" toObject:_sourcesController
 withKeyPath:keyPath options:nil];
 }
 }
 }
 }
 
 */
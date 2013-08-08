//
//  T2SourceListTableView.m
//  Thousand
//
//  Created by R. Natori on 08/12/19.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2SourceListTableView.h"
#import "T2NSPasteboardAdditions.h"
#import "T2SourceList.h"
#import "T2ListFace.h"
#import "T2ThreadFace.h"
#import "T2BookmarkListFace.h"


static NSArray *__sourceListTableAcceptablePboardTypes = nil;
static id <T2ThreadImporting_v100> __localFileImporter = nil;

@interface T2SourceListTableViewInternalDelegate : NSObject {
	T2SourceList *_sourceList;
	T2SourceListTableView *_sourceListTableView;
	NSArrayController *_sourcesController ;
	NSObject *_delegate;
}

-(void)setSourceList:(T2SourceList *)sourceList ;
-(T2SourceList *)sourceList ;
-(void)setSourceListTableView:(T2SourceListTableView *)sourceListTableView ;
-(T2SourceListTableView *)sourceListTableView ;
-(void)setDelegate:(NSObject *)delegate ;
-(NSObject *)delegate ;

-(IBAction)sourceListTableViewClicked:(id)sender ;
-(IBAction)sourceListTableViewDoubleClicked:(id)sender ;
-(IBAction)sourceListTableViewDeleteKeyDown:(id)sender ;
@end


@interface T2SourceListTableView (T2SourceListTableViewInternal)
#pragma mark -
#pragma mark Factory and Init
-(void)initSourceListTableView ;
@end

@implementation T2SourceListTableView

+(void)setClassLocalFileImporter:(id <T2ThreadImporting_v100>)localFileImporter {
	__localFileImporter = localFileImporter;
}

+(void)initialize {
	if (__sourceListTableAcceptablePboardTypes) return;
	__sourceListTableAcceptablePboardTypes = [[NSArray arrayWithObjects:
											   T2TableRowIndexesPasteboardType,
											   T2IdentifiedListFacesPasteboardType,
											   T2IdentifiedThreadFacesPasteboardType,
											   NSFilenamesPboardType, nil] retain];
}

- (id)init {
	self = [super init];
	[self initSourceListTableView];
	return self;
}
- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	[self initSourceListTableView];
	return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	[self initSourceListTableView];
	return self;
}
-(void)initSourceListTableView {
	[self registerForDraggedTypes:__sourceListTableAcceptablePboardTypes];
	if (!_internalDelegate) {
		[self setInternalDelegate:[[[T2SourceListTableViewInternalDelegate alloc] init] autorelease]];
	}
}

-(void)awakeFromNib {
	if (_sourceListTableViewDelegate)
		[self setSourceListTableViewDelegate:_sourceListTableViewDelegate];
}

-(void)dealloc {
	[self setInternalDelegate:nil];
	
	[super dealloc];
}


-(void)setInternalDelegate:(T2SourceListTableViewInternalDelegate *)delegate {
	if (_internalDelegate) {
		[_internalDelegate setSourceListTableView:nil];
	}
	setObjectWithRetain(_internalDelegate, delegate);
	if (_internalDelegate) {
		[_internalDelegate setSourceListTableView:self];
	}
	[self setDelegate:delegate];
	[self setDataSource:delegate];
	[self setTarget:delegate];
	[self setAction:@selector(sourceListTableViewClicked:)];
	[self setDoubleAction:@selector(sourceListTableViewDoubleClicked:)];
	[self setDeleteKeyAction:@selector(sourceListTableViewDeleteKeyDown:)];
}
-(T2SourceListTableViewInternalDelegate *)internalDelegate { return _internalDelegate; }

-(void)setSourceListTableViewDelegate:(NSObject *)delegate {
	[_internalDelegate setDelegate:delegate];
}
-(NSObject *)sourceListTableViewDelegate { return [_internalDelegate delegate]; }
@end


@implementation T2SourceListTableViewInternalDelegate

-(id)init {
	self = [super init];
	_sourcesController = [[NSArrayController alloc] init];
	[_sourcesController bind:@"contentArray" toObject:self
				 withKeyPath:@"sourceList.objects" options:nil];
	return self;
}
-(void)dealloc {
	[_sourcesController unbind:@"contentArray"];
	[_sourcesController release];
	_sourcesController = nil;
	
	[_sourceList release];
	_sourceList = nil;
	
	[super dealloc];
}

-(void)setSourceList:(T2SourceList *)sourceList {
	setObjectWithRetain(_sourceList, sourceList);
}
-(T2SourceList *)sourceList {
	return _sourceList;
}
-(void)setSourceListTableView:(T2SourceListTableView *)sourceListTableView {
	if (_sourceListTableView) {
		NSArray *tableColumns = [[[_sourceListTableView tableColumns] copy] autorelease];
		NSEnumerator *tableColumnEnumerator = [tableColumns objectEnumerator];
		NSTableColumn *tableColumn;
		while (tableColumn = [tableColumnEnumerator nextObject]) {
			[tableColumn unbind:@"value"];
		}
	}
	
	_sourceListTableView = sourceListTableView;
	
	if (_sourceListTableView) {
		T2ListFace *listFace = [[[T2ListFace alloc] init] autorelease];
		
		NSArray *tableColumns = [[[_sourceListTableView tableColumns] copy] autorelease];
		NSEnumerator *tableColumnEnumerator = [tableColumns objectEnumerator];
		NSTableColumn *tableColumn;
		while (tableColumn = [tableColumnEnumerator nextObject]) {
			NSString *identifier = [tableColumn identifier];
			if (identifier && [identifier length]>0) {
				SEL selector = NSSelectorFromString(identifier);
				if ([listFace respondsToSelector:selector]) {
					[tableColumn bind:@"value" toObject:_sourcesController
						  withKeyPath:[@"arrangedObjects." stringByAppendingString:identifier]
							  options:nil];
				}
				
				if ([identifier isEqualToString:@"title"]) {
					[tableColumn bind:@"editable" toObject:_sourcesController
						  withKeyPath:@"arrangedObjects.allowsEditingTitle" options:nil];
				} else {
					[tableColumn setEditable:NO];
				}
			}
		}
		
	}
}
-(T2SourceListTableView *)sourceListTableView { return _sourceListTableView; }
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
	
	if ([selectedRowIndexes intersectsIndexesInRange:NSMakeRange(0,[_sourceList firstBookmarkIndex])]) {
		return NO;
	}
	
	[pboard declareTypes:[NSArray arrayWithObject:T2TableRowIndexesPasteboardType] owner:nil];
	[pboard setTableRowIndexes:selectedRowIndexes];
		
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
	
	NSPasteboard *draggingPasteboard = [info draggingPasteboard];
	NSArray *types = __sourceListTableAcceptablePboardTypes;
	id draggingSource = [info draggingSource];
	
	if (draggingSource != _sourceListTableView) {
		
		NSMutableArray *mutableTypes = [[__sourceListTableAcceptablePboardTypes mutableCopy] autorelease];
		[mutableTypes removeObject:T2TableRowIndexesPasteboardType];
		types = [[mutableTypes copy] autorelease];
	}
	
	if (row < [_sourceList firstBookmarkIndex]) return NSDragOperationNone;
	
	NSString *pBoardType = [draggingPasteboard availableTypeFromArray:types];
	if (operation == NSTableViewDropAbove) {
		if (pBoardType) return NSDragOperationEvery;
		
	} else if (operation == NSTableViewDropOn) {
		if ([pBoardType isEqualToString:T2IdentifiedThreadFacesPasteboardType]) {
			T2ListFace *dropTargetListFace = [[_sourceList objects] objectAtIndex:row];
			if ([dropTargetListFace isKindOfClass:[T2BookmarkListFace class]]) {
				return NSDragOperationEvery;
			} else {
				[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
				return NSDragOperationEvery;
			}
		} else if ([pBoardType isEqualToString:NSFilenamesPboardType]) {
			[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
			return NSDragOperationEvery;
		}
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard *draggingPasteboard = [info draggingPasteboard];
	NSArray *types = __sourceListTableAcceptablePboardTypes;
	id draggingSource = [info draggingSource];
	
	if (draggingSource != _sourceListTableView) {
		
		NSMutableArray *mutableTypes = [[__sourceListTableAcceptablePboardTypes mutableCopy] autorelease];
		[mutableTypes removeObject:T2TableRowIndexesPasteboardType];
		types = [[mutableTypes copy] autorelease];
	}
	NSArray *sourceListObjects = [_sourceList objects];
	
	NSString *pBoardType = [draggingPasteboard availableTypeFromArray:types];
	if ([pBoardType isEqualToString:T2TableRowIndexesPasteboardType]) { // Drag from Self
		NSIndexSet *draggedRowsIndexSet = [draggingPasteboard tableRowIndexes];
		
		if ([draggedRowsIndexSet indexGreaterThanIndex:row] == NSNotFound) {
			row -= [draggedRowsIndexSet count];
			if (row < [_sourceList firstBookmarkIndex]) return NO;
		} else if ([draggedRowsIndexSet indexLessThanOrEqualToIndex:row] != NSNotFound) {
			return NO;
		}
		
		NSArray *movingListFaces = [sourceListObjects objectsAtIndexes_panther:draggedRowsIndexSet];
		
		[_sourceList removeObjectsAtIndexes:draggedRowsIndexSet];
		[_sourceList insertObjects:movingListFaces atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [draggedRowsIndexSet count])]];
		[_sourceList saveToFile];
		
		return YES;
		
	} else if ([pBoardType isEqualToString:T2IdentifiedListFacesPasteboardType]) { // ListFaces
		T2ListFace *selectedListFace = [[draggingPasteboard identifiedListFaces] lastObject];
		
		if (!selectedListFace) return NO;
		[_sourceList insertObject:selectedListFace atIndex:row];
		[_sourceList saveToFile];
		
		return YES;
		
	} else if ([pBoardType isEqualToString:T2IdentifiedThreadFacesPasteboardType]) { // ThreadFaces
		NSArray *movingThreadFaces = [draggingPasteboard identifiedThreadFaces];
		
		if (operation == NSTableViewDropAbove) {
			NSBundle *bundle = [NSBundle bundleForClass:[self class]];
			NSString *title = NSLocalizedStringFromTableInBundle(@"Untitled Bookmark", @"Thousand2chLocalizable", bundle, nil);
			T2BookmarkListFace *threadListFace = [T2BookmarkListFace bookmarkListFace];
			[threadListFace setTitle:title];
			T2BookmarkList *threadList = (T2BookmarkList *)[threadListFace list];
			[threadList setObjects:movingThreadFaces];
			
			[_sourceList insertObject:threadListFace atIndex:row];
			[_sourceList saveToFile];
			
			return YES;
			
		} else if (operation == NSTableViewDropOn) {
			T2ListFace *threadListFace = [sourceListObjects objectAtIndex:row];
			T2List *threadList = [threadListFace list];
			if ([threadList isKindOfClass:[T2BookmarkListFace class]]) {
				[threadList addObjects:movingThreadFaces];
				[_sourceList saveToFile];
				return YES;
			}
		}
	} else if ([pBoardType isEqualToString:NSFilenamesPboardType] && __localFileImporter) { // Files
		NSMutableArray *listFacesForFolders = [NSMutableArray array];
		NSArray *fileNames = [draggingPasteboard propertyListForType:NSFilenamesPboardType];
		NSEnumerator *fileNamesEnumerator = [fileNames objectEnumerator];
		NSString *fileName;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		BOOL isFolder;
		while (fileName = [fileNamesEnumerator nextObject]) {
			if ([fileManager fileExistsAtPath:fileName isDirectory:&isFolder]) {
				if (isFolder) {
					T2ListFace *threadListFace = [T2ListFace listFaceWithInternalPath:[[__localFileImporter importableRootPath] stringByAppendingString:fileName]
																				title:[fileName lastPathComponent]
																				image:nil];
					[threadListFace setImageByListImporter];
					if (threadListFace) {
						[listFacesForFolders addObject:threadListFace];
					}
				}
			}
		}
		
		if (operation == NSTableViewDropAbove) {
			[_sourceList insertObjects:listFacesForFolders atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [listFacesForFolders count])]];
			[_sourceList saveToFile];
			return YES;
		}
	}
	return NO;
}


#pragma mark -
#pragma mark NSTableView delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if (_delegate) {
		NSArray *selectedListFaces = [_sourcesController selectedObjects];
		if ([_delegate respondsToSelector:@selector(sourceListTableView:didSelectListFaces:)]) {
			[_delegate sourceListTableView:_sourceListTableView didSelectListFaces:selectedListFaces];
		}
	}
}

-(IBAction)sourceListTableViewClicked:(id)sender {
	if (_delegate) {
		NSArray *selectedListFaces = [_sourcesController selectedObjects];
		if ([_delegate respondsToSelector:@selector(sourceListTableView:didClickListFaces:)]) {
			[_delegate sourceListTableView:_sourceListTableView didClickListFaces:selectedListFaces];
		}
	}
}
-(IBAction)sourceListTableViewDoubleClicked:(id)sender {
	if (_delegate) {
		NSArray *selectedListFaces = [_sourcesController selectedObjects];
		if ([_delegate respondsToSelector:@selector(sourceListTableView:didDoubleClickListFaces:)]) {
			[_delegate sourceListTableView:_sourceListTableView didDoubleClickListFaces:selectedListFaces];
		}
	}
}
-(IBAction)sourceListTableViewDeleteKeyDown:(id)sender {
	NSArray *selectedListFaces = [[[_sourcesController selectedObjects] copy] autorelease];
	NSIndexSet *indexes = [_sourcesController selectionIndexes];
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
		if ([_delegate respondsToSelector:@selector(sourceListTableView:didDeleteListFaces:)]) {
			[_delegate sourceListTableView:_sourceListTableView didDeleteListFaces:selectedListFaces];
		}
	}
}
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
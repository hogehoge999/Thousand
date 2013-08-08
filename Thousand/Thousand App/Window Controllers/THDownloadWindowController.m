//
//  THDownloadWindowController.m
//  Thousand
//
//  Created by R. Natori on  07/08/31.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "THDownloadWindowController.h"
#import "T2TableView.h"
#import "THWebDownloader.h"

static THDownloadWindowController *__sharedDownloadWindowController = nil;

static BOOL __classDownloadInThreadFolder = YES;
static NSString *__classDownloadDestinationFolderPath = nil;

@implementation THDownloadWindowController

+(void)initialize {
	if (__classDownloadDestinationFolderPath) return;
	
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
		if (MacVersion >= 0x1050) {
			__classDownloadDestinationFolderPath = [[NSString userDownloadsFolderPath] retain];
			return;
		}
	}
	__classDownloadDestinationFolderPath = [[NSString userDesktopFolderPath] retain];
}

+(id)downloadWindowController {
	if (__sharedDownloadWindowController) return __sharedDownloadWindowController;
	return [[[self alloc] initDownloadWindowController] autorelease];
}
-(id)initDownloadWindowController {
	if (__sharedDownloadWindowController) return __sharedDownloadWindowController;
	self = [self initWithWindowNibName:@"THDownloadWindow"];
	[self setWindowFrameAutosaveName:@"download"];
	__sharedDownloadWindowController = [self retain];
	return self;
}
-(void)awakeFromNib {
	[_tableView setDoubleAction:@selector(openFileOfSelectedDonwload:)];
}
-(void)dealloc {
	__sharedDownloadWindowController = nil;
	[_downloaders release];
	[super dealloc];
}

//Accessors
+(void)setClassDownloadInThreadFolder:(BOOL)aBool { __classDownloadInThreadFolder = aBool; }
+(BOOL)classDownloadInThreadFolder { return __classDownloadInThreadFolder; }
+(void)setClassDownloadDestinationFolderPath:(NSString *)path { 
	if (!path || [path length]==0 || ![path isExistentPath]) return;
	setObjectWithRetain(__classDownloadDestinationFolderPath, path);
}
+(NSString *)classDownloadDestinationFolderPath { return __classDownloadDestinationFolderPath; }

-(void)setDownloaders:(NSArray *)downloaders { setObjectWithRetain(_downloaders, downloaders); }
-(NSArray *)downloaders { return _downloaders; }

	//Methods
-(void)addDownloadOfURLString:(NSString *)urlString inThread:(T2Thread *)thread {
	NSString *destinationFolderPath = [[self class] classDownloadDestinationFolderPath];
	
	if (__classDownloadInThreadFolder && thread) {
		destinationFolderPath = [__classDownloadDestinationFolderPath stringByAppendingPathComponent:[[thread title] stringByReplacingReservedCharacters]];
	}
	
	THWebDownloader *downloader = [THWebDownloader webDownLoaderWithURLString:urlString destinationFolderPath:destinationFolderPath];
	if (!downloader) return;
	if (_downloaders) {
		[self setDownloaders:[_downloaders arrayByAddingObject:downloader]];
	} else {
		[self setDownloaders:[NSArray arrayWithObject:downloader]];
	}
}

#pragma mark -
#pragma mark Delegate Methods
- (BOOL)tableView:(NSTableView *)aTableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
	NSString *pBoardType;
	NSMutableIndexSet *selectedRowIndexes = [NSMutableIndexSet indexSet];
	NSEnumerator *rowNumberEnumerator = [rows objectEnumerator];
	NSNumber *rowNumber;
	while (rowNumber = [rowNumberEnumerator nextObject]) {
		[selectedRowIndexes addIndex:[rowNumber unsignedIntValue]];
	}
	
	NSArray *draggingDownloaders = [[_downloadersController arrangedObjects] objectsAtIndexes_panther:selectedRowIndexes];
	NSArray *pboardTypes = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
	
	//NSFilenamesPboardType
	NSMutableArray *fileNames = [NSMutableArray array];
	NSEnumerator *enumerator = [draggingDownloaders objectEnumerator];
	THWebDownloader *downloader;
	while (downloader = [enumerator nextObject]) {
		if (![downloader isLoading]) {
			NSString *fileName = [downloader destinationPath];
			if (fileName) [fileNames addObject:fileName];
		}
	}
	if ([fileNames count] > 0) {
		[pboard declareTypes:pboardTypes owner:nil];
		[pboard setPropertyList:fileNames forType:NSFilenamesPboardType];
		return YES;
	} 
	return NO;
}


#pragma mark -
#pragma mark Actions
-(IBAction)removeAllDownloaders:(id)sender {
	[self setDownloaders:nil];
}

-(IBAction)cancelLoading:(id)sender {
	[self cancelSelectedDonwload:sender];
}
-(IBAction)cancelSelectedDonwload:(id)sender {
	unsigned selectionIndex = [_downloadersController selectionIndex];
	if (selectionIndex == NSNotFound) return;
	
	THWebDownloader *selectedDownloader = [[_downloadersController arrangedObjects] objectAtIndex:selectionIndex];
	[selectedDownloader cancelDownload:sender];
}
-(IBAction)openFileOfSelectedDonwload:(id)sender {
	NSString *filePath = [[_downloadersController selection] valueForKey:@"destinationPath"];
	if (!filePath) return;
	NSWorkspace *workSpace = [NSWorkspace sharedWorkspace];
	[workSpace openFile:filePath];
}
-(IBAction)revealFileOfSelectedDonwload:(id)sender {
	NSString *filePath = [[_downloadersController selection] valueForKey:@"destinationPath"];
	if (!filePath) return;
	NSWorkspace *workSpace = [NSWorkspace sharedWorkspace];
	[workSpace selectFile:filePath inFileViewerRootedAtPath:[filePath stringByDeletingLastPathComponent]];
}
-(IBAction)copyURLOfSelectedDownload:(id)sender {
	NSString *urlString = [[_downloadersController selection] valueForKey:@"URLString"];
	if (!urlString) return;
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects:
		NSStringPboardType,
		NSURLPboardType,
		nil];
	[pasteBoard declareTypes:types owner:nil];
	[pasteBoard setString:urlString forType:NSStringPboardType];
	[[NSURL URLWithString:urlString] writeToPasteboard:pasteBoard];
}
@end

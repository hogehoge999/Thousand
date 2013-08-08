//
//  MyDocument.m
//  MyFirst2chBrowser
//
//  Created by ?? ?? on 08/05/19.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

#pragma mark -
#pragma mark Init and Dealloc

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}

-(void)dealloc {
	[_threadList release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(NSArray *)rootListFaces {
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	return [pluginManager rootListFaces];
}

-(void)setThreadList:(T2ThreadList *)threadList {
	[threadList retain];
	[_threadList autorelease];
	_threadList = threadList;
}
-(T2ThreadList *)threadList {
	return _threadList;
}


#pragma mark -
#pragma mark NSDocument Methods
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	[_threadView setResExtractPath:@"allRes"];
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

#pragma mark -
#pragma mark NSOutlineView Delegate Methods
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	T2ListFace *listFace = [[_sourcesController selectedObjects] lastObject];
	if (listFace) {
		T2List *list = [listFace list];
		if ([list isKindOfClass:[T2ThreadList class]]) {
			[self setThreadList:(T2ThreadList *)list];
		}
		[list load];
	}
			
}

#pragma mark -
#pragma mark NSTableView Delegate Methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	T2ThreadFace *threadFace = [[_threadFacesController selectedObjects] lastObject];
	if (threadFace) {
		T2Thread *thread = [threadFace thread];
		[_threadView setThread:thread];
		[thread load];
	}
}

#pragma mark -
#pragma mark Actions

-(IBAction)load:(id)sender {
	[self outlineViewSelectionDidChange:nil];
	[self tableViewSelectionDidChange:nil];
}
@end

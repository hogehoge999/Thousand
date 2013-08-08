//
//  MyDocument.h
//  MyFirst2chBrowser
//
//  Created by ?? ?? on 08/05/19.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface MyDocument : NSDocument
{
	T2ThreadList *_threadList;
	
	IBOutlet NSTreeController *_sourcesController ;
	IBOutlet NSOutlineView *_sourcesOutlineView;
	
	IBOutlet NSArrayController *_threadFacesController ;
	IBOutlet NSTableView *_threadFacesTableView ;
	
	//IBOutlet NSTextField *_textField;
	IBOutlet T2ThreadView *_threadView;
}


#pragma mark -
#pragma mark Accessors
-(NSArray *)rootListFaces ;

-(void)setThreadList:(T2ThreadList *)threadList ;
-(T2ThreadList *)threadList ;

#pragma mark -
#pragma mark NSOutlineView Delegate Methods
- (void)outlineViewSelectionDidChange:(NSNotification *)notification ;

#pragma mark -
#pragma mark NSTableView Delegate Methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification ;

#pragma mark -
#pragma mark Actions
-(IBAction)load:(id)sender ;
@end

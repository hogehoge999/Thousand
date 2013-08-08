//
//  THChooseNextThreadWindowController.h
//  Thousand
//
//  Created by R. Natori on 平成21/09/02.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface NSObject (THChooseNextThreadWindowControllerDelegate)
-(void)chosenNextThreadFace:(T2ThreadFace *)nextThreadFace forOldThreadFace:(T2ThreadFace *)oldThreadFace ;
@end

@interface THChooseNextThreadWindowController : NSWindowController {
	NSWindow		*_docWindow;
	id 				_delegate;
	SEL				_didEndSelector;
	
	T2ThreadFace	*_oldThreadFace;
	T2ThreadFace	*_newThreadFace;
	T2List		 	*_threadList;
	NSArray			*_threadFaces;
	NSArray			*_newThreadFaces;
	
	IBOutlet NSArrayController		*_arrayController;
	IBOutlet NSTableView			*_tableView;
	IBOutlet NSProgressIndicator	*_progressIndicator;
	IBOutlet NSTextField			*_messageTextField;
	IBOutlet NSTextField			*_statusTextField;
	IBOutlet NSButton				*_inheritLabelCheckBox;
	IBOutlet NSButton				*_inheritBookmarkCheckBox;
	IBOutlet NSButton				*_replaceBookmarkCheckBox;
}

#pragma mark -
#pragma mark Accessors
-(void)setOldThreadFace:(T2ThreadFace *)oldThreadFace ;
-(T2ThreadFace *)oldThreadFace ;
-(void)setNewThreadFace:(T2ThreadFace *)newThreadFace ;
-(T2ThreadFace *)newThreadFace ;
-(void)setNewThreadFaces:(NSArray *)newThreadFaces ;
-(NSArray *)newThreadFaces ;

#pragma mark -
#pragma mark Sheet
+(id)beginSheetModalForWindow:(NSWindow *)docWindow withOldThreadFace:(T2ThreadFace *)oldThreadFace
				newThreadFace:(T2ThreadFace *)newThreadFace delegate:(id)delegate didEndSelector:(SEL)didEndSelector;
-(id)initSheetModalForWindow:(NSWindow *)docWindow withOldThreadFace:(T2ThreadFace *)oldThreadFace
			   newThreadFace:(T2ThreadFace *)newThreadFace delegate:(id)delegate didEndSelector:(SEL)didEndSelector;
-(void)beginSheet ;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo ;

- (void)threadListDidLoad:(NSNotification *)notification ;

#pragma mark -
#pragma mark Actions
- (IBAction)inheritBookmarkAction:(id)sender ;
- (IBAction)cancelAction:(id)sender ;
- (IBAction)okAction:(id)sender ;
@end

/* THAddBookmarkWindowController */

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THAddBookmarkWindowController : NSWindowController
{
	NSWindow				*_docWindow;
	NSArray					*_threadFaces;
	T2BookmarkList	*_selectedBookmarkList;
	
	IBOutlet NSPopUpButton	*_popUpButton;
}

#pragma mark -
#pragma mark Accessors
-(NSArray *)allBookmarkLists ;
-(void)setSelectedBookmarkList:(T2BookmarkList *)bookmarkList ;
-(T2BookmarkList *)selectedBookmarkList ;

#pragma mark -
#pragma mark Sheet
+(id)beginSheetModalForWindow:(NSWindow *)docWindow threadFaces:(NSArray *)threadFaces;
-(id)initSheetModalForWindow:(NSWindow *)docWindow threadFaces:(NSArray *)threadFaces;
-(void)beginSheet ;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo ;

#pragma mark -
#pragma mark Actions
- (IBAction)newBookmark:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;
@end

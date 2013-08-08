//
//  THThreadController.h
//  Thousand
//
//  Created by R. Natori on 05/08/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Thousand2ch/Thousand2ch.h>

#define THBookmarkLocalize(string) (NSLocalizedString(string, @"Bookmark"))

typedef enum {
	THPreviewNone = 0,
	THPreviewInPopUp,
	THPreviewInline,
	THPreviewMove,
	THPreviewInNewTab,
	THPreviewDownload,
	THPreviewWebBrowser
} THPreviewActionType;

@class THDocument, THBookmarkController;

@interface THThreadController : NSObjectController {
	THDocument	*_document;
	//T2Thread 	*_thread;
	
	T2ThreadView								*_threadView;
	id <T2ThreadHTMLExporting_v100> 			*_viewerPlug;
	id <T2ThreadPartialHTMLExporting_v100>	*_partialViewerPlug;
	
	NSString	*_webDataURLString;
	NSString	*_pressedURLString;
	NSString	*_pressedResExtractPath;
}
+(void)setClassPopUpResAnchorElementActionType:(THPreviewActionType)actionType ;
+(THPreviewActionType)classPopUpResAnchorElementActionType ;
+(void)setClassPopUpOtherAnchorElementActionType:(THPreviewActionType)actionType ;
+(THPreviewActionType)classPopUpOtherAnchorElementActionType ;
+(void)setClassClickResAnchorElementActionType:(THPreviewActionType)actionType ;
+(THPreviewActionType)classResClickAnchorElementActionType ;
+(void)setClassClickOtherAnchorElementActionType:(THPreviewActionType)actionType ;
+(THPreviewActionType)classOtherClickAnchorElementActionType ;

+(void)setClassDefaultResExtractPath:(NSString *)path ;
+(NSString *)classDefaultResExtractPath ;

+(id)threadControllerWithThreadView:(T2ThreadView *)threadView thread:(T2Thread *)thread document:(THDocument *)document ;
-(id)initWithThreadView:(T2ThreadView *)threadView thread:(T2Thread *)thread document:(THDocument *)document ;
// Accessors
-(void)setThread:(T2Thread *)thread ;
-(T2Thread *)thread ;

-(void)setThreadView:(T2ThreadView *)threadView ;
-(T2ThreadView *)threadView ;

-(void)setPressedResExtractPath:(NSString *)resExtractPath ;
-(NSString *)pressedResExtractPath ;

-(void)setDocument:(THDocument *)document ;
-(THDocument *)document ;

-(NSString *)filterSearchString ;

#pragma mark Methods
-(void)updateLabelButton ;
-(void)updateThreadMenu ;

THPreviewActionType previewActionTypeWithPriorityAndModifierFlags(
																   THPreviewActionType first,
																   THPreviewActionType second,
																   THPreviewActionType third,
																   THPreviewActionType fourth,
																   unsigned modifierFlags);

-(NSArray *)menusForThread ;
-(NSMenuItem *)labelMenuItem ;
-(NSArray *)restrictedStyleMenuItemsForTarget:(id)target action:(SEL)action ;


#pragma mark -
#pragma mark Menu And Toolbar item Validation
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem ;
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem ;
-(BOOL)validateUIOfAction:(SEL)action ;

-(void)searchString:(NSString *)aString ;
#pragma mark -
#pragma mark Thread Actions
-(IBAction)reloadView:(id)sender ;
-(IBAction)cancelLoading:(id)sender ;
-(IBAction)showFirst100Res:(id)sender ;
-(IBAction)showNext100Res:(id)sender ;
-(IBAction)showLast100Res:(id)sender ;
-(IBAction)showAllRes:(id)sender ;
-(IBAction)trace:(id)sender ;

-(IBAction)selectResExtractPathAction:(id)sender ;
-(IBAction)selectHTMLExporterAction:(id)sender ;

-(IBAction)showSource:(id)sender ;
-(IBAction)removeSelectedThreads:(id)sender ;
-(IBAction)removeSelectedThreadsImmediately:(id)sender ;
-(IBAction)revealLogFileInFinder:(id)sender ;
-(IBAction)addToBookmark:(id)sender ;
-(IBAction)moveToNewRes:(id)sender ;
-(IBAction)openUsingWebBrowser:(id)sender ;
-(IBAction)openUsingOreyon:(id)sender ;
-(IBAction)findNextThread:(id)sender ;
-(IBAction)openParentThreadList:(id)sender ;

-(IBAction)copyURL:(id)sender ;
-(IBAction)copyTitleAndURL:(id)sender ;

-(IBAction)postRes:(id)sender ;
- (IBAction)printTab:(id)sender ;

#pragma mark Res Actions
-(IBAction)reply:(id)sender ;
-(IBAction)extractAndreply:(id)sender ;

-(IBAction)moveToRes:(id)sender ;
-(IBAction)openResInNewTab:(id)sender ;
-(IBAction)showPreviewableRes:(id)sender ;
-(IBAction)previewInlineInRes:(id)sender ;
-(IBAction)previewInlineAll:(id)sender ;

#pragma mark Text and URL Actions
-(IBAction)searchSelectionInThread:(id)sender ;
-(IBAction)searchSelectionUsingWebBrowser:(id)sender ;
-(IBAction)setSelectionToNGWord:(id)sender ;

-(IBAction)copyLinkURL:(id)sender ;
-(IBAction)openLinkUsingWebBrowser:(id)sender ;
-(IBAction)downloadLink:(id)sender ;
-(IBAction)downloadLinkInRes:(id)sender ;
@end
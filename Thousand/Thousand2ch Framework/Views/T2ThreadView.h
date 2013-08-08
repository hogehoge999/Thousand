//
//  T2ThreadView.h
//  Thousand
//
//  Created by R. Natori on 06/10/01.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "T2WebKitAdditions.h"
#import "T2PluginProtocols.h"

@class T2Thread, T2ThreadFace, T2ThreadViewInternalDelegate, T2PopUpWindowController;


@interface T2ThreadView : WebView {
	T2Thread	*_thread;
	//NSString	*_internalBaseURLprefix;
	NSIndexSet	*_resIndexes;
	NSString	*_resExtractPath;
	NSString	*_selectedResExtractPath;
	
	//BOOL			_allowsTypeToJump;
	NSMutableString *_typeBuffer;
	NSTimer			*_typeTimer;
	
	NSTimer			*_styleTimer;
	
	id <T2ThreadHTMLExporting_v100>		_HTMLExporter;
	
	NSURL			*_baseURL;
	
	T2ThreadViewInternalDelegate *_internalDelegate ;
	IBOutlet NSObject	*_delegate;
	
	BOOL	_isPopUp;
	BOOL	_threadLoaded;
	
	NSIndexSet	*_loadedResIndexes;
	NSTimer		*_extendTimer;
	
	int	_storedResIndex;
	float		_storedScrollOffset;
}
#pragma mark -
#pragma mark Class Property
+(void)setClassPopUpWait:(float)wait ;
+(float)classPopUpWait ;
+(void)setClassResPopUpWindowWidth:(float)width ;
+(float)classResPopUpWindowWidth ;
+(void)setClassAllowsTypeToJump:(BOOL)aBool ;
+(BOOL)classAllowsTypeToJump ;
+(void)setClassTypeWait:(NSTimeInterval)wait ;
+(NSTimeInterval)classTypeWait ;
+(void)setClassSafari2Debug:(BOOL)aBool ;
+(BOOL)classSafari2Debug ;

#pragma mark -
#pragma mark Factory and Init
//-(void)initThreadView ;

#pragma mark -
#pragma mark Accessors

-(void)setThreadURLString:(NSString *)URLString ;
-(void)setThreadInternalPath:(NSString *)internalPath ;
-(void)setThreadFace:(T2ThreadFace *)threadFace ;

-(void)setThread:(T2Thread *)thread ;
-(T2Thread *)thread ;

//-(void)setInternalBaseURLprefixFromURL:(NSURL *)baseURL ; 
//-(NSString *)internalBaseURLprefix ;

-(void)setResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)resIndexes;

-(void)setResExtractPath:(NSString *)extractPath ;
-(NSString *)resExtractPath;

-(void)setSelectedResExtractPath:(NSString *)extractPath ;
-(NSString *)selectedResExtractPath;

-(void)setHTMLExporter:(id <T2ThreadHTMLExporting_v100>)HTMLExporter ;
-(id <T2ThreadHTMLExporting_v100>)HTMLExporter ;

-(void)setBaseURL:(NSURL *)anURL ;
-(NSURL *)baseURL ;

-(void)setInternalDelegate:(T2ThreadViewInternalDelegate *)delegate ;
-(T2ThreadViewInternalDelegate *)internalDelegate ;

-(void)setDelegate:(NSObject *)delegate ;
-(NSObject *)delegate ;

-(void)setIsPopup:(BOOL)aBool ;
-(BOOL)isPopup ;

#pragma mark -
#pragma mark WebView Override Methods
- (IBAction)takeStringURLFrom:(id)sender ;
- (void)setMainFrameURL:(NSString *)URLString ;
- (NSString *)mainFrameURL ;
- (IBAction)reload:(id)sender ;
- (IBAction)stopLoading:(id)sender ;
- (double)estimatedProgress ;
- (BOOL)isLoading ;

#pragma mark -
#pragma mark Internal
//-(void)thread:(T2Thread *)thread didUpdateStyleOfResIndexes:(NSIndexSet *)resIndexes ;
-(NSTimer *)extendTimer ;
#pragma mark -
#pragma mark Methods

-(void)displayThread ;
-(void)displayPreviewInsertion:(NSString *)htmlString ;
-(BOOL)displayElementByID:(NSString *)aString ;
-(void)displayResForNumber:(unsigned)resNumber ;
-(DOMHTMLElement *)resElementForNumber:(unsigned)resNumber ;
-(void)registerDisplayResForNumber:(unsigned)resNumber ;

-(void)moveToResExtractPath:(NSString *)resExtractPath ;

-(unsigned)resIndexDisplayedOnTop ;
-(void)extendTop ;
-(void)extendBottom ;
-(void)registerExtendAll ;
-(void)extendAll ;
-(void)extendLoadedResIndexs:(NSIndexSet *)resIndexes ;
-(void)storeTempScroll ;
-(void)loadTempScroll ;
-(void)saveScrollToThread ;
-(void)loadScrollFromThread ;

-(BOOL)previewAnchorElement:(DOMHTMLAnchorElement *)anchorElement withType:(T2PreviewType)type ;

-(BOOL)replaceResAnchorElement:(DOMHTMLAnchorElement *)anchorElement WithResExtractPath:(NSString *)extractPath ;
-(BOOL)replacePreviewableAnchorElement:(DOMHTMLAnchorElement *)anchorElement ;
-(void)replacePreviewableAnchorElementsInResExtractPath:(NSString *)resExtractPath ;
-(void)replacePreviewableAnchorElementsInResIndexes:(NSIndexSet *)resIndexes ;
-(void)replaceAllPreviewableAnchorElements ;

-(NSArray *)urlStringsOfAnchorElementsInResExtractPath:(NSString *)resExtractPath ;
-(NSArray *)urlStringsOfAnchorElementsInResIndexes:(NSIndexSet *)resIndexes ;

#pragma mark -
#pragma mark Actions
-(IBAction)setSelectedResStyleAction:(id)sender ;
-(IBAction)removeSelectedResStyleAction:(id)sender ;
-(IBAction)setResStyleAction:(id)sender ;
-(IBAction)removeResStyleAction:(id)sender ;
-(IBAction)removeAllResStyleAction:(id)sender ;
@end

/*
@interface T2ThreadView (T2ThreadViewInternalMethods)
-(void)setThreadLoaded:(BOOL)aBool ;
-(BOOL)threadLoaded ;
@end
 */
#pragma mark -

@interface T2ThreadViewInternalDelegate : NSObject <DOMEventListener> {
	T2ThreadView					*_threadView;
	
	T2ThreadViewInternalDelegate	*_parentInternalDelegate;
	T2ThreadViewInternalDelegate	*_childInternalDelegate;
	NSWindow						*_childWindow;
	
	//NSString	*_hoveredURLString;
	DOMHTMLAnchorElement	*_hoveredAnchorElement;
	unsigned				_modifierFlags;
	NSTimer					*_hoverTimer;
	NSTimer					*_popUpReleaseTimer;
	
	int			_popUpRetainCount;
	
	unsigned	_registeredResNumberToDisplay;
}

#pragma mark -
#pragma mark Accessors
-(void)setThreadView:(T2ThreadView *)threadView ;
-(T2ThreadView *)threadView ;
-(NSWindow *)window ;

#pragma mark -
#pragma mark Child and Parent Control
/*
-(void)becomeParentOfChildInternalDelegate:(T2ThreadViewInternalDelegate *)childInternalDelegate ;
-(T2ThreadViewInternalDelegate *)parentInternalDelegate ;
-(T2ThreadViewInternalDelegate *)childInternalDelegate ;
 */
-(void)setChildInternalDelegate:(T2ThreadViewInternalDelegate *)childInternalDelegate ;
-(T2ThreadViewInternalDelegate *)childInternalDelegate ;
-(T2ThreadViewInternalDelegate *)parentInternalDelegate ;
-(void)childWindowWillClose ;


#pragma mark -
#pragma mark PopUp Control
-(void)registerHoveredAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags ;
-(void)popUpRetain ;
-(void)popUpRelease ;
-(void)popUpReleaseWithDelay ;
-(void)popUpClose ;
-(void)popUpCloseWithDelay ;
-(void)flushHoverTimer ;
-(void)flushReleaseTimer ;
-(void)makeThreadViewToFirstResponder ;
-(void)performClickHoveredAnchorElement ;

#pragma mark Other Methods
-(void)registerDisplayResForNumber:(unsigned)resNumber ;
-(void)displayRegisteredRes ;

#pragma mark -
#pragma mark WebFrameLoadingDelegate
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame ;

#pragma mark -
#pragma mark WebPolicyDelegate
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request frame:(WebFrame *)frame
 decisionListener:(id<WebPolicyDecisionListener>)listener ;

#pragma mark -
#pragma mark WebUIDelegate
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element
	defaultMenuItems:(NSArray *)defaultMenuItems ;
	
#pragma mark -
#pragma mark DOMEvent
- (void)handleEvent:(DOMEvent *)event ;
-(BOOL)mouseoverAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags ;
-(BOOL)clickAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags ;
@end

#pragma mark -
@interface NSObject (T2ThreadViewDelegate)
-(void)threadView:(T2ThreadView *)sender didFinishLoadingThread:(T2Thread *)thread ;
-(void)threadView:(T2ThreadView *)sender didDisplayThread:(T2Thread *)thread ;

-(BOOL)threadView:(T2ThreadView *)sender shouldHandlePopUpAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags ;
-(BOOL)threadView:(T2ThreadView *)sender shouldHandleClickAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags ;

-(void)threadView:(T2ThreadView *)sender clickedListPath:(NSString *)internalPath ;
-(void)threadView:(T2ThreadView *)sender clickedThreadPath:(NSString *)internalPath ;
-(void)threadView:(T2ThreadView *)sender clickedResPath:(NSString *)extractPath ;
-(void)threadView:(T2ThreadView *)sender clickedEmbeddableURL:(NSString *)URLString ;
-(void)threadView:(T2ThreadView *)sender clickedOtherURL:(NSString *)URLString ;

-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForResPath:(NSString *)extractPath defaultMenuItems:(NSArray *)defaultMenuItems;
-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForEmbeddableURL:(NSString *)URLString defaultMenuItems:(NSArray *)defaultMenuItems;
-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForOtherURL:(NSString *)URLString defaultMenuItems:(NSArray *)defaultMenuItems;
-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForSelectedString:(NSString *)string defaultMenuItems:(NSArray *)defaultMenuItems;
-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForOtherElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems;
@end
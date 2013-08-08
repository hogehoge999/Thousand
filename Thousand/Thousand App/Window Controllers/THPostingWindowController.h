/* THPostingWindowController.h */

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@class T2PluginPrefView ,THSplitView;

static NSString *THPostingWindowToolBarIdentifier 				= @"THPostingWindowToolBarIdentifier";
static NSString *THPostingWindowToolBarPostItemIdentifier 		= @"THPostingWindowToolBarPostItemIdentifier";
static NSString *THPostingWindowToolBarReloadItemIdentifier 	= @"THPostingWindowToolBarReloadItemIdentifier";
static NSString *THPostingWindowToolBarP2ItemIdentifier 		= @"THPostingWindowToolBarP2ItemIdentifier";
static NSString *THPostingWindowToolBar2chViewerItemIdentifier 	= @"THPostingWindowToolBar2chViewerItemIdentifier";
static NSString *THPostingWindowToolBarBeItemIdentifier 		= @"THPostingWindowToolBarBeItemIdentifier";
static NSString *THPostingWindowToolBarSageItemIdentifier 		= @"THPostingWindowToolBarSageItemIdentifier";
static NSString *THPostingWindowToolBarAAFontItemIdentifier 	= @"THPostingWindowToolBarAAFontItemIdentifier";
static NSString *THPostingWindowToolBarBoardTitleItemIdentifier = @"THPostingWindowToolBarBoardTitleItemIdentifier";
static NSString *THPostingWindowToolBarNameItemIdentifier 		= @"THPostingWindowToolBarNameItemIdentifier";
static NSString *THPostingWindowToolBarMailItemIdentifier 		= @"THPostingWindowToolBarMailItemIdentifier";

@interface THPostingWindowController : NSWindowController
{
	T2Thread *_thread;
	T2ThreadList *_threadList;
	NSString *_content;
	
	//T2WebForm *_webForm;
	NSURLRequest *_additionalRequest;
	T2WebConnector *_webConnector;
	
	T2Posting *_posting;
	
	//NSObject <T2ResPosting_v100> *_resPostingPlug; 
	//NSObject <T2ThreadPosting_v100> *_threadPostingPlug; 
	
	NSObject <T2ResPostingUsingWebView_v100> *_webResPostingPlug; 
	NSObject <T2ThreadPostingUsingWebView_v100> *_webThreadPostingPlug; 
	
	BOOL _postingWindowSizeLoaded;
	BOOL _postingSucceeded;
	BOOL _firstRequest;
	
	BOOL _is2ch;
	BOOL _isP2Active;
	BOOL _isViewerActive;
	BOOL _isBeActive;
	BOOL _isSage;
	NSObjectController *_objectController;
		
	IBOutlet NSProgressIndicator *_progressIndicator;
    IBOutlet WebView *_webView;
	IBOutlet NSTextView *_messageTextView;
	IBOutlet NSButton *_confirmButton;
	IBOutlet NSButton *_backButton;
	
	IBOutlet NSTextField *_boardLabelTextField;
	IBOutlet NSTextField *_boardTextField;
	
	IBOutlet NSTextField *_titleLabelTextField;
	IBOutlet NSTextField *_titleTextField;
	IBOutlet NSTextField *_editableTitleTextField;
	
	IBOutlet NSComboBox *_nameTextField;
	IBOutlet NSComboBox *_mailTextField;
	
	IBOutlet THSplitView *_splitView;
	IBOutlet NSTextView *_contentTextView;
	IBOutlet T2PluginPrefView *_pluginPrefView;
	
	IBOutlet NSTabView *_tabView;
	IBOutlet NSTabViewItem *_draftTab;
	IBOutlet NSTabViewItem *_postingTab;
	IBOutlet NSTabViewItem *_responseTab;
	
	NSToolbarItem *_p2Item;
	NSToolbarItem *_viewerItem;
	NSToolbarItem *_beItem;
	NSToolbarItem *_sageItem;
	
	IBOutlet NSButton *_p2Button;
	IBOutlet NSButton *_2chViewerButton;
	IBOutlet NSButton *_BeButton;
	IBOutlet NSButton *_sageButton;
}

#pragma mark -
#pragma mark Class
+(void)setClassUsedNames:(NSArray *)array ;
+(NSArray *)classUsedNames ;
+(void)setClassUsedMails:(NSArray *)array ;
+(NSArray *)classUsedMails ;


#pragma mark -
#pragma mark init
+(id)availableResPostingWindowForThread:(T2Thread *)thread ;
+(id)resPostingWindowForThread:(T2Thread *)thread content:(NSString *)content ;
+(id)threadPostingWindowForThreadList:(T2ThreadList *)threadList ;
-(id)initResPostingWindowForThread:(T2Thread *)thread content:(NSString *)content ;
-(id)initThreadPostingWindowForThreadList:(T2ThreadList *)threadList ;

#pragma mark -
#pragma mark Accessors
-(NSArray *)usedNames ;
-(NSArray *)usedMails ;

-(id)plugin ;

-(void)setIsP2Active:(BOOL)aBool ;
-(BOOL)isP2Active ;
-(void)setIsViewerActive:(BOOL)aBool ;
-(BOOL)isViewerActive ;
-(void)setIsBeActive:(BOOL)aBool ;
-(BOOL)isBeActive ;
/*
-(void)setWebForm:(T2WebForm *)webForm ;
-(T2WebForm *)webForm ;
 */

#pragma mark -
#pragma mark Sheet
/*
-(void)beginSheet ;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo ;
*/

#pragma mark -
#pragma mark Methods
-(void)appendContent:(NSString *)string ;
-(void)setConfirmButtonTitle:(NSString *)string ;

#pragma mark -
#pragma mark Actions
- (IBAction)post:(id)sender;
- (IBAction)close:(id)sender;
- (IBAction)backToDraft:(id)sender;
- (IBAction)confirm:(id)sender;
- (IBAction)p2Checked:(id)sender ;
- (IBAction)viewerChecked:(id)sender ;
- (IBAction)beChecked:(id)sender ;
- (IBAction)sageChecked:(id)sender ;

-(IBAction)postRes:(id)sender ;
-(IBAction)reload:(id)sender ;
@end

//
//  TH2chViewerLoginWindowController.h
//  Thousand
//
//  Created by R. Natori on 08/12/08.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface NSObject (TH2chViewerLoginWindowControllerDelegate)
-(void)loginSheetDidEndWithAccountName:(NSString *)accountName sessionID:(NSString *)sessionID sessionUA:(NSString *)sessionUA saveInKeychain:(BOOL)saveInKeychain;
-(void)p2loginSheetDidEndWithAccountName:(NSString *)accountName succeed:(BOOL)succeed alreadyLoggedIn:(BOOL)alreadyLoggedIn saveInKeychain:(BOOL)saveInKeychain;
-(void)beloginSheetDidEndWithAccountName:(NSString *)accountName succeed:(BOOL)succeed alreadyLoggedIn:(BOOL)alreadyLoggedIn saveInKeychain:(BOOL)saveInKeychain;
@end

typedef enum {
	T2LoginType2chViewer = 0,
	T2LoginTypeP2,
	T2LoginTypeBe
} T2LoginType;

@interface TH2chViewerLoginWindowController : NSWindowController {
	NSWindow *_docWindow;
	NSObject *_delegate;
	
	T2LoginType 	_loginType;
	
	BOOL	_succeed;
	BOOL	_alreadyLoggedIn;
	T2WebForm *_p2WebForm;
	
	NSString *_accountName;
	NSString *_password;
	NSString *_viewerSUA;
	NSString *_viewerSID;
	BOOL _saveInKeychain;
	BOOL _autoLogin;
	
	T2WebConnector *_webConnector;
	
	IBOutlet NSTextField *_titleField;
	IBOutlet NSTextField *_accountNameField;
	IBOutlet NSSecureTextField *_passwordField;
	IBOutlet NSButton *_saveInKeychainButton;
	IBOutlet NSTextField *_statusField;
	IBOutlet NSTextField *_sslField;
	IBOutlet NSProgressIndicator *_progressIndicator;
	IBOutlet NSTabView *_tabView;
}
+(id)beginLoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			 defaultPassword:(NSString *)defaultPassword
	   defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
				   autoLogin:(BOOL)autoLogin
					delegate:(NSObject *)delegate;

-(id)initLoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			defaultPassword:(NSString *)defaultPassword
	  defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
				  autoLogin:(BOOL)autoLogin
				   delegate:(NSObject *)delegate;

+(id)beginP2LoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			 defaultPassword:(NSString *)defaultPassword
		 defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
					 autoLogin:(BOOL)autoLogin
					  delegate:(NSObject *)delegate;

-(id)initP2LoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			defaultPassword:(NSString *)defaultPassword
	  defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
					autoLogin:(BOOL)autoLogin
					 delegate:(NSObject *)delegate;

+(id)beginBeLoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			   defaultPassword:(NSString *)defaultPassword
		 defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
					 autoLogin:(BOOL)autoLogin
					  delegate:(NSObject *)delegate;

-(id)initBeLoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			  defaultPassword:(NSString *)defaultPassword
		defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
					autoLogin:(BOOL)autoLogin
					 delegate:(NSObject *)delegate;

-(void)beginSheet ;
-(void)p2challenge ;
-(void)bechallenge ;
-(IBAction)login:(id)sender ;
-(IBAction)cancel:(id)sender ;
@end

//
//  THDownloadWindowController.h
//  Thousand
//
//  Created by R. Natori on  07/08/31.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>
@class T2TableView;

@interface THDownloadWindowController : NSWindowController {
	NSArray *_downloaders;
	
	IBOutlet NSArrayController *_downloadersController;
	IBOutlet T2TableView *_tableView;
}

+(id)downloadWindowController;
-(id)initDownloadWindowController;

//Accessors
+(void)setClassDownloadInThreadFolder:(BOOL)aBool ;
+(BOOL)classDownloadInThreadFolder ;
+(void)setClassDownloadDestinationFolderPath:(NSString *)path ;
+(NSString *)classDownloadDestinationFolderPath ;

-(void)setDownloaders:(NSArray *)downloaders ;
-(NSArray *)downloaders ;

//Methods
-(void)addDownloadOfURLString:(NSString *)urlString inThread:(T2Thread *)thread ;

//Actions
-(IBAction)removeAllDownloaders:(id)sender ;

-(IBAction)cancelLoading:(id)sender ;
-(IBAction)cancelSelectedDonwload:(id)sender ;
-(IBAction)openFileOfSelectedDonwload:(id)sender ;
-(IBAction)revealFileOfSelectedDonwload:(id)sender ;
-(IBAction)copyURLOfSelectedDownload:(id)sender ;

@end

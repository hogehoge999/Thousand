//
//  THWebDownloader.h
//  Thousand
//
//  Created by R. Natori on  07/08/28.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THWebDownloader : NSObject {
	NSString	*_urlString;
	NSString	*_destinationFolderPath;
	NSString	*_destinationPath;
	NSString	*_message;
	
	long long	_expectedContentLength;
	long long	_receivedContentLength;
	float		_progress;
	BOOL		_isLoading;
	
	NSURLDownload	*_download;
}


+(id)webDownLoaderWithURLString:(NSString *)urlString destinationFolderPath:(NSString *)path ;
-(id)initWithURLString:(NSString *)urlString destinationFolderPath:(NSString *)path ;

	// Accessors
+(void)setClassDownloadWhenFilesExist:(BOOL)aBool ;
+(BOOL)classDownloadWhenFilesExist ;

-(void)setURLString:(NSString *)urlString ;
-(NSString *)URLString ;

-(void)setDestinationFolderPath:(NSString *)path ;
-(NSString *)destinationFolderPath ;

-(void)setDestinationPath:(NSString *)path ;
-(NSString *)destinationPath ;
-(NSString *)fileName ;

-(void)setMessage:(NSString *)message ;
-(NSString *)message ;

-(void)setProgress:(float)progress ;
-(float)progress ;
-(NSString *)progressString ;
NSString *THStringWithBytes(long long bytes) ;

-(void)setIsLoading:(BOOL)aBool ;
-(BOOL)isLoading ;

	// Methods
-(void)finishDownload ;
-(void)cancelDownload ;
-(IBAction)cancelDownload:(id)sender ;
-(IBAction)revealInFinder:(id)sender ;
-(IBAction)openFile:(id)sender ;
@end

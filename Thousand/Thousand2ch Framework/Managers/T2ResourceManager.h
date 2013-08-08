//
//  T2ResourceManager.h
//  Thousand
//
//  Created by R. Natori on 06/06/01.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface T2ResourceManager : NSObject {
	NSMutableArray *_resourceFolderPaths ;
	
	NSArray *_cssPaths;
	NSString *_cssPathsLinkString;
	NSMutableArray *_cssStyles;
	NSMutableDictionary *_cssStyleNames;
	
	NSArray *_skinNames;
	NSString *_skinFilePath;
	
	NSArray *_iconSetNames;
	NSArray *_icons;
}
#pragma mark -
#pragma mark Factory and Init
+(T2ResourceManager *)sharedManager ;

-(id)init ;
-(void)dealloc ;

#pragma mark -
#pragma mark add Resource Folder
-(void)addResourceFolderPaths:(NSString *)path ;
-(NSArray *)resourceFolderPaths ;

#pragma mark -
#pragma mark get Paths
-(NSArray *)pathsForSubFolderName:(NSString *)subFolderName ;
-(NSArray *)filesInSubFolderName:(NSString *)subFolderName ;
-(NSArray *)filesOfType:(NSString *)type inSubFolderName:(NSString *)subFolderName ;
-(NSDictionary *)fileDicionaryOfType:(NSString *)type inSubFolderName:(NSString *)subFolderName ;

#pragma mark -
#pragma mark CSS
-(void)loadCSS ;
-(NSArray *)CSSPaths ;
-(NSString *)CSSPathsLinkString ;
-(void)loadStylesFromCSS:(NSString *)path ;
-(NSString *)nameOfStyle:(NSString *)style ;
-(NSArray *)styleMenuItemsForTarget:(id)target action:(SEL)action ;

#pragma mark -
#pragma mark SKin
-(void)loadSkinNamed:(NSString *)aString ;
-(NSArray *)skinNames ;
-(NSString *)skinFilePath ;
-(NSString *)skinFileContent ;

#pragma mark -
#pragma mark Icon Set
-(void)loadIconSetNamed:(NSString *)aString ;
-(NSArray *)iconSetNames ;

@end

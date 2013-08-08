//
//  T2SetupManager.h
//  Thousand
//
//  Created by R. Natori on 06/10/16.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface T2SetupManager : NSObject {
	NSString *_applicationName;
	NSString *_logFolderName;
	NSString *_logFolderPath;
	NSString *_pluginFolderName;
	NSString *_pluginPrefFolderName;
	
	NSString *_threadListExtension;
	NSString *_threadExtension;
	
	NSString *_iconSetName;
	
	NSArray *_defaultPluginClasses;
	NSArray *_forbiddenPluginBundleIdentifiers;
	
	NSString *_threadStateNewImageName;
	NSString *_threadStateUpdatedImageName;
	NSString *_threadStateNoUpdatedImageName;
	NSString *_threadStateFallenImageName;
	NSString *_threadStateFallenNoLogImageName;
	
	NSArray *_listAnimationImageNames;
	
	NSString *_bookmarkListImageName;
	
	NSString *_labelPopUpBaseImageName;
	NSString *_labelPopUpMaskImageName;
}
#pragma mark -
#pragma mark Factory and Init
+(id)sharedManager ;

#pragma mark -
#pragma mark Accessors
-(void)setApplicationName:(NSString *)aString ;
-(NSString *)applicationName ;
-(void)setLogFolderName:(NSString *)aString ;
-(NSString *)logFolderName ;
-(void)setLogFolderPath:(NSString *)path ;
-(NSString *)logFolderPath ;
-(void)setPluginFolderName:(NSString *)aString ;
-(NSString *)pluginFolderName ;
-(void)setPluginPrefFolderName:(NSString *)aString ;
-(NSString *)pluginPrefFolderName ;

-(void)setThreadListExtension:(NSString *)aString ;
-(NSString *)threadListExtension ;
-(void)setThreadExtension:(NSString *)aString ;
-(NSString *)threadExtension ;

-(void)setIconSetName:(NSString *)aString ;
-(NSString *)iconSetName ;

-(void)setDefaultPluginClasses:(NSArray *)classes ;
-(NSArray *)defaultPluginClasses ;
-(void)setForbiddenPluginBundleIdentifiers:(NSArray *)bundleIdentifiers ;
-(NSArray *)forbiddenPluginBundleIdentifiers ;

-(void)setThreadStateNewImageName:(NSString *)aString ;
-(NSString *)threadStateNewImageName ;
-(void)setThreadStateUpdatedImageName:(NSString *)aString ;
-(NSString *)threadStateUpdatedImageName ;
-(void)setThreadStateNoUpdatedImageName:(NSString *)aString ;
-(NSString *)threadStateNoUpdatedImageName ;
-(void)setThreadStateFallenImageName:(NSString *)aString ;
-(NSString *)threadStateFallenImageName ;
-(void)setThreadStateFallenNoLogImageName:(NSString *)aString ;
-(NSString *)threadStateFallenNoLogImageName ;

-(void)setListAnimationImageNames:(NSArray *)strings ;
-(NSArray *)listAnimationImageNames ;

-(void)setBookmarkListImageName:(NSString *)aString ;
-(NSString *)bookmarkListImageName ;

-(void)setLabelPopUpBaseImageName:(NSString *)aString ;
-(NSString *)labelPopUpBaseImageName ;
-(void)setLabelPopUpMaskImageName:(NSString *)aString ;
-(NSString *)labelPopUpMaskImageName ;

#pragma mark -
#pragma mark Setup
-(void)setup ;
@end

//
//  THFind2ch.h
//  THFind2ch
//
//  Created by R. Natori on  07/02/20.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THFind2ch : NSObject <T2SearchListImporting_v100, T2DictionaryConverting> {
	NSBundle *_selfBundle;
	NSImage *_rootImage;
	NSString *_requestURLFormat;
	int _searchMax;
	
	NSString *_searchString;
	NSString *_previousSearchString;
}

-(void)setSearchMax:(int)searchMax ;
-(int)searchMax ;
-(void)setPreviousSearchString:(NSString *)searchString ;
-(NSString *)previousSearchString ;

#pragma mark -
#pragma mark T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;

-(NSArray *)preferenceItems ;

#pragma mark -
#pragma mark T2ListImporting_v100
-(NSString *)importableRootPath ;
-(T2List *)listForListFace:(T2ListFace *)listFace ;

	// interface NSObject (T2ListImporting_v100)
-(NSURLRequest *)URLRequestForList:(T2List *)list ;
-(T2LoadingResult)buildList:(T2List *)list withWebData:(T2WebData *)webData ;
-(NSArray *)rootListFaces ;
-(NSImage *)imageForListFace:(T2ListFace *)listFace ;

#pragma mark -
#pragma mark T2SearchListImporting_v100
-(void)setSearchString:(NSString *)searchString ;
-(NSString *)searchString ;
-(T2ListFace *)persistentListFaceForSearchString:(NSString *)searchString ;
-(BOOL)receivesWholeSearchString ;
@end
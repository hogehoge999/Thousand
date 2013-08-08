//
//  THHistoryImporter.h
//  Thousand
//
//  Created by R. Natori on 06/02/18.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THHistoryImporter : NSObject <T2PluginInterface_v100, T2DictionaryConverting, T2ListImporting_v100> {
	NSBundle *_selfBundle;
	
	unsigned _threadHistoryMax;
	unsigned _resPostedThreadHistoryMax;
	unsigned _threadListHistoryMax;
	
	T2ThreadHistory *_threadHistory;
	T2ThreadHistory *_resPostedThreadHistory;
	T2ListHistory	*_threadListHistory;
	
	NSArray *_listFaces;
}

#pragma mark -
#pragma mark Accessors
-(void)setThreadHistoryMax:(int)count ;
-(int)threadHistoryMax ;
-(void)setResPostedThreadHistoryMax:(int)count ;
-(int)resPostedThreadHistoryMax ;
-(void)setThreadListHistoryMax:(int)count ;
-(int)threadListHistoryMax ;

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;

-(NSArray *)preferenceItems ;

#pragma mark -
#pragma mark protocol T2DictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use ;

#pragma mark -
#pragma mark protocol T2ListImporting_v100
-(NSString *)importableRootPath ;
-(T2List *)listForListFace:(T2ListFace *)listFace ;
-(NSArray *)rootListFaces ;

#pragma mark -
#pragma mark Actions
-(IBAction)eraseThreadHistory:(id)sender ;
-(IBAction)eraseResPostedThreadHistory:(id)sender ;
-(IBAction)eraseThreadListHistory:(id)sender ;
@end

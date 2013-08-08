//
//  THLocalFileImporter.h
//  THLocalFileImporter
//
//  Created by R. Natori on 05/10/08.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@class TH2chImporterPlug;

@interface THLocalFileImporter : NSObject <T2PluginInterface_v100, T2ListImporting_v100, T2ThreadImporting_v100> {
	NSBundle *_selfBundle;
	TH2chImporterPlug *_2chImporterPlug;
}
#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;
-(NSArray *)uniqueNamesOfdependingPlugins ;

#pragma mark -
#pragma mark protocol T2ListImporting_v100
-(NSString *)importableRootPath ;
-(T2List *)listForListFace:(T2ListFace *)listFace ;
-(NSImage *)imageForListFace:(T2ListFace *)listFace ;

//internal
-(T2ThreadFace *)threadItemWithDatFilePath:(NSString *)pathString ;
-(BOOL)readableFileIsInFolder:(NSString *)folderPath ;

// delayed loading
-(void)loadAllInfoForThreadList:(T2ThreadList *)list ;


#pragma mark -
#pragma mark protocol T2ThreadImporting_v100
-(NSString *)importableRootPath ;
-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace ;

-(NSArray *)importableTypes ;
-(NSString *)threadLogFilePathForInternalPath:(NSString *)internalPath ;

@end

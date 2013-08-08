//
//  THSearchListProxyImporter.h
//  Thousand
//
//  Created by R. Natori on 08/10/23.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THSearchListProxyImporter : NSObject <T2PluginInterface_v100, T2ListImporting_v100> {
	NSBundle *_selfBundle;

}
#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;

#pragma mark -
#pragma mark protocol T2ListImporting_v100
-(NSString *)importableRootPath ;
-(T2List *)listForListFace:(T2ListFace *)listFace ;
-(NSArray *)rootListFaces ;
@end

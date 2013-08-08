//
//  THSelfClashLogImporter.h
//  Thousand
//
//  Created by R. Natori on 06/11/18.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "THStandardPlugHeader.h"

@interface THSelfClashLogImporter : NSObject <T2ThreadImporting_v100> {

}

#pragma mark T2PluginInterface
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;
-(NSArray *)uniqueNamesOfdependingPlugins ;

#pragma mark T2ThreadImporting
-(NSString *)importableRootPath ;
-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace ;
@end

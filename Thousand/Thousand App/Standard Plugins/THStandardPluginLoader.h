//
//  THStandardPluginLoader.h
//  Thousand
//
//  Created by R. Natori on 08/05/18.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THStandardPluginLoader : NSObject <T2PluginInterface_v100> {

}
#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;
@end

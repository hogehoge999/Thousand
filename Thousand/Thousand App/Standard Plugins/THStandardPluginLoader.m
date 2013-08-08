//
//  THStandardPluginLoader.m
//  Thousand
//
//  Created by R. Natori on 08/05/18.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "THStandardPluginLoader.h"
#import "TH2chImporterPlug.h"
#import "THStandardThreadScorer.h"
#import "THStandardViewPlug.h"
#import "THLocalFileImporter.h"
#import "THHistoryImporter.h"
#import "THStandardThreadProcessor.h"
#import "THImagePreviewer.h"

@implementation THStandardPluginLoader

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	NSMutableArray *pluginInstances = [NSMutableArray array];
	
	[pluginInstances addObjectsFromArray:[TH2chImporterPlug pluginInstances]];
	[pluginInstances addObjectsFromArray:[THStandardThreadScorer pluginInstances]];
	[pluginInstances addObjectsFromArray:[THStandardViewPlug pluginInstances]];
	[pluginInstances addObjectsFromArray:[THLocalFileImporter pluginInstances]];
	[pluginInstances addObjectsFromArray:[THHistoryImporter pluginInstances]];
	[pluginInstances addObjectsFromArray:[THStandardThreadProcessor pluginInstances]];
	[pluginInstances addObjectsFromArray:[THImagePreviewer pluginInstances]];
	
	return pluginInstances;
}
-(NSString *)uniqueName { return nil; }
-(NSString *)localizedName { return nil; }
-(NSString *)localizedPluginInfo { return nil; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderFirst; }
@end

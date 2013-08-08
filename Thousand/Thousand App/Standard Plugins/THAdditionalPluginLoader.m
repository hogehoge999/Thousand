//
//  THAdditionalPluginLoader.m
//  Thousand
//
//  Created by R. Natori on 08/05/19.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "THAdditionalPluginLoader.h"

#import "THSecondaryThreadProcessor.h"
#import "THSearchListProxyImporter.h"
#import "THRankingExporter.h"
#import "THVideoThumbnailPreviewer.h"
#import "THWebServicePreviewer.h"

#import "THSearchBoardByName.h"

@implementation THAdditionalPluginLoader

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	NSMutableArray *pluginInstances = [NSMutableArray array];
	
	[pluginInstances addObjectsFromArray:[THSecondaryThreadProcessor pluginInstances]];
	[pluginInstances addObjectsFromArray:[THSearchListProxyImporter pluginInstances]];
	[pluginInstances addObjectsFromArray:[THSearchBoardByName pluginInstances]];
	[pluginInstances addObjectsFromArray:[THRankingExporter pluginInstances]];
	[pluginInstances addObjectsFromArray:[THVideoThumbnailPreviewer pluginInstances]];
	//[pluginInstances addObjectsFromArray:[THWebServicePreviewer pluginInstances]];
	
	return pluginInstances;
}
-(NSString *)uniqueName { return nil; }
-(NSString *)localizedName { return nil; }
-(NSString *)localizedPluginInfo { return nil; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderFirst+1; }
@end


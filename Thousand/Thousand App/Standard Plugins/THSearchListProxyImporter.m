//
//  THSearchListProxyImporter.m
//  Thousand
//
//  Created by R. Natori on 08/10/23.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "THSearchListProxyImporter.h"
#import "T2UtilityHeader.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"AdditionalPlugLocalizable"])

static NSString *__uniqueName =			@"jp_natori_Thousand_SearchListProxyImporter";

static NSString *__rootPath			 	= @"SearchListProxy";
static NSString *__rootListImageName 	= @"TH16_SearchMaster";
static NSImage *__rootListImage 		= nil;


@implementation THSearchListProxyImporter

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	__rootListImage = [[NSImage imageNamed:__rootListImageName orInBundle:_selfBundle] retain];
	return self;
}
#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderLast; }

#pragma mark -
#pragma mark protocol T2ListImporting_v100
-(NSString *)importableRootPath { return __rootPath; }
-(T2List *)listForListFace:(T2ListFace *)listFace {
	
	if ([[listFace internalPath] isEqualToString:__rootPath]) {
		return [T2List listWithListFace:listFace
								objects:[[T2PluginManager sharedManager] searchListRootListFaces]];
	}
	return nil;
}
-(NSArray *)rootListFaces {
	return [NSArray arrayWithObject:
			[T2ListFace listFaceWithInternalPath:__rootPath
										   title:plugLocalizedString(__rootPath)
										   image:__rootListImage]];
}
-(NSImage *)imageForListFace:(T2ListFace *)listFace {
	return __rootListImage;
}
@end

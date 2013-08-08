//
//  THRankingExporter.h
//  Thousand
//
//  Created by R. Natori on 平成 20/04/09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>
#import "THStandardPlugHeader.h"


@interface THRankingExporter : NSObject <T2ThreadHTMLExporting_v100> {
	NSBundle *_selfBundle;
	int _rankingMaxCount;
}

// Accessors
-(void)setRankingMaxCount:(int)count ;
-(int)rankingMaxCount ;

// T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;

-(NSArray *)preferenceItems ;

// T2ThreadHTMLExporting_v100
-(NSString *)HTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL ;

// internal method
-(NSString *)identifierRankingWithThread:(T2Thread *)thread ;
-(NSString *)responseRankingWithThread:(T2Thread *)thread ;
-(NSString *)responseToIdentifierRankingWithThread:(T2Thread *)thread ;
@end

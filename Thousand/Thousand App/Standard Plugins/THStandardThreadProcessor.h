//
//  THStandardThreadProcessor.h
//  Thousand
//
//  Created by R. Natori on 06/04/01.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THStandardThreadProcessor : NSObject <T2ThreadProcessing_v100, T2ThreadHTMLProcessing_v100, T2ResExtracting_v100> {
	NSBundle *_selfBundle;
	
	BOOL _enabled;
	NSString *_resAnchorCharactersString;
	NSCharacterSet *_resAnchorCharacterSet;
	
	NSCharacterSet *_controlCharacterSet;
	NSCharacterSet *_digitAndSeparatorCharacterSet;
	NSCharacterSet *_urlCharacterSet;
	//NSCharacterSet *_urlBreakingCharacterSet;
	
	NSArray *_extractKeys;
}
//Accessors
-(void)setResAnchorCharactersString:(NSString *)aString ;
-(NSString *)resAnchorCharactersString ;

	//protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;
-(NSArray *)uniqueNamesOfdependingPlugins ;

	//protocol T2PluginPrefSetting_v100
-(NSArray *)preferenceItems ;

	//protocol T2PluginEnabling
-(void)setEnabled:(BOOL)aBool ;
-(BOOL)enabled ;

	//protocol T2ThreadProcessing_v100
-(void)processThread:(T2Thread *)thread appendingIndex:(unsigned)index ;

	//protocol T2ThreadHTMLProcessing_v100
-(NSString *)processedHTML:(NSString *)htmlString ofRes:(T2Res *)res inThread:(T2Thread *)thread ;

	//protocol T2ResExtracting_v100
-(NSArray *)extractKeys ;
-(NSIndexSet *)extractResIndexesInThread:(T2Thread *)thread forKey:(NSString *)key path:(NSString *)path ;
-(NSString *)localizedDescriptionForKey:(NSString *)key path:(NSString *)path ;

-(NSArray *)defaultExtractPaths ;

@end

//
//  THSecondaryThreadProcessor.h
//  Thousand
//
//  Created by R. Natori on  07/09/08.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>
#import "THStandardPlugHeader.h"


@interface THSecondaryThreadProcessor : NSObject <T2ThreadProcessing_v100, T2ResExtracting_v100, T2DictionaryConverting> {
	NSBundle *_selfBundle;
	
	BOOL _aaDetectorEnabled;
	BOOL _mineDetectorEnabled;
	
	NSCharacterSet *_skipCharSet;
	NSCharacterSet *_AACharSet;
	NSString *_AACharSetString;
	
	NSString *_minesString;
	NSArray *_mineStrings;
	
	NSArray *_extractKeys;
}

//Accessors
-(void)setAaDetectorEnabled:(BOOL)aBool ;
-(BOOL)aaDetectorEnabled ;
-(void)setMineDetectorEnabled:(BOOL)aBool ;
-(BOOL)mineDetectorEnabled ;

-(void)setAACharSetString:(NSString *)string ;
-(NSString *)AACharSetString ;
-(void)setMinesString:(NSString *)aString ;
-(NSString *)minesString ;

	//protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;
-(NSArray *)uniqueNamesOfdependingPlugins ;

	//protocol T2ThreadProcessing_v100
-(void)processThread:(T2Thread *)thread appendingIndex:(unsigned)index ;

	//protocol T2ResExtracting_v100
-(NSArray *)extractKeys ;
-(NSIndexSet *)extractResIndexesInThread:(T2Thread *)thread forKey:(NSString *)key path:(NSString *)path ;
-(NSString *)localizedDescriptionForKey:(NSString *)key path:(NSString *)path ;
-(NSArray *)defaultExtractPaths ;
@end

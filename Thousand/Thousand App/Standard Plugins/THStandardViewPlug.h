//
//  THStandardViewPlug.h
//  Thousand
//
//  Created by R. Natori on 05/06/26.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THStandardViewPlug : NSObject <T2ThreadPartialHTMLExporting_v100, T2DictionaryConverting> {
	NSBundle *_selfBundle;
	
	NSDictionary *_skinFilesDictionary;
	NSString *_templateName;
	NSString *_templatePath;
	
	NSString *_HTML_Header;
	NSString *_HTML_ResPart;
	NSString *_HTML_Footer;
	
	NSString *_popUp_Header;
	NSString *_popUp_Footer;
	
	T2KeyValueReplace *_headerReplace ;
	T2KeyValueReplace *_resReplace ;
	T2KeyValueReplace *_footerReplace ;
	
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
#pragma mark T2PluginPrefSetting_v100
-(NSArray *)preferenceItems ;

#pragma mark -
#pragma mark Accessors
-(NSArray *)templateNames ;
-(void)setTemplateName:(NSString *)aString ;
-(NSString *)templateName ;

-(void)loadTemplate ;
-(void)loadTemplateList ;

#pragma mark -
#pragma mark protocol T2ThreadPartialHTMLExporting_v100
-(NSString *)headerHTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL ;
-(NSString *)footerHTMLWithThread:(T2Thread *)thread ;
-(NSString *)resHTMLWithRes:(T2Res *)res ;
-(NSString *)popUpHeaderHTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL ;
-(NSString *)popUpFooterHTMLWithThread:(T2Thread *)thread ;


#pragma mark -
#pragma mark protocol T2ThreadHTMLExporting_v100
-(NSString *)HTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL ;
	// internal
	NSMutableString *deleteAtIfComment(NSString *string);
	unsigned buildPartStringAndKeyArray(NSString *src, NSMutableArray *partStringArray, NSMutableArray *keyArray) ;
	NSMutableString *buildResultString(id object, unsigned capacity, NSArray *partStringArray, NSArray *keyArray) ;
@end


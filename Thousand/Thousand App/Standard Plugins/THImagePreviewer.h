//
//  THImagePreviewer.h
//  Thousand
//
//  Created by R. Natori on  07/07/01.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THImagePreviewer : NSObject <T2URLPreviewing_v100, T2DictionaryConverting> {
	NSBundle *_selfBundle;
	
	int _widthPixel;
	int _inlineWidthPixel;
}

#pragma mark -
#pragma mark Accessors
-(void)setWidthPixel:(int)widthPixel;
-(int)widthPixel;
-(void)setInlineWidthPixel:(int)inlineWidthPixel;
-(int)inlineWidthPixel;


#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;

-(NSArray *)preferenceItems ;

#pragma mark -
#pragma mark protocol T2URLPreviewing_v100
-(NSArray *)previewableURLHosts;
-(NSArray *)previewableURLExtensions;
-(BOOL)isPreviewableURLString:(NSString *)urlString type:(T2PreviewType)type ;
-(NSString *)partialHTMLForPreviewingURLString:(NSString *)urlString
										  type:(T2PreviewType)type
									   minSize:(NSSize *)minSize ;
@end

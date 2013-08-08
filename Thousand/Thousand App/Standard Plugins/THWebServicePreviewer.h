//
//  THWebServicePreviewer.h
//  Thousand
//
//  Created by R. Natori on 08/08/11.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THWebServicePreviewer : NSObject <T2PluginInterface_v100, T2URLPreviewing_v100> {
	NSBundle *_selfBundle;

}

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;

#pragma mark -
#pragma mark protocol T2URLPreviewing_v100
-(NSArray *)previewableURLHosts;
-(NSArray *)previewableURLExtensions;
-(BOOL)isPreviewableURLString:(NSString *)urlString type:(T2PreviewType)type ;
-(NSString *)partialHTMLForPreviewingURLString:(NSString *)urlString
										  type:(T2PreviewType)type
									   minSize:(NSSize *)minSize ;
@end

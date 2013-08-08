//
//  THVideoThumbnailPreviewer.h
//  Thousand
//
//  Created by R. Natori on  07/08/06.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "THStandardPlugHeader.h"

@interface THVideoThumbnailPreviewer : NSObject <T2URLPreviewing_v100> {
	NSBundle *_selfBundle;
	NSString *_youTubePopUpFormat;
	NSString *_youTubeInlineFormat;
	NSString *_nicoPopUpFormat;
	NSString *_nicoInlineFormat;
	
	NSString *_audioInlineFormat;
	NSDictionary *_audioMIMETypesForExtensions;
	NSArray *_audioExtensions;
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

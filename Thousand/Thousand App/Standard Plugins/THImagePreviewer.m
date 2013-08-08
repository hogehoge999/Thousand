//
//  THImagePreviewer.m
//  Thousand
//
//  Created by R. Natori on  07/07/01.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "THImagePreviewer.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"StandardPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_Thousand_ImagePreviewer";

@implementation THImagePreviewer

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	
	_widthPixel = 150;
	_inlineWidthPixel = 250;
	return self;
}

#pragma mark -
#pragma mark Accessors
-(void)setWidthPixel:(int)widthPixel {
	if (widthPixel>0) _widthPixel = widthPixel;
}
-(int)widthPixel { return _widthPixel; }
-(void)setInlineWidthPixel:(int)inlineWidthPixel {
	if (inlineWidthPixel>0) _inlineWidthPixel = inlineWidthPixel;
}
-(int)inlineWidthPixel { return _inlineWidthPixel; }

#pragma mark -
#pragma mark Protocol T2DictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"widthPixel", @"inlineWidthPixel",
		nil];
}

#pragma mark -
#pragma mark Protocol T2PluginInterface_v100

+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }

-(int)pluginOrder { return T2PluginOrderFirst; }

-(NSArray *)preferenceItems {
	return [NSArray arrayWithObjects:
		[T2PreferenceItem numberItemWithKey:@"widthPixel"
									  title:plugLocalizedString(@"Pop-Up Preview Width")
									   info:nil],
		[T2PreferenceItem numberItemWithKey:@"inlineWidthPixel"
									  title:plugLocalizedString(@"Inline Preview Width")
									   info:nil],
		nil];
}

-(NSArray *)previewableURLHosts { return nil; }
-(NSArray *)previewableURLExtensions {
	return [NSArray arrayWithObjects:
		@"jpg", @"jpeg", @"gif", @"png", @"tif", @"tiff", @"bmp", @"ico",
		@"JPG", @"JPEG", @"GIF", @"PNG", @"TIF", @"TIFF", @"BMP", @"ICO", nil];
}

-(BOOL)isPreviewableURLString:(NSString *)urlString type:(T2PreviewType)type {
	return YES;
}
	
-(NSString *)partialHTMLForPreviewingURLString:(NSString *)urlString
										  type:(T2PreviewType)type
									   minSize:(NSSize *)minSize {
	int widthPixel;
	if (type == T2PreviewInline)
		widthPixel = _inlineWidthPixel;
	else
		widthPixel = _widthPixel;
		
	*minSize = NSMakeSize(widthPixel, widthPixel);
	return [NSString stringWithFormat:
		@"<a href=\"%@\" class=\"noPreview\"><img src=\"%@\" alt=%@ width=%d></a>", urlString, urlString, urlString, widthPixel];
}
@end

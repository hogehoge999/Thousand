//
//  THWebServicePreviewer.m
//  Thousand
//
//  Created by R. Natori on 08/08/11.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "THWebServicePreviewer.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"AdditionalPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_Thousand_WebServicePreviewer";

@implementation THWebServicePreviewer

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	return self;
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

-(int)pluginOrder { return T2PluginOrderLast; }

#pragma mark -
#pragma mark protocol T2URLPreviewing_v100

-(NSArray *)previewableURLHosts {
	return [NSArray arrayWithObjects:
			@"finance.yahoo.com",
			@"stooq.com",
			nil];
}

-(NSArray *)previewableURLExtensions {
	return nil;
}

-(BOOL)isPreviewableURLString:(NSString *)urlString type:(T2PreviewType)type {
	if ([urlString hasPrefix:@"http://finance.yahoo.com/q/bc?"] ||
		[urlString hasPrefix:@"http://stooq.com/q/?s"]) {
		return YES;
	}
	return NO;
}

-(NSString *)partialHTMLForPreviewingURLString:(NSString *)urlString
										  type:(T2PreviewType)type
									   minSize:(NSSize *)minSize {
	NSRange range = [urlString rangeOfString:@"http://finance.yahoo.com/q/bc?"
									 options:NSLiteralSearch];
	if (range.location != NSNotFound) {
		if ([urlString length] <= range.length) return @"";
		
		NSString *inputString = [urlString substringFromIndex:range.length];
		if (type == T2PreviewInPopUp) {
			inputString = [inputString stringByReplacingFirstOccurrencesOfString:@"z=l" withString:@"z=s" options:NSLiteralSearch];
			inputString = [inputString stringByReplacingFirstOccurrencesOfString:@"z=m" withString:@"z=s" options:NSLiteralSearch];
		} else if (type == T2PreviewInline) {
			inputString = [inputString stringByReplacingFirstOccurrencesOfString:@"z=l" withString:@"z=m" options:NSLiteralSearch];
		}
		
		return [NSString stringWithFormat:@"<a href=\"%@\" class=\"noPreview\"><img src=\"http://ichart.finance.yahoo.com/z?%@\"></a>", urlString, inputString];
		
	}
	
	range = [urlString rangeOfString:@"http://stooq.com/q/?s"
									 options:NSLiteralSearch];
	if (range.location != NSNotFound) {
		if ([urlString length] <= range.length) return @"";
		
		NSString *inputString = [urlString substringFromIndex:range.length];
		inputString = [inputString stringByReplacingFirstOccurrencesOfString:@"a=lg" withString:@"a=ln" options:NSLiteralSearch];
		inputString = [inputString stringByReplacingFirstOccurrencesOfString:@"&b=0" withString:@"" options:NSLiteralSearch];
		inputString = [inputString stringByReplacingFirstOccurrencesOfString:@"&b=1" withString:@"" options:NSLiteralSearch];
		
		return [NSString stringWithFormat:@"<a href=\"%@\" class=\"noPreview\"><img src=\"http://stooq.com/c/?s%@\"></a>", urlString, inputString];
		
	}
	return @"";
}
@end

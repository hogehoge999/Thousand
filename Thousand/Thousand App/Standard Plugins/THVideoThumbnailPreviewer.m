//
//  THVideoThumbnailPreviewer.m
//  Thousand
//
//  Created by R. Natori on  07/08/06.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "THVideoThumbnailPreviewer.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"AdditionalPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_Thousand_VideoThumbnailPreviewer";

@implementation THVideoThumbnailPreviewer

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[_selfBundle pathForResource:@"THVideoThumbnailPreviewerDefaults" ofType:@"plist"]];
	_youTubePopUpFormat = [[dictionary objectForKey:@"youTubePopUpFormat"] retain];
	_youTubeInlineFormat = [[dictionary objectForKey:@"youTubeInlineFormat"] retain];
	_audioInlineFormat = [[dictionary objectForKey:@"audioInlineFormat"] retain];
	_audioMIMETypesForExtensions = [[dictionary objectForKey:@"audioMIMETypesForExtensions"] retain];
	_audioExtensions = [[_audioMIMETypesForExtensions allKeys] retain];
	return self;
}
-(void)dealloc {
	[_youTubePopUpFormat release];
	[_youTubeInlineFormat release];
	[_audioInlineFormat release];
	[_audioMIMETypesForExtensions release];
	[_audioExtensions release];
	[super dealloc];
}

#pragma mark -
#pragma mark Protocol T2PluginInterface_v100

+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName) ; }
-(NSString *)localizedPluginInfo {
	NSString *extensions = plugLocalizedString(@"Nothing");
	if (_audioExtensions) {
		extensions = [_audioExtensions componentsJoinedByString:@", "];
	}
	return [NSString stringWithFormat:plugLocalizedString([__uniqueName stringByAppendingString:@"_info_format"])
			, extensions];
}
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }

-(int)pluginOrder { return T2PluginOrderLast; }


#pragma mark -
#pragma mark protocol T2URLPreviewing_v100

-(NSArray *)previewableURLHosts {
	return [NSArray arrayWithObjects:
			@"www.youtube.com",
			@"jp.youtube.com",
			@"youtube.com",
			@"www.nicovideo.jp",
			nil];
}

-(NSArray *)previewableURLExtensions {
	return _audioExtensions;
}

-(BOOL)isPreviewableURLString:(NSString *)urlString type:(T2PreviewType)type {
	// Audios
	if (_audioExtensions && [_audioExtensions containsObject:[urlString pathExtension]]) {
		if (type == T2PreviewInline) {
			return YES;
		}
		return NO;
	}
	
	// Videos
	NSArray *pathComponents = [urlString pathComponents];
	if ([pathComponents count] < 3) return NO;
	
	NSString *host = [pathComponents objectAtIndex:1];
	if ([host hasSuffix:@"youtube.com"]) {
		if ([[pathComponents objectAtIndex:2] rangeOfString:@"watch?v="].location != NSNotFound)
			return YES;
	} else if ([host isEqualToString:@"www.nicovideo.jp"]) {
		if ([pathComponents count] < 4) return NO;
		if ([[pathComponents objectAtIndex:2] isEqualToString:@"watch"])
			return YES;
		
	}
	return NO;
}

-(NSString *)partialHTMLForPreviewingURLString:(NSString *)urlString
										  type:(T2PreviewType)type
									   minSize:(NSSize *)minSize {
	
	// Audios
	NSString *extension = [urlString pathExtension];
	if (_audioExtensions && [_audioExtensions containsObject:extension]) {
		if (type == T2PreviewInline) {
			NSString *MIMEType = [_audioMIMETypesForExtensions objectForKey:extension];
			return [NSString stringWithFormat:_audioInlineFormat, urlString, MIMEType, urlString, urlString, urlString, urlString];
		} 
		return @"Click To Play.";
	}
	
	// Videos
	NSArray *pathComponents = [urlString pathComponents];
	if ([pathComponents count] < 3) return @"";
	
	NSString *host = [pathComponents objectAtIndex:1];
	
	if ([host hasSuffix:@"youtube.com"]) {
		NSString *params = [pathComponents objectAtIndex:2];
		NSRange prefixRange = [params rangeOfString:@"v="];
		if (prefixRange.location == NSNotFound) return @"";
		NSRange suffixRange = [params rangeOfString:@"&" options:NSLiteralSearch
											  range:NSMakeRange(prefixRange.location, [params length]-(prefixRange.location+prefixRange.length))];
		if (suffixRange.location == NSNotFound) {
			suffixRange.location = [params length];
			suffixRange.length = 0;
		}
		NSString *videoID = [params substringWithRange:NSMakeRange(prefixRange.location+prefixRange.length
																   , suffixRange.location-(prefixRange.location+prefixRange.length) )];
		
		
		if (type == T2PreviewInPopUp) {
			*minSize = NSMakeSize(150, 100);
			return [NSString stringWithFormat:_youTubePopUpFormat,
				urlString, videoID, urlString];
		} else {
			*minSize = NSMakeSize(425, 355);
			return [NSString stringWithFormat:_youTubeInlineFormat,
					videoID, videoID, videoID, videoID];
		}
	} else if ([host isEqualToString:@"www.nicovideo.jp"]) {
		
		if ([pathComponents count] < 4) return NO;
		*minSize = NSMakeSize(312, 176);
		NSString *videoID = [pathComponents objectAtIndex:3];
		return [NSString stringWithFormat:@"<iframe width=\"312\" height=\"176\" src=\"http://www.nicovideo.jp/thumb/%@\" scrolling=\"no\" style=\"border:solid 1px #CCC;\" frameborder=\"0\"><a href=\"%@\" class=\"noPreview\">%@</a></iframe> <br/> <a href=\"%@\" class=\"noPreview\">%@</a>",
			videoID, urlString, urlString, urlString, urlString];
	}
	return [NSString stringWithFormat:@"Can't Preview:%@", urlString];
}
@end

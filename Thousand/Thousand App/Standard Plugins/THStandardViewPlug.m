//
//  THStandardViewPlug.m
//  Thousand
//
//  Created by R. Natori on 05/06/26.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "THStandardViewPlug.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"StandardPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_Thousand_standardHTMLView";
static NSString *__skinFolderName = @"Skins";
static NSString *__standardSkinName = @"standard";

static NSString *__atIfStart = @"<!--@if";
static NSString *__atIfEnd = @"-->";

static NSCharacterSet *__controlCharSet = nil;

@implementation THStandardViewPlug

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	
	[self loadTemplateList];
	
	// ready charactor set
	__controlCharSet = [[NSCharacterSet controlCharacterSet] retain];
	
	return self;
}
-(void)loadTemplateList {
	// Skin file extensions
	NSArray *extensions = [NSArray arrayWithObjects:@"html", @"htm", @"txt", nil];
	
	// All skin files list
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *skinFolderPaths = [NSArray arrayWithObjects:
		[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:__skinFolderName],
		[[NSString ownAppSupportFolderPath] stringByAppendingPathComponent:__skinFolderName],nil];
	NSString *skinFolderPath;
	NSEnumerator *skinFolderEnumerator = [skinFolderPaths objectEnumerator];
	
	NSEnumerator *skinfilePathsEnumerator;
	NSString *skinFilePath;
	
	NSMutableArray *skinFilePaths = [NSMutableArray array];
	NSString *standardSkinFilePath = [_selfBundle pathForResource:__standardSkinName ofType:@"html"];
	if (standardSkinFilePath) {
		[skinFilePaths addObject:standardSkinFilePath];
	}
	
	while (skinFolderPath = [skinFolderEnumerator nextObject]) {
		NSArray *skinFilePathsInFolder = [fileManager directoryContentsAtPath:skinFolderPath];
		skinfilePathsEnumerator = [skinFilePathsInFolder objectEnumerator];
		while (skinFilePath = [skinfilePathsEnumerator nextObject]) {
			NSString *pathExtension = [skinFilePath pathExtension];
			if ([extensions containsObject:pathExtension])
				[skinFilePaths addObject:[skinFolderPath stringByAppendingPathComponent:skinFilePath]];
			else if (!pathExtension || [pathExtension isEqualToString:@""]) {
				NSString *newSkinFilePath = [[skinFolderPath stringByAppendingPathComponent:skinFilePath] stringByAppendingPathComponent:[skinFilePath stringByAppendingPathExtension:@"html"]];
				if ([fileManager fileExistsAtPath:newSkinFilePath])
					[skinFilePaths addObject:newSkinFilePath];
			}
		}
	}
	
	// make Dictionary
	skinfilePathsEnumerator = [skinFilePaths objectEnumerator];
	NSMutableDictionary *skinFilesDictionary = [NSMutableDictionary dictionary];
	while (skinFilePath = [skinfilePathsEnumerator nextObject]) {
		[skinFilesDictionary setObject:skinFilePath forKey:[skinFilePath lastPathComponent]];
	}
	if ([skinFilesDictionary count] > 0) {
		[self willChangeValueForKey:@"templateNames"];
		setObjectWithRetain(_skinFilesDictionary, skinFilesDictionary);
		[self didChangeValueForKey:@"templateNames"];
	}
}

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName); }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderFirst; }
-(NSArray *)uniqueNamesOfdependingPlugins { return nil; }

#pragma mark -
#pragma mark Protocol T2DictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"templateName", nil];
}

#pragma mark -
#pragma mark Protocol T2PluginPrefSetting_v100
-(NSArray *)preferenceItems {
	return [NSArray arrayWithObjects:[T2PreferenceItem stringPopUpItemWithKey:@"templateName"
																		title:@"Skin File"
																		 info:nil
																	listItems:[_skinFilesDictionary allKeys]],
		nil];
}

#pragma mark -
#pragma mark Accessors
-(NSArray *)templateNames {
	NSMutableArray *templateNames = [[[_skinFilesDictionary allKeys] mutableCopy] autorelease];
	[templateNames sortUsingSelector:@selector(compare:)];
	return [[templateNames copy] autorelease];
}
-(void)setTemplateName:(NSString *)aString {
	if (!aString || [_templateName isEqualToString:aString]) return;
	
	[aString retain];
	[_templateName release];
	_templateName = aString;
	
	[_templatePath release];
	_templatePath = [[_skinFilesDictionary objectForKey:_templateName] retain];
	[self loadTemplate];
}
-(NSString *)templateName { return _templateName; }

-(void)loadTemplate {
	
	if (!_templateName) {
		if (!_skinFilesDictionary) return;
		[self setTemplateName:[[_skinFilesDictionary allKeys] objectAtIndex:0]];
		return;
	}
	NSString *templateHTML = [NSString stringWithContentsOfFile:_templatePath];
	if (!templateHTML) return;
	
	// for Compatible
	NSMutableString *mutableTemplateHTML = [[templateHTML mutableCopy] autorelease];
	[mutableTemplateHTML replaceOccurrencesOfString:@"@(title)"
										 withString:@"@(escapedTitle)"
											options:NSLiteralSearch
											  range:NSMakeRange(0, [mutableTemplateHTML length])];
	templateHTML = [[mutableTemplateHTML copy] autorelease];
	
	
	// Scan template HTML
	
	NSString *resPartStart = 	@"<!--@ResPartStart-->";
	NSString *resPartEnd = 		@"<!--@ResPartEnd-->";
	NSString *templateEnd = 	@"<!--@TemplateEnd-->";
	
	
	NSString 	*HTML_ResPart = 		nil, *HTML_Footer = nil;
	NSString 	*HTML_Header = 	nil;
	
	
	NSScanner *templateHTMLScanner = [NSScanner scannerWithString:templateHTML];
	[templateHTMLScanner setCharactersToBeSkipped:[NSCharacterSet controlCharacterSet]];
	// scan header
	[templateHTMLScanner scanUpToString:resPartStart intoString:&HTML_Header] ;
	[templateHTMLScanner scanString:resPartStart intoString:NULL] ;
	// scan res
	[templateHTMLScanner scanUpToString:resPartEnd intoString:&HTML_ResPart] ;
	[templateHTMLScanner scanString:resPartEnd intoString:NULL];
	[templateHTMLScanner scanUpToString:templateEnd intoString:&HTML_Footer];
	
	NSMutableString *mutableHTML_Header = [[HTML_Header mutableCopy] autorelease];
	
	NSURL *templateURL = [NSURL fileURLWithPath:_templatePath];
	NSString *templateURLString = [templateURL absoluteString];
	templateURLString = [templateURLString substringToIndex:[templateURLString rangeOfLastString:@"/" options:NSLiteralSearch].location];
	[mutableHTML_Header replaceOccurrencesOfString:@"@(skinFileBaseURLString)"
										withString:templateURLString
										   options:NSLiteralSearch
											 range:NSMakeRange(0,[mutableHTML_Header length])];
	
	_HTML_Header = 	[mutableHTML_Header copy];
	_HTML_ResPart =	[HTML_ResPart copy];
	_HTML_Footer = 	[HTML_Footer copy];
	
	_popUp_Header = [_HTML_Header retain];
	_popUp_Footer = [_HTML_Footer retain];
	
	// Scan PartStrings and Keys
	_headerReplace = [[T2KeyValueReplace keyReplaceWithTemplateString:_HTML_Header] retain];
	_resReplace = [[T2KeyValueReplace keyReplaceWithTemplateString:_HTML_ResPart] retain];
	_footerReplace = [[T2KeyValueReplace keyReplaceWithTemplateString:_HTML_Footer] retain];
	
}


#pragma mark -
#pragma mark protocol T2ThreadPartialHTMLExporting_v100
-(NSString *)headerHTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL {
	if (!_HTML_Header) {
		[self loadTemplate];
	}
	NSString *resultHTML = [_headerReplace replacedStringUsingObject:thread];
	/*
	= buildResultString(thread, _headerPartCapacity, _headerPartStrings, _headerKeys);
	 */
	if (resultHTML) {
		NSURL *tempBaseURL = [NSURL fileURLWithPath:_templatePath];
		*baseURL = tempBaseURL;
		return resultHTML;
	} else return nil;
}
-(NSString *)footerHTMLWithThread:(T2Thread *)thread {
	return [_footerReplace replacedStringUsingObject:thread];
	/*
	buildResultString(thread, _footerPartCapacity, _footerPartStrings, _footerKeys);
	 */
}
-(NSString *)resHTMLWithRes:(T2Res *)res {
	return [_resReplace replacedStringUsingObject:res];
	/*
	 deleteAtIfComment(buildResultString(res, _resPartCapacity, _resPartStrings, _resKeys));
	 */
}
-(NSString *)popUpHeaderHTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL {
	if (!_HTML_Header) {
		[self loadTemplate];
	}
	NSString *resultHTML = [_headerReplace replacedStringUsingObject:thread];
	//NSString *resultHTML = buildResultString(thread, _headerPartCapacity, _headerPartStrings, _headerKeys);
	if (resultHTML) {
		NSRange bodyRange = [resultHTML rangeOfString:@"<body>"];
		NSString *resultHTML2 = [resultHTML substringToIndex:bodyRange.location];
		resultHTML2 = [resultHTML2 stringByAppendingString:@"<body class=\"popUp\">"];
		NSURL *tempBaseURL = [NSURL fileURLWithPath:_templatePath];
		*baseURL = tempBaseURL;
		return resultHTML2;
	} else return nil;
	
}
-(NSString *)popUpFooterHTMLWithThread:(T2Thread *)thread {
	return [_footerReplace replacedStringUsingObject:thread];
	//return buildResultString(thread, _footerPartCapacity, _footerPartStrings, _footerKeys);
}


#pragma mark -
#pragma mark protocol T2ThreadHTMLExporting_v100
-(NSString *)HTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL {
	if (!_HTML_Header) {
		[self loadTemplate];
		if (!_HTML_Header) return @"Skin file was not found";
	}
	
	NSAutoreleasePool *myPool;
	
	NSArray *resArray = [thread resArray];
	NSEnumerator *resEnumerator = [resArray objectEnumerator];
	T2Res *tempRes;
	NSMutableString *htmlRep = [NSMutableString string];
	/*[[[NSMutableString alloc]
 initWithCapacity:(_headerPartCapacity + _footerPartCapacity + _resPartCapacity*[resArray count])
		] autorelease];
	 */
	NSMutableString *buildingPartString;
	NSMutableString *partString;
	NSString *tempString;
	NSString *key;
	
	// Header
	[htmlRep appendString:[_headerReplace replacedStringUsingObject:thread]];
	// buildResultString(thread, _headerPartCapacity, _headerPartStrings, _headerKeys)];
	
	// Res
	while (tempRes = [resEnumerator nextObject]) {
			myPool = [[NSAutoreleasePool alloc] init];
			
	 [htmlRep appendString:[_resReplace replacedStringUsingObject:tempRes]];
			 //deleteAtIfComment(buildResultString(tempRes, _resPartCapacity, _resPartStrings, _resKeys))];
			
			[myPool release];
		}
		
	// Footer
	[htmlRep appendString:[_footerReplace replacedStringUsingObject:thread]];
	 //buildResultString(thread, _footerPartCapacity, _footerPartStrings, _footerKeys)];
	
	NSURL *tempBaseURL = [NSURL fileURLWithPath:_templatePath];
	baseURL = &tempBaseURL;
	return htmlRep;
}

// internal 
/*
NSMutableString *deleteAtIfComment(NSString *string) {
	NSMutableString *buildingPartString = [[[NSMutableString alloc] init] autorelease];
	NSString *tempString;
	NSScanner *partStringScanner = [NSScanner scannerWithString:string];
	[partStringScanner setCharactersToBeSkipped:__controlCharSet];
	[partStringScanner scanUpToString:__atIfStart intoString:&tempString];
	if (tempString) [buildingPartString appendString:tempString];
	while ([partStringScanner scanString:__atIfStart intoString:NULL]
		   && [partStringScanner scanUpToString:__atIfEnd intoString:&tempString]) {
		
		if (tempString && ([tempString rangeOfString:@"@(" options:NSLiteralSearch].location == NSNotFound))
			[buildingPartString appendString:tempString];
		[partStringScanner scanString:__atIfEnd intoString:NULL];
		if ([partStringScanner scanUpToString:__atIfStart intoString:&tempString])
			if (tempString) [buildingPartString appendString:tempString];
	}
	return buildingPartString;
}

unsigned buildPartStringAndKeyArray(NSString *src, NSMutableArray *partStringArray, NSMutableArray *keyArray) {
	NSScanner *scanner = [NSScanner scannerWithString:src];
	[scanner setCharactersToBeSkipped:__controlCharSet];
	NSString *partString, *key;
	unsigned capacity = 0;
	while ([scanner scanUpToString:@"@(" intoString:&partString]
		   && [scanner scanString:@"@(" intoString:NULL]
		   && [scanner scanUpToString:@")" intoString:&key]
		   && [scanner scanString:@")" intoString:NULL]) {
		if (!partString) partString = @"";
		[partStringArray addObject:partString];
		capacity += [partString length];
		if (!key) key = @"";
		[keyArray addObject:key];
	}
	if (!partString) partString = @"";
	[partStringArray addObject:partString];
	return capacity;
}

NSMutableString *buildResultString(id object, unsigned capacity, NSArray *partStringArray, NSArray *keyArray) {
	NSMutableString *resultString = [[[NSMutableString alloc] initWithCapacity:capacity] autorelease];
	NSEnumerator *partStringEnumerator = [partStringArray objectEnumerator];
	NSEnumerator *keyEnumerator = [keyArray objectEnumerator];
	NSString *partString, *key;
	
	partString = [partStringEnumerator nextObject];
	[resultString appendString:partString];
	
	while ((key = [keyEnumerator nextObject]) && (partString = [partStringEnumerator nextObject])) {
		NSString *value = [object valueForKey:key];
		if (value)
			[resultString appendString:value];
		else
			[resultString appendFormat:@"@(%@)", key];
		[resultString appendString:partString];
			
	}
	return resultString;
}
*/
@end

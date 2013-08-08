//
//  THStandardThreadProcessor.m
//  Thousand
//
//  Created by R. Natori on 06/04/01.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "THStandardThreadProcessor.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"StandardPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_Thousand_StandardThreadProcessor";

static NSString *__defaultResAnchorString = @"&gt;";
static NSString *__resLinkFormat = @"<a href=\"internal://resNumber/%@\">%@</a>";


@implementation THStandardThreadProcessor

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	
	_controlCharacterSet = [[NSCharacterSet controlCharacterSet] retain];
	_digitAndSeparatorCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:plugLocalizedString(@"digitAndSeparatorString")] retain];
	NSMutableCharacterSet *alphanumericCharacterSet = [[[NSCharacterSet alphanumericCharacterSet] mutableCopy] autorelease];
	[alphanumericCharacterSet addCharactersInString:@":/?#[]@!$&'()*+,;=.-_~%"];
	//_urlCharacterSet = [[NSCharacterSet characterSetWithRange:NSMakeRange(0x0021, 0x007E)] retain];
	_urlCharacterSet = [alphanumericCharacterSet copy];
	//[alphanumericCharacterSet release];
	//[[NSCharacterSet letterCharacterSet] retain];
	//_urlBreakingCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:plugLocalizedString(@"urlBreaking")] retain];
	[self setResAnchorCharactersString:plugLocalizedString(@"resAnchorCharactersString")];
	
	_extractKeys = [[NSArray arrayWithObjects:
					 @"automatic",
					 @"allRes",
					 @"resNumber",
					 @"last",
					 @"newPlus",
					 @"trace",
					 @"traceOnce",
					 @"backtrace",
					 @"backtraceOnce",
					 @"identifier",
					 @"trip",
					 @"word",
					 @"style",
					 @"previewable",
					 nil] retain];
	
	return self;
}

-(void)dealloc {
	[_resAnchorCharactersString release];
	[_resAnchorCharacterSet release];
	
	[_controlCharacterSet release];
	[_digitAndSeparatorCharacterSet release];
	[_urlCharacterSet release];
	
	[_extractKeys release];
	[super dealloc];
}

-(void)setResAnchorCharactersString:(NSString *)aString {
	[aString retain];
	[_resAnchorCharactersString release];
	_resAnchorCharactersString = aString;
	
	[_resAnchorCharacterSet release];
	_resAnchorCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:_resAnchorCharactersString] retain];
}
-(NSString *)resAnchorCharactersString { return _resAnchorCharactersString; }


#pragma mark -
#pragma mark Protocol T2PluginInterface_v100

+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName ; }
-(NSString *)localizedName { return plugLocalizedString([self uniqueName]) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([[self uniqueName] stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderFirst; }
-(NSArray *)uniqueNamesOfdependingPlugins { return nil; }

#pragma mark -
#pragma mark protocol T2PluginPrefSetting_v100
-(NSArray *)preferenceItems {
	return [NSArray arrayWithObjects:
			[T2PreferenceItem stringItemWithKey:@"resAnchorCharactersString"
										  title:plugLocalizedString(@"Other Res Anchor")
										   info:plugLocalizedString(@"Res Anchor Except \">, >>\"")]
			,nil];
}

#pragma mark -
#pragma mark protocol T2PluginEnabling
-(void)setEnabled:(BOOL)aBool {
	_enabled = aBool;
}
-(BOOL)enabled { return _enabled; }

#pragma mark -
#pragma mark Protocol T2ThreadProcessing_v100
-(void)processThread:(T2Thread *)thread appendingIndex:(unsigned)index {
	NSArray *resArray = [thread resArray];
	//NSEnumerator *resEnumerator = [resArray objectEnumerator];
    NSLog(@"processThread start");
	
    T2Res *res;
	
	NSMutableDictionary *idDictionary = [[[thread idDictionary] mutableCopy] autorelease];
	if (!idDictionary) idDictionary = [NSMutableDictionary dictionary];
	NSMutableDictionary *tripDictionary = [[[thread tripDictionary] mutableCopy] autorelease];
	if (!tripDictionary) tripDictionary = [NSMutableDictionary dictionary];
	
	NSAutoreleasePool *pool;
	
	unsigned resNumber, resCount = [resArray count];

    NSLog(@"3 index = %d", index);

	for (resNumber = index; resNumber<resCount; resNumber++) {
		res = [resArray objectAtIndex:resNumber];
		pool = [[NSAutoreleasePool alloc] init];
		
		NSString *content = [res content];
		NSScanner *contentScanner = [NSScanner scannerWithString:content];
		[contentScanner setCharactersToBeSkipped:_controlCharacterSet];
		NSString *scanedString;
		unsigned scanedLocation;
		NSRange scanedRange;
		
		//NSMutableIndexSet *anchoredResIndexSet = [NSMutableIndexSet indexSet];
		//scan ">, >>"
		while (![contentScanner isAtEnd]) {
			if ([contentScanner scanString:__defaultResAnchorString intoString:NULL]) {
				unsigned i;
				for (i=0; i<2; i++) {
					if (![contentScanner scanString:__defaultResAnchorString intoString:NULL]) break;
				}
				
				if ([contentScanner scanCharactersFromSet:_digitAndSeparatorCharacterSet intoString:&scanedString]) {
					scanedString = [scanedString halfWidthString];
					NSIndexSet *indexSet = [NSIndexSet shiftedIndexSetWithString:scanedString];
					if (indexSet && [indexSet count] < 100) {
						int index = [indexSet firstIndex];
                        NSLog(@"index = %d", index);
						unsigned j=0;
						while (index != -1/*NSNotFound*/ && index < resCount) {
							[res addBackwardResIndex:index];
							[(T2Res *)[resArray objectAtIndex:index] addForwardResIndex:resNumber];
							index = [indexSet indexGreaterThanIndex:index];
						} 
					}
				}
			} else {
				[contentScanner scanUpToString:__defaultResAnchorString intoString:NULL];
			}
		}
		
		//scan other
		[contentScanner setScanLocation:0];
		
		while (![contentScanner isAtEnd]) {
			if ([contentScanner scanCharactersFromSet:_resAnchorCharacterSet intoString:NULL]) {
				
				if ([contentScanner scanCharactersFromSet:_digitAndSeparatorCharacterSet intoString:&scanedString]) {
					scanedString = [scanedString halfWidthString];
					NSIndexSet *indexSet = [NSIndexSet shiftedIndexSetWithString:scanedString];
					if (indexSet && [indexSet count] < 100) {
						int index = [indexSet firstIndex];
                        NSLog(@"index = %d", index);
						while (index != -1/*NSNotFound*/ && index < resCount) {
							[res addBackwardResIndex:index];
							[(T2Res *)[resArray objectAtIndex:index] addForwardResIndex:resNumber];
							index = [indexSet indexGreaterThanIndex:index];
						} 
					}
				}
			} else {
				[contentScanner scanUpToCharactersFromSet:_resAnchorCharacterSet intoString:NULL];
			}
			
		}
		
		//ID dic
		NSString *identifier = [res identifier];
		if (identifier) {
			NSMutableIndexSet *mutableIndexSet = [idDictionary objectForKey:identifier];
			if (!mutableIndexSet) {
				mutableIndexSet = [NSMutableIndexSet indexSet];
				[idDictionary setObject:mutableIndexSet forKey:identifier];
			}
			[mutableIndexSet addIndex:resNumber];
		}
		//trip dic
		identifier = [res trip];
		if (identifier) {
			NSMutableIndexSet *mutableIndexSet = [tripDictionary objectForKey:identifier];
			if (!mutableIndexSet) {
				mutableIndexSet = [NSMutableIndexSet indexSet];
				[tripDictionary setObject:mutableIndexSet forKey:identifier];
			}
			[mutableIndexSet addIndex:resNumber];
		}
		[pool release];
	}
	[thread setIdDictionary:idDictionary];
	[thread setTripDictionary:tripDictionary];
    NSLog(@"processThread end");
}

-(NSString *)processedHTML:(NSString *)htmlString ofRes:(T2Res *)res inThread:(T2Thread *)thread {
	
	NSString *content = htmlString;
	NSMutableString *contentResult = [[NSMutableString alloc] init];
	NSScanner *contentScanner = [NSScanner scannerWithString:content];
	[contentScanner setCharactersToBeSkipped:_controlCharacterSet];
	NSString *scanedString;
	unsigned scanedLocation;
	NSRange scanedRange;
	BOOL scanned = YES;
	
	//scan ">, >>"
	while (![contentScanner isAtEnd]) {
		scanedLocation = [contentScanner scanLocation];
		if ([contentScanner scanString:__defaultResAnchorString intoString:&scanedString]) {
			
			unsigned i;
			for (i=0; i<2; i++) {
				if (![contentScanner scanString:__defaultResAnchorString intoString:NULL]) break;
			}
			
			if ([contentScanner scanCharactersFromSet:_digitAndSeparatorCharacterSet intoString:&scanedString]) {
				scanedString = [scanedString halfWidthString];
				if ([NSIndexSet shiftedIndexSetWithString:scanedString]) {
					scanedRange = NSMakeRange(scanedLocation,[contentScanner scanLocation]-scanedLocation);
					[contentResult appendString:[NSString stringWithFormat:__resLinkFormat,scanedString,[content substringWithRange:scanedRange]]];
				} else {
					scanedRange = NSMakeRange(scanedLocation,[contentScanner scanLocation]-scanedLocation);
					[contentResult appendString:[content substringWithRange:scanedRange]];
				}
			} else {
				scanedRange = NSMakeRange(scanedLocation,[contentScanner scanLocation]-scanedLocation);
				[contentResult appendString:[content substringWithRange:scanedRange]];
			}
			
		} else {
			[contentScanner scanUpToString:__defaultResAnchorString intoString:&scanedString];
			[contentResult appendString:scanedString];
		}
	}
	
	//scan other res anchor
	content = [[contentResult copy] autorelease];
	[contentResult release];
	contentResult = [[NSMutableString alloc] init];
	contentScanner = [NSScanner scannerWithString:content];
	[contentScanner setCharactersToBeSkipped:_controlCharacterSet];
	
	while (![contentScanner isAtEnd]) {
		scanedLocation = [contentScanner scanLocation];
		if ([contentScanner scanCharactersFromSet:_resAnchorCharacterSet intoString:NULL]) {
			if ([contentScanner scanCharactersFromSet:_digitAndSeparatorCharacterSet intoString:&scanedString]) {
				scanedString = [scanedString halfWidthString];
				if ([NSIndexSet shiftedIndexSetWithString:scanedString]) {
					scanedRange = NSMakeRange(scanedLocation,[contentScanner scanLocation]-scanedLocation);
					[contentResult appendString:[NSString stringWithFormat:__resLinkFormat,scanedString,[content substringWithRange:scanedRange]]];
				} else {
					scanedRange = NSMakeRange(scanedLocation,[contentScanner scanLocation]-scanedLocation);
					[contentResult appendString:[content substringWithRange:scanedRange]];
				}
			} else {
				scanedRange = NSMakeRange(scanedLocation,[contentScanner scanLocation]-scanedLocation);
				[contentResult appendString:[content substringWithRange:scanedRange]];
			}
		} else {
			[contentScanner scanUpToCharactersFromSet:_resAnchorCharacterSet intoString:&scanedString];
			[contentResult appendString:scanedString];
		}
	}
	
	// scan web links 
	content = [[contentResult copy] autorelease];
	[contentResult release];
	contentResult = [[NSMutableString alloc] init];
	
	NSArray *contentParts = [content componentsSeparatedByString:@">"];
	NSEnumerator *contentPartEnumerator = [contentParts objectEnumerator];
	NSString *contentPart;
	
	while (contentPart = [contentPartEnumerator nextObject]) {
		int tagIndex = [contentPart rangeOfString:@"<" options:NSLiteralSearch].location;
        // NSNotFound が64bitの-1になったのでうまくいかない
        NSLog(@"tagIndex = %d", tagIndex);
		if (tagIndex == -1/*NSNotFound*/ || tagIndex <= 3) {
			[contentResult appendString:contentPart];
			[contentResult appendString:@">"];
		} else {
			NSString *anteriorPart = [contentPart substringToIndex:tagIndex];
			NSString *posteriorPart = [contentPart substringFromIndex:tagIndex];
			NSScanner *anteriorScanner = [NSScanner scannerWithString:anteriorPart];
			[anteriorScanner setCharactersToBeSkipped:_controlCharacterSet];
			while (![anteriorScanner isAtEnd]) {
				
				scanedLocation = [anteriorScanner scanLocation];
				NSString *scanedString = nil;
				NSString *pseudoScheme;
				NSString *scheme;
				
				[anteriorScanner scanUpToString:@"://" intoString:&scanedString];
				if (scanedString) {
					unsigned scanedLocation2 = [anteriorScanner scanLocation];
					if ( [anteriorScanner scanString:@"://" intoString:NULL]) {
						if ([scanedString hasSuffix:@"http"] && (scanedLocation2-scanedLocation >= 4)) {
							scanedRange = NSMakeRange(scanedLocation,scanedLocation2-scanedLocation-4);
							if (scanedRange.length > 0) [contentResult appendString:[anteriorPart substringWithRange:scanedRange]];
							scheme = @"http";
							pseudoScheme = @"http";
						}
						else if ([scanedString hasSuffix:@"ttp"] && (scanedLocation2-scanedLocation >= 3)) {
							scanedRange = NSMakeRange(scanedLocation,scanedLocation2-scanedLocation-3);
							if (scanedRange.length > 0) [contentResult appendString:[anteriorPart substringWithRange:scanedRange]];
							scheme = @"http";
							pseudoScheme = @"ttp";
						}
						else if ([scanedString hasSuffix:@"https"] && (scanedLocation2-scanedLocation >= 5)) {
							scanedRange = NSMakeRange(scanedLocation,scanedLocation2-scanedLocation-5);
							if (scanedRange.length > 0) [contentResult appendString:[anteriorPart substringWithRange:scanedRange]];
							scheme = @"https";
							pseudoScheme = @"https";
						}
						else if ([scanedString hasSuffix:@"ttps"] && (scanedLocation2-scanedLocation >= 4)) {
							scanedRange = NSMakeRange(scanedLocation,scanedLocation2-scanedLocation-4);
							if (scanedRange.length > 0) [contentResult appendString:[anteriorPart substringWithRange:scanedRange]];
							scheme = @"https";
							pseudoScheme = @"ttps";
						}
						else if ([scanedString hasSuffix:@"ftp"] && (scanedLocation2-scanedLocation >= 3)) {
							scanedRange = NSMakeRange(scanedLocation,scanedLocation2-scanedLocation-3);
							if (scanedRange.length > 0) [contentResult appendString:[anteriorPart substringWithRange:scanedRange]];
							scheme = @"ftp";
							pseudoScheme = @"ftp";
						}
						else if ([scanedString hasSuffix:@"tp"] && (scanedLocation2-scanedLocation >= 2)) {
							scanedRange = NSMakeRange(scanedLocation,scanedLocation2-scanedLocation-2);
							if (scanedRange.length > 0) [contentResult appendString:[anteriorPart substringWithRange:scanedRange]];
							scheme = @"http";
							pseudoScheme = @"tp";
						}
						else if ([scanedString hasSuffix:@"feed"] && (scanedLocation2-scanedLocation >= 4)) {
							scanedRange = NSMakeRange(scanedLocation,scanedLocation2-scanedLocation-4);
							if (scanedRange.length > 0) [contentResult appendString:[anteriorPart substringWithRange:scanedRange]];
							scheme = @"feed";
							pseudoScheme = @"feed";
						}
						else if ([scanedString hasSuffix:@"file"] && (scanedLocation2-scanedLocation >= 4)) {
							scanedRange = NSMakeRange(scanedLocation,scanedLocation2-scanedLocation-4);
							if (scanedRange.length > 0) [contentResult appendString:[anteriorPart substringWithRange:scanedRange]];
							scheme = @"file";
							pseudoScheme = @"file";
						}
						else {
							[contentResult appendString:scanedString];
							[contentResult appendString:@"://"];
							scheme = nil;
							pseudoScheme = nil;
						}
						if (scheme) {
							if ( [anteriorScanner scanCharactersFromSet:_urlCharacterSet
															 intoString:&scanedString]) {
								NSString *URLString = scanedString;
								NSRange serverNameEnd = [URLString rangeOfString:@"/" options:NSLiteralSearch];
								NSMutableString *serverName;
								
								if (serverNameEnd.location != NSNotFound && serverNameEnd.location > 0)
									serverName = [[[URLString substringToIndex:serverNameEnd.location] mutableCopy] autorelease];
								else
									serverName = [[URLString mutableCopy] autorelease];
								[serverName replaceOccurrencesOfString:@"."
															withString:@"-"
															   options:NSLiteralSearch
																 range:NSMakeRange(0,[serverName length])];
								
								[contentResult appendString:
								 [NSString stringWithFormat:@"<a class=\"%@\" href=\"%@://%@\">%@://%@</a>",
								  serverName, scheme, URLString, pseudoScheme, URLString]];
							} else {
								[contentResult appendFormat:@"%@://", pseudoScheme];
							}
						}
					} 
					else {
						[contentResult appendString:scanedString];
						break;
					}
				} else {
					[contentResult appendString:anteriorPart];
					break;
				}
			}
			[contentResult appendString:posteriorPart];
			[contentResult appendString:@">"];
		}
	}
	[contentResult deleteCharactersInRange:NSMakeRange([contentResult length]-1,1)];
	
	content = [[contentResult copy] autorelease];
	[contentResult release];
	return content;
	
}

	
#pragma mark -
#pragma mark Protocol T2ResExtracting_v100
	-(NSArray *)extractKeys { return _extractKeys; }
	
	/*
	 @"allRes",
	 @"resNumber",
	 @"last",
	 @"newPlus",
	 @"trace",
	 @"traceOnce",
	 @"backtrace",
	 @"backtraceOnce",
	 @"identifier",
	 @"trip",
	 @"word",
	 @"style",
	 @"previewable",
	 */
	
	-(NSIndexSet *)extractResIndexesInThread:(T2Thread *)thread forKey:(NSString *)key path:(NSString *)path {
		//NSIndexSet *resIndexSet;
		switch ([_extractKeys indexOfObject:key]) {
				
			case 0: //automatic
				return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[thread resArray] count])];
			case 1: //allRes
				return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[thread resArray] count])];
				
			case 2: //resNumber
			{
				path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				return [NSIndexSet shiftedIndexSetWithString:path];
			}
				
			case 3: //last
			{
				unsigned resCount = [[thread resArray] count];
				unsigned resCount2 = [[NSIndexSet indexSetWithString:path] firstIndex];
				if (resCount > resCount2) {
					NSMutableIndexSet *resIndexSet2 = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(resCount-resCount2,resCount2)];
					[resIndexSet2 addIndex:0];
					return [[resIndexSet2 copy] autorelease];
				} else
					return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[thread resArray] count])];
			}
			case 4: //newPlus
			{
				unsigned resCount = [[thread resArray] count];
				unsigned resCount2 = [[NSIndexSet indexSetWithString:path] firstIndex];
				unsigned newResIndex = [thread newResIndex];
				if (newResIndex < resCount) resCount2 += resCount-newResIndex;
				if (resCount > resCount2) {
					NSMutableIndexSet *resIndexSet2 = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(resCount-resCount2,resCount2)];
					[resIndexSet2 addIndex:0];
					return [[resIndexSet2 copy] autorelease];
				} else
					return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[thread resArray] count])];
			}
			case 5: //trace
			{
				NSArray *pathComponents = [path pathComponents];
				if ([pathComponents count]>=3) {
					NSArray *subPathComponents = [pathComponents subarrayWithRange:NSMakeRange(1,[pathComponents count]-1)];
					NSIndexSet *resIndexSet = [[T2PluginManager sharedManager] extractResIndexesInThread:thread
																								 forPath:[NSString pathWithComponents:subPathComponents]];
					
					if (resIndexSet) {
						unsigned depth = [[pathComponents objectAtIndex:0] intValue];
						return [thread traceResIndexes:resIndexSet depth:depth];
					}
				} else return nil;
			}
			case 6: //traceOnce
			{
				NSIndexSet *resIndexSet = [NSIndexSet shiftedIndexSetWithString:path];
				if (resIndexSet) {
					return [thread traceResIndexes:resIndexSet depth:1];
				}
			}
			case 7: //backtrace
			{
				NSArray *pathComponents = [path pathComponents];
				if ([pathComponents count]>=3) {
					NSArray *subPathComponents = [pathComponents subarrayWithRange:NSMakeRange(1,[pathComponents count]-1)];
					NSIndexSet *resIndexSet = [[T2PluginManager sharedManager] extractResIndexesInThread:thread
																								 forPath:[NSString pathWithComponents:subPathComponents]];
					
					if (resIndexSet) {
						unsigned depth = [[pathComponents objectAtIndex:0] intValue];
						return [thread backtraceResIndexes:resIndexSet depth:depth];
					}
				} else return nil;
			}
			case 8: //backtraceOnce
			{
				NSIndexSet *resIndexSet = [NSIndexSet shiftedIndexSetWithString:path];
				if (resIndexSet) {
					return [thread backtraceResIndexes:resIndexSet depth:1];
				}
			}
			case 9: //identifier
			{
				return [[thread idDictionary] objectForKey:[path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			case 10: //trip
				return [[thread tripDictionary] objectForKey:[path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				
			case 11: //word
			{
				NSString *word = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSMutableIndexSet *mutableIndexSet = [NSMutableIndexSet indexSet];
				NSEnumerator *enumerator = [[thread resArray] objectEnumerator];
				T2Res *res;
				unsigned i=0;
				while (res = [enumerator nextObject]) {
					if ([[res name] rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound ||
						[[res mail] rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound ||
						[[res content] rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound) {
						[mutableIndexSet addIndex:i];
					}
					i++;
				}
				return [[mutableIndexSet copy] autorelease];
			}
			case 12: //style
			{
				NSString *style = [path firstPathComponent];
				NSMutableIndexSet *mutableIndexSet = [NSMutableIndexSet indexSet];
				NSEnumerator *enumerator = [[thread resArray] objectEnumerator];
				T2Res *res;
				unsigned i=0;
				while (res = [enumerator nextObject]) {
					NSArray *resHTMLClasses = [res HTMLClasses];
					if ([resHTMLClasses containsObject:style]) {
						[mutableIndexSet addIndex:i];
					}
					i++;
				}
				return [[mutableIndexSet copy] autorelease];
			}
			case 13: //previewable
			{
				T2PluginManager *pluginManager = [T2PluginManager sharedManager];
				NSString *prefix = @"ttp://";
				NSMutableIndexSet *mutableIndexSet = [NSMutableIndexSet indexSet];
				NSEnumerator *enumerator = [[thread resArray] objectEnumerator];
				T2Res *res;
				unsigned i=0;
				while (res = [enumerator nextObject]) {
					NSString *content = [res content];
					NSString *urlString = nil;
					NSScanner *contentScanner = [NSScanner scannerWithString:content];
					while (![contentScanner isAtEnd]) {
						if ([contentScanner scanString:prefix intoString:NULL]) {
							[contentScanner scanCharactersFromSet:_urlCharacterSet intoString:&urlString];
						} else {
							[contentScanner scanUpToString:prefix intoString:NULL];
							[contentScanner scanString:prefix intoString:NULL];
							[contentScanner scanCharactersFromSet:_urlCharacterSet intoString:&urlString];
						}
						if (urlString) {
							urlString = [@"http://" stringByAppendingString:urlString];
							if ([pluginManager isPreviewableURLString:urlString type:T2PreviewInline]) {
								[mutableIndexSet addIndex:i];
								break;
							}
						}
					}
					i++;
				}
				return [[mutableIndexSet copy] autorelease];
			}
			default:
				return nil;
		}
	}
	
	-(NSString *)localizedDescriptionForKey:(NSString *)key path:(NSString *)path {
		switch ([_extractKeys indexOfObject:key]) {
				
			case 0: //automatic
				return plugLocalizedString(@"Automatic");
			case 1: //allRes
				return plugLocalizedString(@"All Res");
			case 2: //resNumber
				return [NSString stringWithFormat:plugLocalizedString(@"%@"),path];
			case 3: //last
				return [NSString stringWithFormat:plugLocalizedString(@"Last %@ Res"),path];
			case 4: //newPlus
				return [NSString stringWithFormat:plugLocalizedString(@"Last %@ Res and New Res"),path];
			case 5: //trace
			{
				NSArray *pathComponents = [path pathComponents];
				if ([pathComponents count]>=3) {
					NSArray *subPathComponents = [pathComponents subarrayWithRange:NSMakeRange(1,[pathComponents count]-1)];
					NSString *subPath = [NSString pathWithComponents:subPathComponents];
					return [NSString stringWithFormat:plugLocalizedString(@"Responses to %@"),[[T2PluginManager sharedManager] localizedDescriptionOfExtractPath:subPath]];
				}
			}
			case 6: //traceOnce
				return [NSString stringWithFormat:plugLocalizedString(@"Responses to %@"),path];
			case 7: //backtrace
			{
				NSArray *pathComponents = [path pathComponents];
				if ([pathComponents count]>=3) {
					NSArray *subPathComponents = [pathComponents subarrayWithRange:NSMakeRange(1,[pathComponents count]-1)];
					NSString *subPath = [NSString pathWithComponents:subPathComponents];
					return [NSString stringWithFormat:plugLocalizedString(@"Backtrace from %@"),[[T2PluginManager sharedManager] localizedDescriptionOfExtractPath:subPath]];
				}
			}
			case 8: //backtraceOnce
				return [NSString stringWithFormat:plugLocalizedString(@"Backtrace from %@"),path];
			case 9: //identifier
				return [NSString stringWithFormat:plugLocalizedString(@"ID:%@"),[path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			case 10: //trip
				return [NSString stringWithFormat:plugLocalizedString(@"Trip:%@"),[path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			case 11: //word
				return [NSString stringWithFormat:plugLocalizedString(@"Word:%@"),[path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			case 12: //style
				return [NSString stringWithFormat:plugLocalizedString(@"Style:%@"),[path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			case 13: //previewable
				return plugLocalizedString(@"Previewable Res");
		}	
		return @"?";
	}
	
-(NSArray *)defaultExtractPaths {
		
		/*
		 @"allRes",
		 @"resNumber",
		 @"last",
		 @"newPlus",
		 @"trace",
		 @"traceOnce",
		 @"backtrace",
		 @"backtraceOnce",
		 @"identifier",
		 @"trip",
		 @"word",
		 @"style",
		 @"previewable",
		 */
		
		return [NSArray arrayWithObjects:
				@"automatic",
				@"allRes",
				@"newPlus/50",
				@"newPlus/100",
				@"newPlus/200",
				nil];
}
@end

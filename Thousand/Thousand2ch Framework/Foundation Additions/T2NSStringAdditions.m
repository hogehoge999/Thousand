//
//  T2NSStringAdditions.m
//  Thousand
//
//  Created by R. Natori on 05/06/19.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2NSStringAdditions.h"
#import "TEC.h"
#import "T2UtilityHeader.h"
#include <iconv.h>
#include <errno.h>

#define __iconvBufferLength 1024

//static NSString *__appSupportFolderPath = nil;
static NSString *__appName = nil;
static NSString *__appLogFolderName = nil;
static NSString *__ownAppSupportFolderPath = nil;
static NSString *__appLogFolderPath = nil;

//static NSString *__threadURLKey = @"/test/read.cgi/";
static NSString *__HTML4CharEntitiesFileName = @"HTML4CharEntities";
static NSDictionary *__HTML4CharEntities = nil;
static NSDictionary *__HTML4CharEntities_Reverse = nil;
static NSCharacterSet *__HTMLbreakingCharSet = nil;

static NSString *__URIReservedString = @" :/?#/[]@!$&'()*+,;=¥\\";
static NSCharacterSet *__URIReservedCharacterSet = nil;
static NSString *__unicodeLineSepartorString = nil;
static NSString *__unicodeParagraphSepartorString = nil;

static NSCharacterSet *__whitespaceAndNewlineCharacterSet = nil;

@implementation NSString (T2NSStringAdditions)

#pragma mark -
#pragma mark Factory Methods
+(NSString *)stringWithTimeInterval:(NSTimeInterval)timeInterval {
	NSAutoreleasePool *myPool = [[NSAutoreleasePool alloc] init];
	int timeItem[4]; unsigned i;
	timeItem[0] = timeInterval/(24*60*60);
	timeItem[1] = (timeInterval-timeItem[0]*(24*60*60))/(60*60);
	timeItem[2] = (timeInterval-timeItem[0]*(24*60*60)-timeItem[1]*(60*60))/60;
	timeItem[3] = (timeInterval-timeItem[0]*(24*60*60)-timeItem[1]*(60*60)-timeItem[2]*60);
	NSMutableArray *strings = [NSMutableArray array];
	for (i=0; i<4; i++) {
		if (timeItem[i] > 0 || i>=2)
			[strings addObject:[NSString stringWithFormat:@"%.2d",timeItem[i]]];
	}
	NSString *resultString = [[strings componentsJoinedByString:@":"] retain];
	[myPool release];
	return resultString;
}

+(NSString *)stringUsingTECwithData:(NSData *)data encoding:(NSStringEncoding)encoding {
	TECConverter* converter;
    converter = [[TECConverter alloc] initWithEncoding: encoding];
    
    NSString* content;
    content = [converter convertToString: data];
    
    [converter release];
	return content;
}
+(NSString *)stringWithData:(NSData *)data iconvEncoding:(NSString *)encodingString {
    int err = 0;
	iconv_t descriptor = iconv_open("UTF-16//IGNORE", [encodingString UTF8String]);
	size_t inbytesleft = [data length];
	char* inbuf = (char*)[data bytes];

	size_t outbytesleft = __iconvBufferLength;

	char* outbuf = malloc(__iconvBufferLength);
	char* outbytes = NULL;
	NSMutableString *resultString = [NSMutableString string];
	err = E2BIG;
	
	while (err == E2BIG) {
		outbytes = outbuf;
		errno = 0;
		iconv(descriptor, &inbuf, &inbytesleft, &outbytes, &outbytesleft);
        err = errno;
		if (err == EILSEQ || err == EINVAL)
            break;
		NSString *part = [[[NSString alloc] initWithBytes:outbuf
												   length:__iconvBufferLength-outbytesleft
												 encoding:NSUnicodeStringEncoding] autorelease];
		[resultString appendString:part];
		outbytesleft = __iconvBufferLength;
	}
    if (err != 0)
    {
        NSLog(@"errno = %d" ,err);
    }
    if (inbytesleft > 0)
    {
        NSLog(@"end! inbytesleft = %ld", inbytesleft);
    }
	iconv_close(descriptor);
	free(outbuf);
	
	return resultString;
}

+(NSString *)stringUsingIconvWithData:(NSData *)data encoding:(NSStringEncoding)encoding {
	CFStringEncoding cfEncoding= CFStringConvertNSStringEncodingToEncoding(encoding);
	CFStringRef cfEncodingString = CFStringConvertEncodingToIANACharSetName(cfEncoding);
	if (!cfEncodingString) return nil;
	return [NSString stringWithData:data iconvEncoding:(NSString *)cfEncodingString];
}

#pragma mark -
#pragma mark Replace Utility

-(NSString *)stringByReplacingFirstOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts {
	NSRange targetRange = [self rangeOfString:target options:opts];
	if (targetRange.location == NSNotFound) return self;
	
	NSString *preString;
	if (targetRange.location == 0)
		preString = @"";
	else
		preString = [self substringToIndex:targetRange.location];
	
	NSString *postString;
	if (targetRange.location == [self length])
		postString = @"";
	else
		postString = [self substringFromIndex:targetRange.location+targetRange.length];
	
	return [NSString stringWithFormat:@"%@%@%@", preString, replacement, postString];
}

-(NSString *)stringByTrimmingInvalidWhiteCharactersBeforeLineBreaks {
	if (!__whitespaceAndNewlineCharacterSet) {
		__whitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
	}
	
	NSArray *components = [self componentsSeparatedByString:@"\n"];
	if ([components count] == 0) return self;
	NSEnumerator *componentEnumerator = [components objectEnumerator];
	NSMutableArray *newComponents = [NSMutableArray array];
	NSString *component;
	while (component = [componentEnumerator nextObject]) {
		if ([component length] > 0) {
			unichar tempUnichar = [component characterAtIndex:[component length]-1];
			if ([__whitespaceAndNewlineCharacterSet characterIsMember:tempUnichar]) {
				component = [component substringToIndex:[component length]-1];
			}
		}
		[newComponents addObject:component];
	}
	return [newComponents componentsJoinedByString:@"\n"];
}




#pragma mark -
#pragma mark Escape and Encoding Utility

-(NSString *)stringFromHTML {
	NSString* src = self;
	int tempLoc, tempLoc2;
	if (!src) return nil;
	NSMutableString *tempString = [[[NSMutableString alloc] initWithString:src] autorelease];
	//<br> to return
	[tempString replaceOccurrencesOfString:@"<br>" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[tempString length])];
	
	//cut other tags
	tempLoc = [tempString rangeOfString:@"<" options:NSLiteralSearch].location;
	while (tempLoc != -1/*NSNotFound*/) {
		tempLoc2 = [tempString rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(tempLoc, [tempString length]-tempLoc)].location;
		if ((tempLoc2 == -1/*NSNotFound*/) || (tempLoc > tempLoc2)) break;
		[tempString deleteCharactersInRange:NSMakeRange(tempLoc, (tempLoc2-tempLoc+1))];
		tempLoc = [tempString rangeOfString:@"<" options:NSLiteralSearch].location;
	}
	
	return [tempString stringByReplacingCharacterReferences];
}
-(NSString *)stringByAddingHTMLEscapes {
	NSMutableString *mutableString = [[self mutableCopy] autorelease];
	[mutableString replaceOccurrencesOfString:@"&"
								   withString:@"&amp;"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [mutableString length])];
	[mutableString replaceOccurrencesOfString:@"<"
								   withString:@"&lt;"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [mutableString length])];
	[mutableString replaceOccurrencesOfString:@">"
								   withString:@"&gt;"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [mutableString length])];
	[mutableString replaceOccurrencesOfString:@"\""
								   withString:@"&quot;"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [mutableString length])];
	[mutableString replaceOccurrencesOfString:@"'"
								   withString:@"&apos;"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [mutableString length])];
	return [[mutableString copy] autorelease];
}

-(NSString *)stringByReplacingCharacterReferences {
	if (!__HTMLbreakingCharSet && !__HTML4CharEntities) {
		[T2HTML4CharEntitiesLoader loadHTML4CharEntities];
		__HTMLbreakingCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"&;\n<"] retain];
	}
	
	NSMutableString *resultString = [[[NSMutableString alloc] init] autorelease];
	NSScanner *srcScanner = [NSScanner scannerWithString:self];
	[srcScanner setCharactersToBeSkipped:[NSCharacterSet illegalCharacterSet]];
	//NSScanner *partScanner;
	NSString *escapeString;
	//NSNumber *originalNumber;
	long long anInt;
	NSAutoreleasePool *myPool;
	while (![srcScanner isAtEnd]) {
		myPool = [[NSAutoreleasePool alloc] init];
		
		if (![srcScanner scanString:@"&" intoString:NULL]) {
			if ([srcScanner scanUpToString:@"&" intoString:&escapeString]) {
				[resultString appendString:escapeString];
			}
			[srcScanner scanString:@"&" intoString:NULL];
		}
		if ([srcScanner scanUpToCharactersFromSet:__HTMLbreakingCharSet intoString:&escapeString] && escapeString) {
			if ([escapeString length]>10) {
				[resultString appendFormat:@"&%@",escapeString];
			}
			else {
				NSScanner *escapeStringScanner = [NSScanner scannerWithString:escapeString];
				anInt = 0;
				if ([escapeStringScanner scanString:@"#" intoString:NULL]) {  // Numeric Reference
					if ([escapeStringScanner scanString:@"x" intoString:NULL]) {
						unsigned aHexInt1 = 0;
						unsigned aHexInt2 = 0;
						unsigned length = [escapeString length];
						if (length >= 7)  { // #x10000 : 7
							NSString *temp1 = [escapeString substringToIndex:length-4];
							NSScanner *temp1Scanner = [NSScanner scannerWithString:temp1];
							[temp1Scanner scanString:@"#x" intoString:NULL];
							[temp1Scanner scanHexInt:&aHexInt2];
							
							[escapeStringScanner setScanLocation:length-4];
						}
						if ([escapeStringScanner scanHexInt:&aHexInt1]) {
							anInt = ((long long)aHexInt2 << 16) | aHexInt1;
						}
					} else {
						[escapeStringScanner scanLongLong:&anInt];
					}
					
					if (anInt >= 0x10000) {
						anInt -= 0x10000;
						unichar char1 = (anInt >> 10) | 0xD800;
						unichar char2 = (anInt & 0x3FF) | 0xDC00;
						[resultString appendFormat:@"%C%C",char1, char2];
					} else if (anInt > 0){
						[resultString appendFormat:@"%C",(unichar)anInt];
					}
					
				} else {  // Charactor Reference
					NSString *resultCharString = [__HTML4CharEntities objectForKey:escapeString];
					if (resultCharString) {
						[resultString appendString:resultCharString];
					} else {
						[resultString appendFormat:@"&%@",escapeString];
					}
				}
				[srcScanner scanString:@";" intoString:NULL];
			}
		}
		[myPool release];
	}
	if ([resultString length] >0) return [[resultString copy] autorelease];
	else return self;
}


-(NSString *)stringByAddingCharacterReferencesForEncoding:(NSStringEncoding)encoding {
	
	if (!__HTML4CharEntities_Reverse)
		[T2HTML4CharEntitiesLoader loadHTML4CharEntities_Reverse];
	
	NSMutableString *resultString = [NSMutableString string];
	NSMutableArray *parts= [NSMutableArray arrayWithObject:self];
	unsigned i=0;
	while (i<[parts count]) {
		NSString *part = [parts objectAtIndex:i];
		NSData *data = [part dataUsingEncoding:encoding];
		if (data && [data length] > 0) {
			[resultString appendString:part];
			i++;
		} else {
			unsigned length = [part length];
			if (length == 0) {
				i++;
			} else if (length == 1) {
				NSString *characterReference = [__HTML4CharEntities_Reverse objectForKey:part];
				if (characterReference) {
					[resultString appendFormat:@"&%@;", characterReference];
				} else {
					unichar character = [part characterAtIndex:0];
					[resultString appendFormat:@"&#%d;", character];
				}
				i++;
			} else if (length == 2) {
				unichar high = [part characterAtIndex:0];
				unichar low = [part characterAtIndex:1];
				if (high >= 0xD800 && high <= 0xDBFF && low >= 0xDC00 && low <= 0xDFFF) {
					UInt32 character = (((high & 0x3FF) << 10) | (low & 0x3FF)) + 0x10000;
					[resultString appendFormat:@"&#%d;", character];
					i++;
				} else {
					NSString *string1 = [part substringToIndex:1];
					NSString *string2 = [part substringFromIndex:1];
					[parts removeObjectAtIndex:i];
					[parts insertObject:string1 atIndex:i];
					[parts insertObject:string2 atIndex:i+1];
				}
			} else {
				unsigned location = length / 2;
				NSString *string1 = [part substringToIndex:location];
				NSString *string2 = [part substringFromIndex:location];
				[parts removeObjectAtIndex:i];
				[parts insertObject:string1 atIndex:i];
				[parts insertObject:string2 atIndex:i+1];
			}
		}
	}
	return [[resultString copy] autorelease];
}

-(NSString *)stringByAddingNumericCharacterReferencesForEncoding:(NSStringEncoding)encoding {
	NSMutableString *resultString = [NSMutableString string];
	NSMutableArray *parts= [NSMutableArray arrayWithObject:self];
	unsigned i=0;
	while (i<[parts count]) {
		NSString *part = [parts objectAtIndex:i];
		NSData *data = [part dataUsingEncoding:encoding];
		if (data && [data length] > 0) {
			[resultString appendString:part];
			i++;
		} else {
			unsigned length = [part length];
			if (length == 0) {
				i++;
			} else if (length == 1) {
				unichar character = [part characterAtIndex:0];
				NSString *numericCharacterReference = [NSString stringWithFormat:@"&#%d;", character];
				[resultString appendString:numericCharacterReference];
				i++;
			} else if (length == 2) {
				unichar high = [part characterAtIndex:0];
				unichar low = [part characterAtIndex:1];
				if (high >= 0xD800 && high <= 0xDBFF && low >= 0xDC00 && low <= 0xDFFF) {
					UInt32 character = (((high & 0x3FF) << 10) | (low & 0x3FF)) + 0x10000;
					NSString *numericCharacterReference = [NSString stringWithFormat:@"&#%d;", character];
					[resultString appendString:numericCharacterReference];
					i++;
				} else {
					NSString *string1 = [part substringToIndex:1];
					NSString *string2 = [part substringFromIndex:1];
					[parts removeObjectAtIndex:i];
					[parts insertObject:string1 atIndex:i];
					[parts insertObject:string2 atIndex:i+1];
				}
			} else {
				unsigned location = length / 2;
				NSString *string1 = [part substringToIndex:location];
				NSString *string2 = [part substringFromIndex:location];
				[parts removeObjectAtIndex:i];
				[parts insertObject:string1 atIndex:i];
				[parts insertObject:string2 atIndex:i+1];
			}
		}
	}
	return [[resultString copy] autorelease];
}

-(NSString *)stringByAddingUTF8PercentEscapesForce {
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes (NULL,
																 (CFStringRef)self,
																 NULL,
																 (CFStringRef)__URIReservedString,
																 kCFStringEncodingUTF8) autorelease];
}
-(NSString *)stringByAddingSJISPercentEscapesForce {
	NSString *string = [self precomposedStringWithCanonicalMapping];
	string = [string stringByAddingCharacterReferencesForEncoding:NSShiftJISStringEncoding];
	return [string stringByAddingPercentEscapes_T2_UsingEncoding:NSShiftJISStringEncoding];
}
-(NSString *)stringByAddingPercentEscapes_T2_UsingEncoding:(NSStringEncoding)encoding {
	// init
	NSString *string = self;
	if (!__unicodeLineSepartorString) {
		unichar unicodeLineSeparator = 0x2028;
		unichar unicodeParagraphSeparator = 0x2029;
		__unicodeLineSepartorString = [[NSString stringWithCharacters:&unicodeLineSeparator length:1] retain];
		__unicodeParagraphSepartorString = [[NSString stringWithCharacters:&unicodeParagraphSeparator length:1] retain];
		__URIReservedCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:__URIReservedString] retain];
	}
	
	// replace unicode line separator
	NSMutableString *resultString = [[string mutableCopy] autorelease];
	[resultString replaceOccurrencesOfString:__unicodeLineSepartorString
								  withString:@"\n"
									 options:0
									   range:NSMakeRange(0,[resultString length])];
	[resultString replaceOccurrencesOfString:__unicodeParagraphSepartorString
								  withString:@"\n"
									 options:0
									   range:NSMakeRange(0,[resultString length])];
	
	// escape
	string = [resultString stringByAddingPercentEscapesUsingEncoding:encoding];
	
	// escape 2
	CFStringEncoding cfencoding = CFStringConvertNSStringEncodingToEncoding(encoding);
	NSScanner *scanner = [NSScanner scannerWithString:string];
	resultString = [NSMutableString string];
	while (![scanner isAtEnd]) {
		NSString *scannedString = nil;
		if ([scanner scanCharactersFromSet:__URIReservedCharacterSet intoString:&scannedString]) {
			if (scannedString) {
				scannedString = [(NSString *)CFURLCreateStringByAddingPercentEscapes (NULL,
																				  (CFStringRef)scannedString,
																				  NULL,
																				  (CFStringRef)__URIReservedString,
																				  cfencoding) autorelease];
				[resultString appendString:scannedString];
			}
		}
		else if ([scanner scanUpToCharactersFromSet:__URIReservedCharacterSet intoString:&scannedString]) {
			if (scannedString) {
				[resultString appendString:scannedString];
			}
			
		}
	}
	return [[resultString copy] autorelease];
}
-(NSString *)stringByReplacingPercentEscapes_T2_UsingEncoding:(NSStringEncoding)encoding {
	return [(NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
															NULL,
															(CFStringRef)self,
															(CFStringRef)@"",
															CFStringConvertNSStringEncodingToEncoding(encoding)
															  ) autorelease];
}

-(NSData *)dataByTECUsingEncoding:(NSStringEncoding)encoding {
	NSString *precomposedStringWithCanonicalMapping = [self precomposedStringWithCanonicalMapping];
	TECConverter *converter = [[[TECConverter alloc] initWithEncoding:NSUnicodeStringEncoding to:encoding] autorelease];
	NSData *unicodeStringData = [precomposedStringWithCanonicalMapping dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES];
	return [converter convert:unicodeStringData];
}

#pragma mark -
#pragma mark Transform Utility
-(NSString *)stringAppliedCFTransform:(CFStringRef)transform reverse:(BOOL)reverse {
	CFMutableStringRef cfMutableString = CFStringCreateMutableCopy(NULL, [self length], (CFStringRef)self);
	CFStringTransform(cfMutableString, NULL, transform, reverse);
	NSString *result = [[(NSString *)cfMutableString copy] autorelease];
	CFRelease(cfMutableString);
	return result;
}
-(NSString *)halfWidthString {
	CFMutableStringRef cfMutableString = CFStringCreateMutableCopy(NULL, [self length], (CFStringRef)self);
	CFStringTransform(cfMutableString, NULL, kCFStringTransformFullwidthHalfwidth, NO);
	NSString *result = [[(NSString *)cfMutableString copy] autorelease];
	CFRelease(cfMutableString);
	return result;
}
-(NSString *)fullWidthString {
	CFMutableStringRef cfMutableString = CFStringCreateMutableCopy(NULL, [self length], (CFStringRef)self);
	CFStringTransform(cfMutableString, NULL, kCFStringTransformFullwidthHalfwidth, YES);
	NSString *result = [[(NSString *)cfMutableString copy] autorelease];
	CFRelease(cfMutableString);
	return result;
}

#pragma mark -
#pragma mark Range Utility
-(NSRange)rangeOfLastString:(NSString *)aString options:(unsigned)mask {
	unsigned length = [self length];
	unsigned nextLoaction;
	NSRange foundRange = [self rangeOfString:aString options:mask];
	NSRange resultRange = foundRange;
	while (foundRange.location != NSNotFound) {
		resultRange = foundRange;
		nextLoaction = foundRange.location + foundRange.length;
		if (length-nextLoaction == 0) break;
		foundRange = [self rangeOfString:aString
								 options:mask
								   range:(NSRange){nextLoaction, length-nextLoaction}];
	}
	return resultRange;
}

-(NSString *)substringBetweenPrefix:(NSString *)prefix andPostfix:(NSString *)postfix {
	NSRange prefixRange = [self rangeOfString:prefix];
	NSRange postfixRange = [self rangeOfString:postfix];
	if (prefixRange.location == NSNotFound ||
		postfixRange.location == NSNotFound ||
		prefixRange.location + prefixRange.length >= postfixRange.location)
		return nil;
	return [self substringWithRange:NSMakeRange(prefixRange.location + prefixRange.length,
												postfixRange.location - (prefixRange.location + prefixRange.length) )];
}

#pragma mark -
#pragma mark Distance Utility
-(unsigned)distanceFromString:(NSString *)anotherString {
	unsigned length1 = [self length];
	unsigned length2 = [anotherString length];
	if (length1 == 0 && length2 > 0) return length2;
	if (length2 == 0 && length1 > 0) return length1;
	if (length1 > 1024 || length2 > 1024) return NSNotFound;
	
	unichar *chars1 = malloc((length1+1)*sizeof(unichar));
	unichar *chars2 = malloc((length2+1)*sizeof(unichar));
	[self getCharacters:chars1];
	[anotherString getCharacters:chars2];
	
	
	unsigned *table2 = malloc((length1+1)*(length2+1)*sizeof(unsigned));
	unsigned **table = malloc((length1+1)*sizeof(unsigned));
	unsigned i1,i2,cost,minimum,insert,deletion,replace,result;
	
	for (i1=0; i1<=length1; i1++) {
		table[i1] = table2 + (length2+1)*i1;
		table[i1][0] = i1;
	}
	for (i2=0; i2<=length2; i2++) {
		table[0][i2] = i2;
	}
	
	for (i1=1; i1<=length1; i1++) {
		for (i2=1; i2<=length2; i2++) {
			if (chars1[i1-1] == chars2[i2-1])
				cost = 0;
			else
				cost = 1;
			
			insert = table[i1-1][i2]+1;
			deletion = table[i1][i2-1]+1;
			replace = table[i1-1][i2-1]+cost;
			
			minimum = insert;
			if (minimum > deletion) minimum = deletion;
			if (minimum > replace) minimum = replace;
			
			table[i1][i2] = minimum;
		}
	}
	result = table[length1][length2];
	free(chars1);
	free(chars2);
	free(table);
	free(table2);
	
	return result;
}

#pragma mark -
#pragma mark file path utility
-(NSString *)stringByResolvingAliasesInPath {  // Resolve aliases in path string.
											   // this code was taken from ADC document.
	NSString *path = self;  // Assume this exists.
	NSString *resolvedPath = nil;
	CFURLRef url;
	url = CFURLCreateWithFileSystemPath(NULL /*allocator*/, (CFStringRef)path,
										kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	
	if(url != NULL) {
		FSRef fsRef;
		if(CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/,
				&targetIsFolder, &wasAliased) == noErr && wasAliased)
{
				CFURLRef resolvedUrl = CFURLCreateFromFSRef(NULL, &fsRef);
				if(resolvedUrl != NULL) {
					resolvedPath = (NSString*)
					CFURLCopyFileSystemPath(resolvedUrl,
											kCFURLPOSIXPathStyle);
					CFRelease(resolvedUrl);
				}
}
		}
CFRelease(url);
	}
if (resolvedPath==nil) return path;
else return [resolvedPath autorelease];
}

-(NSString *)stringByDeletingfirstPathComponent {
	NSArray *pathComponents = [self pathComponents];
	unsigned maxCount = [pathComponents count];
	if (maxCount <= 1) return [NSString string];
	pathComponents = [pathComponents subarrayWithRange:(NSRange){1, maxCount-1}];
	return [NSString pathWithComponents:pathComponents];
}
-(NSString *)firstPathComponent {
	NSArray *pathComponents = [self pathComponents];
	unsigned maxCount = [pathComponents count];
	if (maxCount == 0) return self;
	else return [pathComponents objectAtIndex:0];
}
-(NSString *)pathComponentAtIndex:(int)index {
	NSArray *pathComponents = [self pathComponents];
	unsigned maxCount = [pathComponents count];
	if (maxCount == 0) return self;
	if (index >= 0) {
		if (index >= maxCount) index = maxCount - 1;
		return [pathComponents objectAtIndex:index];
	} else {
		if (-1*index > maxCount) return [pathComponents objectAtIndex:0];
		return [pathComponents objectAtIndex:(maxCount+index)];
	}
}

-(NSString *)stringByReplacingReservedCharacters {
	NSMutableString *resultString = [NSMutableString string];
	NSScanner *scanner = [NSScanner scannerWithString:self];
	NSCharacterSet *reservedCharSet = [NSCharacterSet characterSetWithCharactersInString:@":/\\*?\"<>|"];
	NSString *scannedString = nil;
	while (![scanner isAtEnd]) {
		if ([scanner scanCharactersFromSet:reservedCharSet intoString:&scannedString]) {
			[resultString appendString:@"_"];
		}
		if ([scanner scanUpToCharactersFromSet:reservedCharSet intoString:&scannedString]) {
			[resultString appendString:scannedString];
		}
	}
	return [[resultString copy] autorelease];
}

#pragma mark -
+(void)setClassAppName:(NSString *)appName {
	[appName retain];
	[__appName release];
	__appName = appName;
}
+(NSString *)appName {
	if (__appName)
		return __appName;
	NSBundle *appBundle = [NSBundle mainBundle];
	NSString *appName = [[appBundle executablePath] lastPathComponent];
	[self setClassAppName:appName];
	return appName;
}
+(void)setClassAppLogFolderName:(NSString *)appLogFolderName {
	[appLogFolderName retain];
	[__appLogFolderName release];
	__appLogFolderName = appLogFolderName;
}

+(NSString *)userLibraryFolderPath {
	NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES);
	return [libraryPaths objectAtIndex:0];
}

+(NSString *)appSupportFolderPath {
	NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES);
	NSString *libraryPath = [libraryPaths objectAtIndex:0];
	return [libraryPath stringByAppendingPathComponent:@"Application Support"];
}
+(NSString *)ownAppSupportFolderPath {
	if (!__ownAppSupportFolderPath && __appName) {
		__ownAppSupportFolderPath = [[[[NSString appSupportFolderPath] stringByAppendingPathComponent:__appName] stringByResolvingAliasesInPath] retain];
	}
	return __ownAppSupportFolderPath;
}
+(void)setAppLogFolderPath:(NSString *)path {
	if (!path || [path isEqualToString:__appLogFolderPath]) return;
	
	[[path stringByAppendingPathComponent:@"__dummy__"] prepareFoldersInPath];
	
	if (__appLogFolderPath) {
		[path prepareFoldersInPath];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *oldContents = [fileManager directoryContentsAtPath:__appLogFolderPath];
		
		NSEnumerator *enumerator = [oldContents objectEnumerator];
		NSString *fileName;
		while (fileName = [enumerator nextObject]) {
			NSString *oldFilePath = [__appLogFolderPath stringByAppendingPathComponent:fileName];
			NSString *newFilePath = [path stringByAppendingPathComponent:fileName];
			if (![fileManager fileExistsAtPath:newFilePath]) {
				[fileManager movePath:oldFilePath toPath:newFilePath handler:NULL];
			}
		}
	}
	id tempObject = __appLogFolderPath;
	__appLogFolderPath = [path retain];
	[tempObject release];
}
+(NSString *)appLogFolderPath {
	if (!__appLogFolderPath && __appName && __appLogFolderName) {
		__appLogFolderPath = [[[[NSString ownAppSupportFolderPath] stringByAppendingPathComponent:__appLogFolderName] stringByResolvingAliasesInPath] retain];
	}
	return __appLogFolderPath;
}
+(NSString *)userDesktopFolderPath {
	
	return [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
}
+(NSString *)userDownloadsFolderPath {
	return [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
}


#pragma mark -
-(BOOL)isExistentPath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [fileManager fileExistsAtPath:self];
}
-(BOOL)prepareFoldersInPath {
	if ([self hasPrefix:@"~"]) return NO;
	NSString *lastFolderPath = [self stringByDeletingLastPathComponent];
	BOOL isDirectory;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:lastFolderPath isDirectory:&isDirectory] && isDirectory) {
		return YES;
	} else {
		NSString *andLastFolderPath = [lastFolderPath stringByDeletingLastPathComponent];
		if ([fileManager fileExistsAtPath:andLastFolderPath isDirectory:&isDirectory] && isDirectory) {
			if ([fileManager createDirectoryAtPath:lastFolderPath attributes:nil]) {
				return YES;
			} else return NO;
		} else return [lastFolderPath prepareFoldersInPath];
	}
}
-(BOOL)recycleFileAtPath {
	if (![self isExistentPath]) return NO;
	NSString *folderPath = [self stringByDeletingLastPathComponent];
	return [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
														   source:folderPath
													  destination:folderPath
															files:[NSArray arrayWithObject:[self lastPathComponent]]
															  tag:NULL];
}

#pragma mark Deprecated
+(NSString *)stringUsingTECwith2chData:(NSData *)data encoding:(NSStringEncoding)encoding {
	return [self stringUsingTECwithData:data encoding:encoding];
}
+(NSString *)stringWithData:(NSData *)data IANAencodingName:(NSString *)encodingName {
	return [[[NSString alloc] initWithData:data
								  encoding:CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName))]
			autorelease];
}

+(NSString *)stringWith2chData:(NSData *)data IANAencodingName:(NSString *)encodingName orCocoaEncoding:(NSStringEncoding)encoding {
	if (encodingName) {
		encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName));
	}
	if (encoding == 0) encoding = NSShiftJISStringEncoding;
	
	TECConverter* converter;
    converter = [[TECConverter alloc] initWithEncoding: encoding];
    
    NSString* content;
    content = [converter convertToString: data];
    
    [converter release];
	return content;
}

-(NSString *)stringByReplacingAmpersandEscapes {
	return [self stringByReplacingCharacterReferences];
}

@end

@implementation T2HTML4CharEntitiesLoader
+(void)loadHTML4CharEntities {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:__HTML4CharEntitiesFileName ofType:@"plist"];
	if (path) {
		NSData *data = [NSData dataWithContentsOfFile:path];
		NSDictionary *HTML4CharEntities = [NSPropertyListSerialization propertyListFromData:data
																		   mutabilityOption:NSPropertyListImmutable
																					 format:NULL
																		   errorDescription:NULL];
		
		if (HTML4CharEntities) {
			setObjectWithRetain(__HTML4CharEntities, HTML4CharEntities);
			return;
		}
	}
	setObjectWithRetain(__HTML4CharEntities, [NSDictionary dictionary]);
}
+(void)loadHTML4CharEntities_Reverse {
	if (__HTML4CharEntities_Reverse) return;
	if (!__HTML4CharEntities) return;
	
	NSMutableDictionary *reslutDictionary = [NSMutableDictionary dictionaryWithCapacity:[__HTML4CharEntities count]];
	NSArray *keys = [__HTML4CharEntities allKeys];
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *key;
	while (key = [keyEnumerator nextObject]) {
		NSString *object = [__HTML4CharEntities objectForKey:key];
		[reslutDictionary setObject:key forKey:object];
	}
	
	setObjectWithCopy(__HTML4CharEntities_Reverse, reslutDictionary);
}
@end

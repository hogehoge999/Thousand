//
//  T2NSStringAdditions.m
//  Thousand
//
//  Created by R. Natori on 05/06/19.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2NSStringAdditions.h"
#include <iconv.h>
#include <errno.h>

#define __iconvBufferLength 1024
//#import "TEC.h"

/*
//static NSString *__appSupportFolderPath = nil;
static NSString *__appName = nil;
static NSString *__appLogFolderName = nil;
static NSString *__ownAppSupportFolderPath = nil;
static NSString *__appLogFolderPath = nil;

//static NSString *__threadURLKey = @"/test/read.cgi/";
static NSString *__HTMLCharEntitiesFileName = @"HTMLCharEntities";
static NSDictionary *__HTMLCharEntitiesDic = nil;
static NSCharacterSet *__HTMLbreakingCharSet = nil;

static NSString *__URIReservedString = @" :/?#/[]@!$&'()*+,;=¥\\";
static NSCharacterSet *__URIReservedCharacterSet = nil;
static NSString *__unicodeLineSepartorString = nil;
static NSString *__unicodeParagraphSepartorString = nil;

static NSCharacterSet *__whitespaceAndNewlineCharacterSet = nil;
 */

@implementation NSString (T2NSStringAdditions)

+(NSString *)stringWithData:(NSData *)data iconvEncoding:(NSString *)encodingString {
	iconv_t descriptor = iconv_open("UTF-16//IGNORE", [encodingString UTF8String]);
	size_t inbytesleft = [data length];
	const char* inbuf = (char*)[data bytes];
	
	size_t outbytesleft;
	char* outbuf = malloc(__iconvBufferLength);
	char* outbyteslength = NULL;
	NSMutableString *resultString = [NSMutableString string];
	errno = E2BIG;
	
	while (errno == E2BIG) {
		outbytesleft = __iconvBufferLength;
		outbyteslength = outbuf;
		errno = 0;
		iconv(descriptor, &inbuf, &inbytesleft, &outbyteslength, &outbytesleft);
		if (errno == EILSEQ || errno == EINVAL) break;
		NSString *part = [[[NSString alloc] initWithBytes:outbuf
												   length:__iconvBufferLength-outbytesleft
												 encoding:NSUnicodeStringEncoding] autorelease];
		[resultString appendString:part];
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
/*
+(NSString *)stringUsingTECwith2chData:(NSData *)data encoding:(NSStringEncoding)encoding {
	TECConverter* converter;
    converter = [[TECConverter alloc] initWithEncoding: encoding];
    
    NSString* content;
    content = [converter convertToString: data];
    
    [converter release];
	return content;
}
 */

/*
-(NSString *)stringByReplacingAmpersandEscapes {
	if (!__HTMLCharEntitiesDic) {
		__HTMLCharEntitiesDic = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:__HTMLCharEntitiesFileName ofType:@"plist"]];
		__HTMLbreakingCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"&;\n<"] retain];
	}
	
	NSMutableString *resultString = [[[NSMutableString alloc] init] autorelease];
	NSScanner *srcScanner = [NSScanner scannerWithString:self];
	NSScanner *partScanner;
	NSString *escapeString;
	NSNumber *originalNumber;
	unsigned anInt;
	NSAutoreleasePool *myPool;
	while (![srcScanner isAtEnd]) {
		myPool = [[NSAutoreleasePool alloc] init];
		
		if ([srcScanner scanUpToString:@"&" intoString:&escapeString])
			[resultString appendString:escapeString];
		[srcScanner scanString:@"&" intoString:NULL];
		if ([srcScanner scanUpToCharactersFromSet:__HTMLbreakingCharSet intoString:&escapeString]) {
			if ([escapeString length]>10)
				[resultString appendFormat:@"&%@",escapeString];
			else {
				anInt = 0;
				if (![escapeString hasPrefix:@"#"]) {
					originalNumber = [__HTMLCharEntitiesDic objectForKey:escapeString];
					anInt = [originalNumber intValue];
				} else {
					if ([escapeString hasPrefix:@"#x"]) {
						escapeString = [NSString stringWithFormat:@"0x%@",[escapeString substringFromIndex:2]];
						partScanner = [NSScanner scannerWithString:escapeString];
						[partScanner scanHexInt:&anInt];
					}
					else anInt = [[escapeString substringFromIndex:1] intValue];
				}
				if (anInt) {
					[resultString appendFormat:@"%C",(unichar)anInt];
					[srcScanner scanString:@";" intoString:NULL];
				}
			}
		}
		
		[myPool release];
	}
	if ([resultString length] >0) return resultString;
	else return self;
}
*/
-(NSString *)stringFromHTML {
	NSString* src = self;
	unsigned tempLoc, tempLoc2;
	if (!src) return nil;
	NSMutableString *tempString = [[[NSMutableString alloc] initWithString:src] autorelease];
	//<br> to return
	[tempString replaceOccurrencesOfString:@"<br>" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[tempString length])];
	//<> to space
	[tempString replaceOccurrencesOfString:@"<>" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[tempString length])];
	
	//cut other tags
	tempLoc = [tempString rangeOfString:@"<" options:NSLiteralSearch].location;
	while (tempLoc != NSNotFound) {
		tempLoc2 = [tempString rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(tempLoc, [tempString length]-tempLoc)].location;
		if ((tempLoc2 == NSNotFound) || (tempLoc > tempLoc2)) break;
		[tempString deleteCharactersInRange:NSMakeRange(tempLoc, (tempLoc2-tempLoc+1))];
		tempLoc = [tempString rangeOfString:@"<" options:NSLiteralSearch].location;
	}
	
	return tempString;
}

-(NSString *)stringByReplacingPercentEscapes_T2_UsingEncoding:(NSStringEncoding)encoding {
	return [(NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
															NULL,
															(CFStringRef)self,
															(CFStringRef)@"",
															CFStringConvertNSStringEncodingToEncoding(encoding)
															  ) autorelease];
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
-(BOOL)isExistentPath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [fileManager fileExistsAtPath:self];
}
@end


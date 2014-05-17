//
//  T2NSStringAdditions.h
//  Thousand
//
//  Created by R. Natori on 05/06/19.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (T2NSStringAdditions)

#pragma mark -
#pragma mark Factory Methods
+(NSString *)stringWithTimeInterval:(NSTimeInterval)timeInterval ;
+(NSString *)stringUsingTECwithData:(NSData *)data encoding:(NSStringEncoding)encoding ;
+(NSString *)stringWithData:(NSData *)data iconvEncoding:(NSString *)encodingString ;
+(NSString *)stringUsingIconvWithData:(NSData *)data encoding:(NSStringEncoding)encoding ;

#pragma mark -
#pragma mark Replace Utility
-(NSString *)stringByReplacingFirstOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts ;
-(NSString *)stringByTrimmingInvalidWhiteCharactersBeforeLineBreaks ;

#pragma mark -
#pragma mark Escape and Encoding Utility
-(NSString *)stringFromHTML ;
-(NSString *)stringByAddingHTMLEscapes ;
-(NSString *)stringByReplacingCharacterReferences ;
-(NSString *)stringByAddingCharacterReferencesForEncoding:(NSStringEncoding)encoding ;
-(NSString *)stringByAddingNumericCharacterReferencesForEncoding:(NSStringEncoding)encoding ;

-(NSString *)stringByAddingUTF8PercentEscapesForce ;
-(NSString *)stringByAddingSJISPercentEscapesForce ;
-(NSString *)stringByAddingPercentEscapes_T2_UsingEncoding:(NSStringEncoding)encoding ;
-(NSString *)stringByReplacingPercentEscapes_T2_UsingEncoding:(NSStringEncoding)encoding ;
-(NSData *)dataByTECUsingEncoding:(NSStringEncoding)encoding ;

#pragma mark -
#pragma mark Transform Utility
-(NSString *)stringAppliedCFTransform:(CFStringRef)transform reverse:(BOOL)reverse ;
-(NSString *)halfWidthString ;
-(NSString *)fullWidthString ;

#pragma mark -
#pragma mark Range Utility
-(NSRange)rangeOfLastString:(NSString *)aString options:(unsigned)mask ;
-(NSString *)substringBetweenPrefix:(NSString *)prefix andPostfix:(NSString *)postfix ;

#pragma mark -
#pragma mark Distance Utility
-(NSUInteger)distanceFromString:(NSString *)anotherString ;

#pragma mark -
#pragma mark file path utility
-(NSString *)stringByResolvingAliasesInPath ;
-(NSString *)stringByDeletingfirstPathComponent ;
-(NSString *)firstPathComponent ;
-(NSString *)pathComponentAtIndex:(int)index ;
-(NSString *)stringByReplacingReservedCharacters ;

+(void)setClassAppName:(NSString *)appName ;
+(NSString *)appName ;
+(void)setClassAppLogFolderName:(NSString *)appLogFolderName ;
+(NSString *)userLibraryFolderPath ;
+(NSString *)appSupportFolderPath ;
+(NSString *)ownAppSupportFolderPath ;
+(void)setAppLogFolderPath:(NSString *)path ;
+(NSString *)appLogFolderPath ;
+(NSString *)userDesktopFolderPath ;
+(NSString *)userDownloadsFolderPath ;

-(BOOL)isExistentPath ;
-(BOOL)prepareFoldersInPath ;
-(BOOL)recycleFileAtPath;

#pragma mark deprecated
// +(NSString *)stringUsingTECwith2chData:(NSData *)data encoding:(NSStringEncoding)encoding ;
// +(NSString *)stringWithData:(NSData *)data IANAencodingName:(NSString *)encodingName ;
// +(NSString *)stringWith2chData:(NSData *)data IANAencodingName:(NSString *)encodingName orCocoaEncoding:(NSStringEncoding)encoding;
	/* Use stringUsingTECwithData:encoding: instead. */

// -(NSString *)stringByReplacingAmpersandEscapes ;
	/* Use stringByReplacingCharacterReferences instead. */
@end

@interface T2HTML4CharEntitiesLoader : NSObject
{
}
+(void)loadHTML4CharEntities ;
+(void)loadHTML4CharEntities_Reverse ;
@end


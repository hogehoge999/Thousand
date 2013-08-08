#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#import <Foundation/Foundation.h>
#import "T2NSDataAdditions.h"
#import "T2NSStringAdditions.h"

#define releasePoolAndReturnResult ({[pool release]; return result;})

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
	Boolean result = FALSE;
	
	NSMutableDictionary *attributesDictionary = (NSMutableDictionary *)attributes;
	NSString *filePath = (NSString *)pathToFile;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	NSData *plistData = [NSData dataWithContentsOfFile:filePath];
	if (!plistData) releasePoolAndReturnResult;
	
	NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:plistData
																mutabilityOption:NSPropertyListImmutable
																		  format:NULL
																errorDescription:NULL];
	
	NSDictionary *threadFace = [dictionary objectForKey:@"threadFace"];
	
	// Thread Title
	NSString *title = [threadFace objectForKey:@"title"];
	if (!title) title = [dictionary objectForKey:@"title"];
	if (title) {
		[attributesDictionary setObject:@"Thousand" forKey:(id)kMDItemCreator];
		[attributesDictionary setObject:title forKey:(id)kMDItemDisplayName];
		[attributesDictionary setObject:title forKey:(id)kMDItemTitle];
		result = TRUE;
	} else {
		result = FALSE;
	}
	
	// Language
	[attributesDictionary setObject:[NSArray arrayWithObject:@"ja"] forKey:(id)kMDItemLanguages];
	
	// Res Count
	NSNumber *resCount = [threadFace objectForKey:@"resCount"];
	if (resCount) {
		[attributesDictionary setObject:resCount
								 forKey:@"jp_natori_Thousand_thread_resCount"];
	}
	// Res Count New
	NSNumber *resCountNew = [threadFace objectForKey:@"resCountNew"];
	if (resCountNew) {
		[attributesDictionary setObject:resCountNew
								 forKey:@"jp_natori_Thousand_thread_resCountNew"];
	}
	
	// Label
	NSNumber *label = [threadFace objectForKey:@"label"];
	if (label) {
		[attributesDictionary setObject:label
								 forKey:@"jp_natori_Thousand_thread_label"];
	}
	
	// State
	NSNumber *state = [threadFace objectForKey:@"state"];
	if (state) {
		[attributesDictionary setObject:state
								 forKey:@"jp_natori_Thousand_thread_state"];
	}
	
	// Created Date
	NSDate *createdDate = [threadFace objectForKey:@"createdDate"];
	if (createdDate) {
		[attributesDictionary setObject:createdDate
								 forKey:@"jp_natori_Thousand_thread_createdDate"];
	}
	
	// Modified Date
	NSDate *modifiedDate = [threadFace objectForKey:@"modifiedDate"];
	if (modifiedDate) {
		[attributesDictionary setObject:modifiedDate
								 forKey:@"jp_natori_Thousand_thread_modifiedDate"];
	}
	
	// Board Title
	
	NSString *threadListTitle = [dictionary objectForKey:@"threadListTitle"];
	if (threadListTitle) {
		[attributesDictionary setObject:threadListTitle
								 forKey:@"jp_natori_Thousand_thread_listTitle"];
	}
	
	
	// Internal Path
	NSString *internalPath = [dictionary objectForKey:@"internalPath"];
	if (!internalPath) releasePoolAndReturnResult;
	
	[attributesDictionary setObject:internalPath
							 forKey:@"jp_natori_Thousand_thread_threadInternalPath"];
	
	
	[attributesDictionary setObject:[internalPath stringByDeletingLastPathComponent]
									 forKey:@"jp_natori_Thousand_thread_listInternalPath"];
	 
	
		
	
	// Text Content
	NSString *internalPathExtension = [internalPath pathExtension];
	if (!internalPathExtension || [internalPathExtension length] == 0) {
		if ([[internalPath firstPathComponent] isEqualToString:@"TownBBS"]) {
			internalPathExtension = @"html";
		} else {
			releasePoolAndReturnResult;
		}
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *logFilePath = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:internalPathExtension];
	if (![fileManager fileExistsAtPath:logFilePath]) {
		if (![fileManager fileExistsAtPath:[logFilePath stringByAppendingPathExtension:@"gz"]]) releasePoolAndReturnResult;
	}
	
	NSString *content = nil;
	
	if ([internalPathExtension isEqualToString:@"dat"]) { // 2ch dat
		NSData *data = [NSData dataWithContentsOfGZipFile:logFilePath];
		if (!data) releasePoolAndReturnResult;
		content = [NSString stringUsingIconvWithData:data encoding:NSShiftJISStringEncoding];
		//content = [NSString stringUsingTECwith2chData:data encoding:NSShiftJISStringEncoding];
		content = [content stringFromHTML];
		
	}
	else if ([internalPathExtension isEqualToString:@"jbbsdat"]) { // JBBS dat
		NSData *data = [NSData dataWithContentsOfGZipFile:logFilePath];
		if (!data) releasePoolAndReturnResult;
		
		content = [NSString stringUsingIconvWithData:data encoding:NSJapaneseEUCStringEncoding];
		//content = [NSString stringUsingTECwith2chData:data encoding:NSJapaneseEUCStringEncoding];
		content = [content stringFromHTML];
	}
	else if ([internalPathExtension isEqualToString:@"html"]) { // html
		NSData *data = [NSData dataWithContentsOfGZipFile:logFilePath];
		if (!data) releasePoolAndReturnResult;
		
		if ([[internalPath firstPathComponent] isEqualToString:@"TownBBS"]) {
			content = [NSString stringUsingIconvWithData:data encoding:NSShiftJISStringEncoding];
			//content = [NSString stringUsingTECwith2chData:data encoding:NSShiftJISStringEncoding];
			content = [content stringFromHTML];
		}
	}
	if (!content) releasePoolAndReturnResult;
	
	NSBundle *selfBundle = [NSBundle bundleWithIdentifier:@"jp.natori.ThousandMDImporter"];
	NSString *LAServerNGWordsPath = [selfBundle pathForResource:@"LAServerNGWords"
														 ofType:@"plist"];
	if (!LAServerNGWordsPath) releasePoolAndReturnResult;
	NSData *LAServerNGWordsData = [NSData dataWithContentsOfFile:LAServerNGWordsPath];
	NSArray *LAServerNGWords = [NSPropertyListSerialization propertyListFromData:LAServerNGWordsData
																mutabilityOption:NSPropertyListImmutable
																		  format:NULL
																errorDescription:NULL];
	
	if (LAServerNGWordsData && LAServerNGWords) {
		NSMutableString *mutableContent = [content mutableCopy];
		NSEnumerator *LAServerNGWordEnumerator = [LAServerNGWords objectEnumerator];
		NSString *NGWord;
		while (NGWord = [LAServerNGWordEnumerator nextObject]) {
			[mutableContent replaceOccurrencesOfString:NGWord
											withString:@" "
											   options:NSCaseInsensitiveSearch
												 range:NSMakeRange(0, [mutableContent length])];
		}
		
		content = [[mutableContent copy] autorelease];
		[mutableContent release];
	}
	
	[attributesDictionary setObject:content forKey:(id)kMDItemTextContent];
	
	[pool release];
	return TRUE;
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    
	// #warning To complete your importer please implement the function GetMetadataForFile in GetMetadataForFile.c
    //return FALSE;
}

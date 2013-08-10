//
//  T2ResourceManager.m
//  Thousand
//
//  Created by R. Natori on 06/06/01.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2ResourceManager.h"
#import "T2UtilityHeader.h"


static T2ResourceManager 	*__sharedManager 	= nil;

@implementation T2ResourceManager

+(T2ResourceManager *)sharedManager {
	if (!__sharedManager) {
		__sharedManager = [[self alloc] init];
	}
	return __sharedManager;
}

-(id)init {
	self = [super init];
	if (!__sharedManager) {
		__sharedManager = self;
		
		_resourceFolderPaths = [[NSMutableArray alloc] init];
		_cssStyles = [[NSMutableArray alloc] init];
		_cssStyleNames = [[NSMutableDictionary alloc] init];
		
		return self;
	}
	if (self != __sharedManager) [self autorelease];
	return __sharedManager;
}

-(void)dealloc {
	[_resourceFolderPaths release];
	[_cssPaths release];
	[_cssPathsLinkString release];
	
	[_cssStyles release];
	[_cssStyleNames release];
	[_skinNames release];
	[_skinFilePath release];
	[_iconSetNames release];
	[_icons release];
	[super dealloc];
}

-(void)addResourceFolderPaths:(NSString *)path {
	[_resourceFolderPaths addObject:path];
}
-(NSArray *)resourceFolderPaths {
	return _resourceFolderPaths;
}

-(NSArray *)pathsForSubFolderName:(NSString *)subFolderName {
	NSMutableArray *resultPaths = [NSMutableArray array];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSEnumerator *resourceFolderPathsEnumerator = [_resourceFolderPaths objectEnumerator];
	NSString *resourceFolderPath;
	while (resourceFolderPath = [resourceFolderPathsEnumerator nextObject]) {
		NSString *subPath = [resourceFolderPath stringByAppendingPathComponent:subFolderName];
		BOOL isDirectory;
		if ([fileManager fileExistsAtPath:subPath isDirectory:&isDirectory] && isDirectory) {
			[resultPaths addObject:subPath];
		}
	}
	return resultPaths;
}
-(NSArray *)filesInSubFolderName:(NSString *)subFolderName {
	NSMutableArray *resultPaths = [NSMutableArray array];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSEnumerator *resourceFolderPathsEnumerator = [_resourceFolderPaths objectEnumerator];
	NSString *resourceFolderPath;
	while (resourceFolderPath = [resourceFolderPathsEnumerator nextObject]) {
		NSString *subPath = [resourceFolderPath stringByAppendingPathComponent:subFolderName];
		BOOL isDirectory;
		if ([fileManager fileExistsAtPath:subPath isDirectory:&isDirectory] && isDirectory) {
			NSArray *subPathContents = [fileManager directoryContentsAtPath:subPath];
			NSEnumerator *subPathContentsEnumerator = [subPathContents objectEnumerator];
			NSString *subPathContent;
			while (subPathContent = [subPathContentsEnumerator nextObject]) {
				[resultPaths addObject:[subPath stringByAppendingPathComponent:subPathContent]];
			}
		}
	}
	return resultPaths;
}
-(NSArray *)filesOfType:(NSString *)type inSubFolderName:(NSString *)subFolderName {
	return [[self filesInSubFolderName:subFolderName] pathsMatchingExtensions:[NSArray arrayWithObject:type]];
}

-(NSDictionary *)fileDicionaryOfType:(NSString *)type inSubFolderName:(NSString *)subFolderName {
	NSArray *filePaths = [self filesOfType:type inSubFolderName:subFolderName];
	NSEnumerator *filePathEnumerator = [filePaths objectEnumerator];
	NSString *filePath;
	NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
	while (filePath = [filePathEnumerator nextObject]) {
		[resultDic setObject:filePath
					  forKey:[[filePath lastPathComponent] stringByDeletingPathExtension]];
	}
	return resultDic;
}
#pragma mark -
-(void)loadCSS {
	[_cssPaths release];
	_cssPaths = [[self filesOfType:@"css" inSubFolderName:@"CSS"] retain];
	NSMutableArray *resultArray = [NSMutableArray array];
	NSEnumerator *cssPathEnumerator = [_cssPaths objectEnumerator];
	NSString *cssPath;
	while (cssPath = [cssPathEnumerator nextObject]) {
		[resultArray addObject:
			[NSString stringWithFormat:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"%@\">",
				[[NSURL fileURLWithPath:cssPath] absoluteString]]];
		[self loadStylesFromCSS:cssPath];
	}
	NSString *resultString = [resultArray componentsJoinedByString:@"\n"];
	[_cssPathsLinkString release];
	_cssPathsLinkString = [resultString retain];
}
-(NSArray *)CSSPaths {
	return _cssPaths;
}
-(NSString *)CSSPathsLinkString {
	return _cssPathsLinkString;
}
-(void)loadStylesFromCSS:(NSString *)path {
	if (![path isExistentPath]) return;
	NSString *srcString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	NSString *srcString2;
	//NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSScanner *srcScanner = [NSScanner scannerWithString:srcString];
	if ([srcScanner scanUpToString:@"THOUSAND_STYLE_DEFINITION {" intoString:NULL] &&
		[srcScanner scanString:@"THOUSAND_STYLE_DEFINITION {" intoString:NULL] &&
		[srcScanner scanUpToString:@"}" intoString:&srcString2] ) {
		NSScanner *srcScanner2 = [NSScanner scannerWithString:srcString2];
		
		NSString *style;
		NSString *styleName;
		while (
			   [srcScanner2 scanUpToString:@":" intoString:&style] &&
			   [srcScanner2 scanString:@":" intoString:NULL] &&
			   [srcScanner2 scanUpToString:@";" intoString:&styleName] &&
			   [srcScanner2 scanString:@";" intoString:NULL]) {
			//[srcScanner2 scanCharactersFromSet:whitespaceAndNewlineCharacterSet intoString:NULL];
			
			[_cssStyles addObject:style];
			[_cssStyleNames setObject:styleName forKey:style];
		}
		
	}
}
-(NSString *)nameOfStyle:(NSString *)style {
	return [_cssStyleNames objectForKey:style];
}
-(NSArray *)styleMenuItemsForTarget:(id)target action:(SEL)action {
	NSEnumerator *styleEnumerator = [_cssStyles objectEnumerator];
	NSMutableArray *menuItems = [NSMutableArray array];
	NSString *style;
	while (style = [styleEnumerator nextObject]) {
		NSString *title = [_cssStyleNames objectForKey:style];
		if (!title) title = style;
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:title
														   action:action
													keyEquivalent:@""] autorelease];
		[menuItem setTarget:target];
		[menuItem setRepresentedObject:style];
		[menuItems addObject:menuItem];
	}
	return menuItems;
}

#pragma mark -
#pragma mark SKin
-(void)loadSkinNamed:(NSString *)aString {
	NSDictionary *skinPathDic = [self fileDicionaryOfType:@"html" inSubFolderName:@"Skins"];
	setObjectWithCopy(_skinNames, [skinPathDic allKeys]);
	setObjectWithCopy(_skinFilePath, [skinPathDic objectForKey:aString]);
	if (!_skinFilePath && [skinPathDic count]>0) {
		setObjectWithCopy(_skinFilePath, [[skinPathDic allValues] objectAtIndex:0]);
	} else {
		NSLog(@"No skin files found!");
	}
}
-(NSArray *)skinNames {
	if (!_skinNames) [self loadSkinNamed:@"Standard"];
	return _skinNames;
}
-(NSString *)skinFilePath {
	if (!_skinFilePath) [self loadSkinNamed:@"Standard"];
	return _skinFilePath;
}
-(NSString *)skinFileContent {
	if (!_skinFilePath) [self loadSkinNamed:@"Standard"];
	if (_skinFilePath)
		return [[[NSString alloc] initWithContentsOfFile:_skinFilePath encoding:NSUTF8StringEncoding error:nil] autorelease];
	return nil;
}

#pragma mark -
#pragma mark Icon Set
-(void)loadIconSetNamed:(NSString *)aString {
	[_icons release];
	_icons = nil;
	
	NSMutableDictionary *iconSetFolderDic = [NSMutableDictionary dictionary];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *iconSetSuperFolderPaths = [self pathsForSubFolderName:@"Icons"];
	NSEnumerator *iconSetSuperFolderPathEnumerator = [iconSetSuperFolderPaths objectEnumerator];
	NSString *iconSetSuperFolderPath;
	while (iconSetSuperFolderPath = [iconSetSuperFolderPathEnumerator nextObject]) {
		NSArray *iconSetFolderPaths = [fileManager directoryContentsAtPath:iconSetSuperFolderPath];
		NSEnumerator *iconSetFolderPathEnumerator = [iconSetFolderPaths objectEnumerator];
		NSString *iconSetFolderPath;
		while (iconSetFolderPath = [iconSetFolderPathEnumerator nextObject]) {
			BOOL isDirectory;
			NSString *iconSetSuperFolderFullPath = [iconSetSuperFolderPath stringByAppendingPathComponent:iconSetFolderPath];
			if ([fileManager fileExistsAtPath:iconSetSuperFolderFullPath isDirectory:&isDirectory]
				&& isDirectory) {
				[iconSetFolderDic setObject:iconSetSuperFolderFullPath forKey:iconSetFolderPath];
			}
		}
	}
	if ([iconSetFolderDic count]>0) {
		//_iconSetDictionary = [iconSetFolderDic copy];
		_iconSetNames = [[[iconSetFolderDic allKeys] arrayByAddingObject:@"Standard"] retain];
		if (aString) {
			NSString *iconSetFolder = [iconSetFolderDic objectForKey:aString];
			if (iconSetFolder) {
				NSArray *iconFiles = [[fileManager directoryContentsAtPath:iconSetFolder]
					pathsMatchingExtensions:[NSImage imageUnfilteredFileTypes]];
				NSEnumerator *iconFileEnumerator = [iconFiles objectEnumerator];
				NSString *iconFile;
				NSMutableArray *tempIcons = [NSMutableArray arrayWithCapacity:[iconFiles count]];
				while (iconFile = [iconFileEnumerator nextObject]) {
					NSImage *icon = [[NSImage alloc] initByReferencingFile:[iconSetFolder stringByAppendingPathComponent:iconFile]];
					[icon setName:[[iconFile lastPathComponent] stringByDeletingPathExtension]];
					[tempIcons addObject:icon];
					[icon release];
				}
				
				if ([tempIcons count] >0) {
					_icons = [tempIcons copy];
				}
			}
		}
	}
}	
-(NSArray *)iconSetNames {
	if (!_iconSetNames) [self loadIconSetNamed:@"Standard"];
	return _iconSetNames;
}
@end

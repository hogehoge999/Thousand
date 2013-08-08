//
//  THSelfClashLogImporter.m
//  Thousand
//
//  Created by R. Natori on 06/11/18.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "THSelfClashLogImporter.h"

static NSString *__uniqueName = @"jp_natori_Thousand_SelfCrashLogImporter";
static NSString *__rootPath = @"ThousandCrashLog";
//static NSString *__importableType = @"log";
static NSString *__crashLogFolderPath = @"~/Library/Logs/CrashReporter";

@implementation THSelfClashLogImporter
#pragma mark protocol T2PluginInterface
+(NSArray *)pluginInstances { return [NSArray arrayWithObject:[[[self alloc] init] autorelease]]; }
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName); }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]); }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderMiddle; }
-(NSArray *)uniqueNamesOfdependingPlugins { return nil; }


#pragma mark T2ThreadImporting
	// 新たな形式のスレッドを読み込むプラグインの実装すべきプロトコル
-(NSString *)importableRootPath {
	return __rootPath;
}
-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace {
	NSString *internalPath = [threadFace internalPath];
	if (![internalPath hasPrefix:__rootPath]) return nil;
	NSString *logFileName = @"Thousand.crash.log";
	NSString *logFilePath = [[__crashLogFolderPath stringByExpandingTildeInPath] stringByAppendingPathComponent:logFileName];
	
	NSData *srcData = [NSData dataWithContentsOfFile:logFilePath];
	NSString *src = [[[NSString alloc] initWithData:srcData encoding:NSUTF8StringEncoding] autorelease];
	if (!src) return nil;
	
	NSArray *srcArray = [src componentsSeparatedByString:@"**********"];
	NSEnumerator *srcComponentEnumerator = [srcArray objectEnumerator];
	NSString *srcComponent = [srcComponentEnumerator nextObject];
	unsigned resNumber = 1;
	NSMutableArray *resArray = [NSMutableArray array];
	
	NSDate *date = [NSDate date];
	
	T2Thread *thread = [T2Thread threadWithThreadFace:threadFace resArray:nil];
	NSAutoreleasePool *pool;
	while (srcComponent = [srcComponentEnumerator nextObject]) {
		pool = [[NSAutoreleasePool alloc] init];
		
		NSScanner *scanner = [NSScanner scannerWithString:srcComponent];
		NSMutableString *resContent = [NSMutableString string];
		NSString *partString = nil;
		[scanner scanUpToString:@"Date/Time:" intoString:NULL];
		[scanner scanUpToString:@"Exception:" intoString:&partString];
		if (partString) [resContent appendString:partString];
		[scanner scanUpToString:@"Binary Images Description:" intoString:&partString];
		if (partString) [resContent appendString:partString];
		
		[resContent replaceOccurrencesOfString:@"\n"
									withString:@"<br>"
									   options:NSLiteralSearch
										 range:NSMakeRange(0,[resContent length])];
		
		T2Res *res = [T2Res resWithResNumber:resNumber++
										name:@"--"
										mail:@""
										date:date
								  identifier:nil
									 content:resContent
									  thread:thread]; // Thousandのバグで、dateがまったくないと変な動作をする
		[resArray addObject:res];
		
		[pool release];
	}
	T2Res *res = [T2Res resWithResNumber:resNumber++
									name:THStandardPlugLocalizedString(@"AuthorName")
									mail:@""
									date:date
							  identifier:nil
								 content:THStandardPlugLocalizedString(@"SendMeClashLog")
								  thread:thread]
	[thread setResArray:resArray];
	[thread setNewResIndex:[resArray count]-1];
	return thread;
}

@end

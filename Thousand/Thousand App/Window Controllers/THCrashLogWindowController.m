//
//  THCrashLogWindowController.m
//  Thousand
//
//  Created by R. Natori on 08/06/15.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "THCrashLogWindowController.h"

static THCrashLogWindowController *__sharedCrashLogWindowController;

@implementation THCrashLogWindowController
+(id)sharedCrashLogWindowController {
	if (!__sharedCrashLogWindowController)
		__sharedCrashLogWindowController = [[self alloc] initCrashLogWindowController];
	return __sharedCrashLogWindowController;
}

-(id)initCrashLogWindowController {
	
	if (__sharedCrashLogWindowController) {
		[self autorelease];
		return __sharedCrashLogWindowController;
	}
	self = [super initWithWindowNibName:@"THCrashLogWindow"];
	return self;
}
-(oneway void)release {
}

-(void)windowDidLoad {
	if (_result) return;
	
	NSString *crashLogFolder = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
								 stringByAppendingPathComponent:@"Logs"]
								stringByAppendingPathComponent:@"CrashReporter"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory = YES;
	if (![fileManager fileExistsAtPath:crashLogFolder isDirectory:&isDirectory])
		return;
	if (!isDirectory)
		return;
	
	// Find the last crashlog
	NSString *lastCrashLog = nil;
	
	unsigned lastNumber = 0;
	NSDate  *lastdate = [NSDate dateWithTimeIntervalSince1970:0];
	BOOL useLeopardSuffix = NO;
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
		if (MacVersion >= 0x1050){
			useLeopardSuffix = YES;
		}
	}
	NSString *thousandVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	
	
	NSArray *crashLogs = [fileManager directoryContentsAtPath:crashLogFolder];
	NSEnumerator *crashLogEnumerator = [crashLogs objectEnumerator];
	NSString *crashLog;
	
	while (crashLog = [crashLogEnumerator nextObject]) {
		if ([crashLog hasPrefix:@"Thousand"]) {
			NSScanner *scanner = [NSScanner scannerWithString:crashLog];
			[scanner scanString:@"Thousand" intoString:NULL];
			
			if (useLeopardSuffix) {
				[scanner scanString:@"_" intoString:NULL];
				NSString *calendarDateString = nil;
				[scanner scanUpToString:@"_" intoString:&calendarDateString];
				if (calendarDateString) {
					NSCalendarDate *calendarDate = [[[NSCalendarDate alloc] initWithString:calendarDateString
																			calendarFormat:@"%Y-%m-%d-%H%M%S"] autorelease];
					if (calendarDate) {
						if ([calendarDate timeIntervalSinceDate:lastdate] > 0) {
							lastCrashLog = crashLog;
							lastdate = calendarDate;
						}
					}
				}
			} else {
				if ([scanner scanString:@"-" intoString:NULL]) {
					int logNumber = 0;
					[scanner scanInt:&logNumber];
					if (logNumber > lastNumber) {
						lastCrashLog = crashLog;
						lastNumber = logNumber;
					}
				} else {
					lastCrashLog = crashLog;
					lastNumber = 0;
				}
			}
		}
	}
	
	if (!lastCrashLog)
		return;
	
	lastCrashLog = [crashLogFolder stringByAppendingPathComponent:lastCrashLog];
	_crashLogFilePath = [lastCrashLog copy];
	
	// Read crashlog
	NSData *contentData = [NSData dataWithContentsOfFile:lastCrashLog];
	NSString *content = [[[NSString alloc] initWithData:contentData
											   encoding:NSUTF8StringEncoding] autorelease];
	if (!content)
		return;
	content = [[content componentsSeparatedByString:@"**********"] lastObject];
	
	NSScanner *contentScanner = [NSScanner scannerWithString:content];
	NSString *OSVersion, *appVersion, *exception;
	
	[contentScanner scanUpToString:@"OS Version:" intoString:NULL];
	[contentScanner scanString:@"OS Version:" intoString:NULL];
	[contentScanner scanUpToString:@"\n" intoString:&OSVersion];
	
	[contentScanner setScanLocation:0];
	
	[contentScanner scanUpToString:@"\nVersion:" intoString:NULL];
	[contentScanner scanString:@"Version:" intoString:NULL];
	[contentScanner scanUpToString:@"\n" intoString:&appVersion];
	
	if (thousandVersion && appVersion) {
		if ([appVersion rangeOfString:thousandVersion].location == NSNotFound) {
			return;
		}
	}
	
	[contentScanner scanUpToString:@"Exception" intoString:NULL];
	[contentScanner scanString:@"Exception" intoString:NULL];
	[contentScanner scanUpToString:@":" intoString:NULL];
	[contentScanner scanString:@":" intoString:NULL];
	[contentScanner scanUpToString:@"\n" intoString:&exception];
	
	[contentScanner scanUpToString:@"Thread" intoString:NULL];
	[contentScanner scanString:@"Thread" intoString:NULL];
	[contentScanner scanUpToString:@"Crashed:\n" intoString:NULL];
	[contentScanner scanString:@"Crashed:\n" intoString:NULL];
	
	NSMutableString *trace = [NSMutableString string];
	NSString *cause = nil;
	NSString *line;
	while (![contentScanner isAtEnd]) {
		[contentScanner scanUpToString:@"\n" intoString:&line];
		if (line) {
			if ([line rangeOfString:@"0x" options:NSLiteralSearch].location == NSNotFound) {
				break;
			}
			[trace appendString:@"\n"];
			[trace appendString:line];
			if ([line rangeOfString:@"[TH" options:NSLiteralSearch].location != NSNotFound
				|| [line rangeOfString:@"[T2" options:NSLiteralSearch].location != NSNotFound) {
				NSLocalizedString(@"Thousand Bug", @"Crash");
				break;
			}
		}
	}
	if (!cause) {
		if ([trace rangeOfString:@"WebCore"].location != NSNotFound) {
			cause = NSLocalizedString(@"WebView Crash (Style?)", @"Crash");
		}
		else if ([trace rangeOfString:@"NSBind"].location != NSNotFound) {
			cause = NSLocalizedString(@"Binding Problem", @"Crash");
		}
		else if ([trace rangeOfString:@"AutoreleasePool"].location != NSNotFound) {
			cause = NSLocalizedString(@"Autorelease Crash (PopUp?)", @"Crash");
		}
		else {
			cause = NSLocalizedString(@"Undefined", @"Crash");
		}
	}
	
	// Get plugin info
	NSMutableArray *pluginNames = [NSMutableArray array];
	NSArray *allPlugins = [[T2PluginManager sharedManager] allPlugins];
	NSEnumerator *pluginEnumerator = [allPlugins objectEnumerator];
	NSObject <T2PluginInterface_v100> *plugin;
	
	while (plugin = [pluginEnumerator nextObject]) {
		if ([plugin pluginType] != T2EmbeddedPlugin) {
			[pluginNames addObject:[plugin localizedName]];
		}
	}
	
	NSString *pluginNamesString = [pluginNames componentsJoinedByString:@", "];
	
	// Get skin info
	NSString *skinName = nil;
	NSObject <T2ThreadPartialHTMLExporting_v100> *viewPlugin = [[T2PluginManager sharedManager] partialHTMLExporterPlugin];
	if ([viewPlugin respondsToSelector:@selector(templateName)]) {
		skinName = [viewPlugin performSelector:@selector(templateName)];
	}
	
	// Write result
	NSMutableString *result = [NSMutableString string];
	[result appendFormat:NSLocalizedString(@"Mac OS X Version: %@\n", @"Crash"), OSVersion];
	[result appendFormat:NSLocalizedString(@"Thousand Version: %@\n", @"Crash"), appVersion];
	[result appendFormat:NSLocalizedString(@"External Plugins: %@\n", @"Crash"), pluginNamesString];
	[result appendFormat:NSLocalizedString(@"Skin: %@\n", @"Crash"), skinName];
	
	[result appendString:@"\n"];
	
	[result appendFormat:NSLocalizedString(@"Exception: %@\n", @"Crash"), exception];
	[result appendFormat:NSLocalizedString(@"Cause: %@\n", @"Crash"), cause];
	
	[result appendString:@"\n"];
	
	[result appendFormat:NSLocalizedString(@"Stack Trace (mini): \n%@", @"Crash"), trace];
	[result appendString:@"\n"];
	
	_result = [result copy];
	
	if (_result && _textView) {
		[_textView setString:_result];
	}
	
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}

-(IBAction)revealCrashLogFileInFinder:(id)sender {
	if (!_crashLogFilePath) return;
	NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
	[sharedWorkspace selectFile:_crashLogFilePath
	   inFileViewerRootedAtPath:[_crashLogFilePath stringByDeletingLastPathComponent]];
}

-(IBAction)createMailForReporting:(id)sender {
	if (!_result) return;
	
	NSString *result = [_result stringByAppendingString:NSLocalizedString(@"\nPlease describe the circumstances leading to the crash and any other relevant information:\n", @"Crash")];
	NSString *urlString = [NSString stringWithFormat:
						   @"mailto:%@?subject=%@&body=%@",
						   @"thousand_natori@mac.com",
						   [NSLocalizedString(@"Thousand Crash Report", @"Crash") stringByAddingUTF8PercentEscapesForce],
						   [result stringByAddingUTF8PercentEscapesForce]];
	
	NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
	[sharedWorkspace openURL:[NSURL URLWithString:urlString]];
						   
}
@end

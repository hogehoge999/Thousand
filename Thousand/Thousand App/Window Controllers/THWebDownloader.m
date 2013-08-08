//
//  THWebDownloader.m
//  Thousand
//
//  Created by R. Natori on  07/08/28.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "THWebDownloader.h"

static NSString *__classDownloadFolderPath = nil;
static BOOL __classDownloadWhenFilesExist = NO;

@implementation THWebDownloader

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"destinationPath", @"URLString", nil]
          triggerChangeNotificationsForDependentKey:@"fileName"];
    [self setKeys:[NSArray arrayWithObjects:@"progress", nil]
          triggerChangeNotificationsForDependentKey:@"progressString"];
}

+(id)webDownLoaderWithURLString:(NSString *)urlString destinationFolderPath:(NSString *)path {
	return [[[self alloc] initWithURLString:urlString destinationFolderPath:path] autorelease];
}
-(id)initWithURLString:(NSString *)urlString destinationFolderPath:(NSString *)path {
	self = [super init];
	[self setURLString:urlString];
	[self setDestinationFolderPath:path];
	//[self setIsLoading:YES];
	NSURL *url = [NSURL URLWithString:urlString];
	if (!url) {
		[self autorelease];
		return nil;
	}
	_download = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
	if (!_download) {
		[self autorelease];
		return nil;
	}
	return self;
}
-(void)dealloc {
	[self cancelDownload];
	[super dealloc];
}

	// Accessors

+(void)setClassDownloadWhenFilesExist:(BOOL)aBool { __classDownloadWhenFilesExist = aBool; }
+(BOOL)classDownloadWhenFilesExist { return __classDownloadWhenFilesExist; }


-(void)setURLString:(NSString *)urlString { setObjectWithRetain(_urlString, urlString); }
-(NSString *)URLString { return _urlString; }

-(void)setDestinationFolderPath:(NSString *)path { setObjectWithRetain(_destinationFolderPath, path); }
-(NSString *)destinationFolderPath { return _destinationFolderPath; }

-(void)setDestinationPath:(NSString *)path { setObjectWithRetain(_destinationPath, path); }
-(NSString *)destinationPath { return _destinationPath; }
-(NSString *)fileName {
	if (_destinationPath) {
		return [_destinationPath lastPathComponent];
	} else {
		return [_urlString lastPathComponent];
	}
}

-(void)setMessage:(NSString *)message { setObjectWithRetain(_message, message); }
-(NSString *)message { return _message; }

-(void)setProgress:(float)progress { _progress = progress; }
-(float)progress { return _progress; }
-(NSString *)progressString {
	if (_progress < 1.0)
		return [NSString stringWithFormat:@"%@ / %@", THStringWithBytes(_receivedContentLength), THStringWithBytes(_expectedContentLength)];
	return [NSString stringWithFormat:NSLocalizedString(@"%@ Complete", @"Download"), THStringWithBytes(_expectedContentLength)];
}
NSString *THStringWithBytes(long long bytes) {
	if (bytes < 1024*1024) {
		return [NSString stringWithFormat:@"%.1fKB", (float)bytes/1024.0];
	} else if (bytes < 1024*1024*1024) {
		return [NSString stringWithFormat:@"%.1fMB", (float)bytes/(1024.0*1024.0)];
	}
	return [NSString stringWithFormat:@"%.1fGB", (float)bytes/(1024.0*1024.0*1024.0)];
}

-(void)setIsLoading:(BOOL)aBool { _isLoading = aBool; }
-(BOOL)isLoading { return _isLoading; }

	// Methods
-(void)finishDownload {
	[self setIsLoading:NO];
	if (_download) {
		NSURLDownload *tempDownLoad = _download;
		_download = nil;
		[tempDownLoad release];
	}
}
-(void)cancelDownload {
	[self setIsLoading:NO];
	[self setProgress:0.0];
	[self setMessage:NSLocalizedString(@"Canceled", @"Download")];
	if (_download) {
		NSURLDownload *tempDownLoad = _download;
		_download = nil;
		[tempDownLoad cancel];
		[tempDownLoad release];
	}
}
-(IBAction)cancelDownload:(id)sender {
	[self cancelDownload];
}
-(IBAction)revealInFinder:(id)sender {
	if (_destinationPath) {
		[[NSWorkspace sharedWorkspace] selectFile:_destinationPath
						 inFileViewerRootedAtPath:[_destinationPath stringByDeletingLastPathComponent]];
	}
}
-(IBAction)openFile:(id)sender {
	if (_destinationPath) {
		[[NSWorkspace sharedWorkspace] openFile:_destinationPath];
	}
}

// NSURLDownload Delegate Methods
- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
	NSString *destinationPath = [_destinationFolderPath stringByAppendingPathComponent:filename];
	if (!__classDownloadWhenFilesExist && [destinationPath isExistentPath]) {
		[self cancelDownload];
		_expectedContentLength = 0;
		[self setMessage:NSLocalizedString(@"Already Exists", @"Download")];
		return;
	}

	[self setDestinationPath:destinationPath];
	[destinationPath prepareFoldersInPath];
	[download setDestination:destinationPath allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
	[self setMessage:[NSString stringWithFormat:NSLocalizedString(@"Error: %@", @"Download"), [error localizedDescription]]];
	[self finishDownload];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response {
	_expectedContentLength = [response expectedContentLength];
	if (_expectedContentLength == NSURLResponseUnknownLength) _expectedContentLength = 0;
}
- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length {
	_receivedContentLength += length;
	if (_expectedContentLength > 0) {
		[self setProgress:(_receivedContentLength/_expectedContentLength)];
	}
}
- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
	return YES;
}

- (void)downloadDidBegin:(NSURLDownload *)download {
	[self setIsLoading:YES];
}
- (void)downloadDidFinish:(NSURLDownload *)download {
	[self setProgress:1.0];
	[self finishDownload];
}

@end

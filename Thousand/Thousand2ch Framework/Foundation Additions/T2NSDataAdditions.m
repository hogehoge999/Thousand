//
//  T2NSDataAdditions.m
//  Thousand
//
//  Created by R. Natori on 06/01/12.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2NSDataAdditions.h"

#define ZIP_OUT_SIZE 1024
#define UNZIP_OUT_SIZE 1024

@implementation NSData (T2NSDataAdditions)
#pragma mark -
#pragma mark NSData <-> .gz file
+(id)dataWithContentsOfGZipFile:(NSString *)path {
	/*
	if (![[path pathExtension] isEqualToString:@"gz"]) path = [path stringByAppendingPathExtension:@"gz"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		return nil;
	}
	
	const char *cFilePath = [path fileSystemRepresentation];
	NSMutableData *outData = [[[NSMutableData alloc] init] autorelease];
	Bytef *outBytes = malloc(sizeof(Bytef)*UNZIP_OUT_SIZE);
	int currentOut = 0;
	
    gzFile file = gzopen(cFilePath, "rb");
	if (file == NULL) {
		NSLog(@"gzopen failed");
		free(outBytes);
		return nil;
	}
	while (currentOut = gzread(file, outBytes, UNZIP_OUT_SIZE))
		[outData appendBytes:outBytes length:currentOut];
	if (gzclose(file) != Z_OK) NSLog(@"gzclose failed");
	
	free(outBytes);
	
	return [[outData copy] autorelease];
	 */
	return [[[NSMutableData dataWithContentsOfGZipFile:path] copy] autorelease];
}

-(BOOL)writeToGZipFile:(NSString *)path {
	if ([self length] == 0 || !path) return NO;
	
	if (![[path pathExtension] isEqualToString:@"gz"]) path = [path stringByAppendingPathExtension:@"gz"];
	
	const char *cFilePath = [path fileSystemRepresentation];
    gzFile file = gzopen(cFilePath, "wb");
	if (file == NULL) {
		NSLog(@"gzopen failed");
		[self writeToFile:[path stringByDeletingPathExtension] atomically:YES];
		return YES;
	}
	int writtenLength = gzwrite(file,[self bytes],[self length]);
	if (writtenLength == 0) {
		return NO;
	}
	if (gzclose(file) != Z_OK) {
		return NO;
	}
	return YES;
}

@end

@implementation NSMutableData (T2NSMutableDataAdditions)
#pragma mark -
#pragma mark NSData <- .gz file
+(id)dataWithContentsOfGZipFile:(NSString *)path {
	if (![[path pathExtension] isEqualToString:@"gz"]) path = [path stringByAppendingPathExtension:@"gz"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSString *path2 = [path stringByDeletingPathExtension];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path2]) {
			return [self dataWithContentsOfFile:path2];
		} else {
			return nil;
		}
	}
	
	const char *cFilePath = [path fileSystemRepresentation];
	NSMutableData *outData = [NSMutableData data];
	Bytef *outBytes = malloc(sizeof(Bytef)*UNZIP_OUT_SIZE);
	int currentOut = 0;
	
    gzFile file = gzopen(cFilePath, "rb");
	if (file == NULL) {
		NSLog(@"gzopen failed");
		free(outBytes);
		return nil;
	}
	while (currentOut = gzread(file, outBytes, UNZIP_OUT_SIZE))
		[outData appendBytes:outBytes length:currentOut];
	if (gzclose(file) != Z_OK) NSLog(@"gzclose failed");
	
	free(outBytes);
	
	return outData;
}
@end


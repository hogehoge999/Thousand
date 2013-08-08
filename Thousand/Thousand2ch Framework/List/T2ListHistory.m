//
//  T2ListHistory.m
//  Thousand
//
//  Created by R. Natori on 06/08/20.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2ListHistory.h"
#import "T2ListFace.h"

@implementation T2ListHistory
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"objects", @"maxHistoryCount", nil];
}
#pragma mark -
+(id)listHistoryForKey:(NSString *)key {
	T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:[@"History" stringByAppendingPathComponent:key]
														  title:nil
														  image:nil];
	return [listFace list];
}
-(id)initWithListFace:(T2ListFace *)listFace {
	self = [super initWithListFace:listFace];
	[self setShouldSaveFile:YES];
	return self;
}

-(void)setMaxHistoryCount:(unsigned)count { _maxHistoryCount = count; }
-(unsigned)maxHistoryCount { return _maxHistoryCount; }

-(NSString *)filePath {
	return [[[NSString appLogFolderPath] stringByAppendingPathComponent:_internalPath] stringByAppendingPathExtension:@"plist"];
}

-(void)addHistory:(T2ListFace *)listFace {
	if (_maxHistoryCount == 0) return;
	if (![listFace internalPath]) return;
	NSMutableArray *mutableList = [[[self objects] mutableCopy] autorelease];
	if (!mutableList) mutableList = [NSMutableArray array];
	[mutableList removeObjectIdenticalTo:listFace];
	[mutableList insertObject:listFace atIndex:0];
	if ([mutableList count] > _maxHistoryCount)
		[mutableList removeLastObject];
	[self setObjects:mutableList];
	
	if (_waitingHistoryCount >= _maxHistoryCount/40) {
		[self saveToFile];
		_waitingHistoryCount = 0;
	} else {
		_waitingHistoryCount++;
	}
}
-(void)removeAllHistory {
	[self setObjects:nil];
}
@end

//
//  T2ThreadHistory.m
//  Thousand
//
//  Created by R. Natori on 06/02/18.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2ThreadHistory.h"
#import "T2NSDictionaryAdditions.h"
#import "T2ListFace.h"

static NSSortDescriptor *__sharedSortDescriptor;

@implementation T2ThreadHistory

+(void)initialize {
	if (__sharedSortDescriptor) return;
	__sharedSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"voidProperty" ascending:NO];
}


#pragma mark -

-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"objects", @"maxHistoryCount", nil];
}

#pragma mark -
+(id)threadHistoryForKey:(NSString *)key {
	T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:[@"History" stringByAppendingPathComponent:key]
														  title:nil
														  image:nil];
	return [listFace list];
}
#pragma mark -

-(void)setMaxHistoryCount:(unsigned)count {
	_maxHistoryCount = count;
	NSMutableArray *mutableList = [[[self objects] mutableCopy] autorelease];
	if ([mutableList count] > _maxHistoryCount) {
		if (_maxHistoryCount == 0) {
			[mutableList removeAllObjects];
		} else {
			[mutableList removeObjectsInRange:NSMakeRange(_maxHistoryCount-1, [mutableList count] - _maxHistoryCount)];
		}
		[self setObjects:[[mutableList copy] autorelease]];
	}
}
-(unsigned)maxHistoryCount { return _maxHistoryCount; }


-(void)addHistory:(T2ThreadFace *)threadFace {
	if (!threadFace) return;
	if (_maxHistoryCount == 0) return;
	NSMutableArray *mutableList = [[[self objects] mutableCopy] autorelease];
	if (!mutableList) mutableList = [NSMutableArray array];
	
	[mutableList removeObjectIdenticalTo:threadFace];
	[mutableList insertObject:threadFace atIndex:0];
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

-(NSString *)sortDescriptorKey { return @"voidProperty"; }
-(NSSortDescriptor *)sortDescriptor { return __sharedSortDescriptor; }

#pragma mark -
#pragma mark OverRide

-(void)load {
}

-(BOOL)allowsEditingObjects {
	return YES;
}
#pragma mark -
#pragma mark Automaticaly Saving & Loading
-(NSString *)filePath {
	return [[[NSString appLogFolderPath] stringByAppendingPathComponent:_internalPath] stringByAppendingPathExtension:@"plist"];
}
@end

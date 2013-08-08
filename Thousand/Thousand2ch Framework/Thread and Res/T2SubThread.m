//
//  T2SubThread.m
//  Thousand
//
//  Created by R. Natori on 06/05/04.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2SubThread.h"

#import "T2PluginManager.h"
#import "T2Res.h"
#import "T2ThreadFace.h"


@implementation T2SubThread

+(T2SubThread *)subThreadWithThread:(T2Thread *)superThread extractPath:(NSString *)extractPath {
	return [[[self alloc] initSubThreadWithThread:superThread extractPath:extractPath] autorelease];
}
-(id)initSubThreadWithThread:(T2Thread *)superThread extractPath:(NSString *)extractPath {
	_superThread = [superThread retain];
	_extractPath = [extractPath retain];
	
	NSArray *pathComponents = [_extractPath pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	if (pathComponentsCount <= 1) return nil;
	NSString *extractKey = [pathComponents objectAtIndex:0];
	NSString *subExtractPath;
	if ([extractKey isEqualToString:@"internal:"]) {
		extractKey = [pathComponents objectAtIndex:1];
		subExtractPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(2,pathComponentsCount-2)]];
	} else {
		extractKey = [pathComponents objectAtIndex:0];
		subExtractPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(1,pathComponentsCount-1)]];
	}
	
	T2PluginManager *manager = [T2PluginManager sharedManager];
	_resExtractor = [[manager resExtractorForKey:extractKey] retain];
	
	[self updateExtracting];
	
	if (!_resArray) {
		[self autorelease];
		return nil;
	}
	
	NSString *extractDescription = [_resExtractor localizedDescriptionForKey:extractKey path:subExtractPath];
	T2ThreadFace *superThreadFace = [_superThread threadFace];
	NSString *subThreadTitle = [NSString stringWithFormat:@"%@ - %@",extractDescription ,[superThreadFace title]];
	T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:nil
																  title:subThreadTitle
																  order:0
															   resCount:[_resArray count]
															resCountNew:[_resArray count]];
	[self setThreadFace:threadFace];
	[_superThread addObserver:self forKeyPath:@"resArray" options:NSKeyValueObservingOptionOld context:NULL];
	[_superThread addObserver:self forKeyPath:@"styleUpdatedResIndexes" options:NSKeyValueObservingOptionOld context:NULL];
	return self;
}
-(void)dealloc {
	[_superThread removeObserver:self forKeyPath:@"resArray"];
	[_superThread removeObserver:self forKeyPath:@"styleUpdatedResIndexes"];
	[_superThread release];
	
	[_extractPath release];
	[_extractedResIndexes release];
	[_resExtractor release];
	
	[super dealloc];
}

-(void)updateExtracting {
	NSIndexSet *resIndexSet = [_superThread resIndexesWithExtractPath:_extractPath];
	
	NSArray *resArray = [[_superThread resArray] objectsAtIndexes_panther:resIndexSet];
	[self setResArray:resArray];
	[self setExtractedResIndexes:resIndexSet];
	[self notifyLoadedResIndexes:resIndexSet location:[resIndexSet firstIndex]];
}

#pragma mark -
#pragma mark Accessors

-(NSArray *)originalResArray { return [_superThread resArray]; }

-(void)setExtractedResIndexes:(NSIndexSet *)indexSet { setObjectWithRetain(_extractedResIndexes, indexSet); }
-(NSIndexSet *)extractedResIndexes { return _extractedResIndexes; }

#pragma mark -
#pragma mark Override

-(T2Thread *)subThreadWithExtractPath:(NSString *)extractPath {
	return [T2SubThread subThreadWithThread:_superThread extractPath:extractPath];
}

-(void)addStyle:(NSString *)style ofResWithExtractPath:(NSString *)extractPath {
	[_superThread addStyle:style ofResWithExtractPath:extractPath];
	[self notifyUpdatedStyleOfResIndexes:[_superThread styleUpdatedResIndexes]];
}
-(void)removeStylesOfResWithExtractPath:(NSString *)extractPath {
	[_superThread removeStylesOfResWithExtractPath:extractPath];
	[self notifyUpdatedStyleOfResIndexes:[_superThread styleUpdatedResIndexes]];
}
-(void)removeAllStyles {
	[_superThread removeAllStyles];
}

#pragma mark -
#pragma mark obserb
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"resArray"]) {
		[self updateExtracting];
	} else if ([keyPath isEqualToString:@"styleUpdatedResIndexes"]) {
		[self notifyUpdatedStyleOfResIndexes:[_superThread styleUpdatedResIndexes]];
	}
}
@end

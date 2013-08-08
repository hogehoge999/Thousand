//
//  T2SubThread.h
//  Thousand
//
//  Created by R. Natori on 06/05/04.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2Thread.h"

@interface T2SubThread : T2Thread {
	T2Thread *_superThread;
	NSString *_extractPath;
	NSIndexSet *_extractedResIndexes;
	id <T2ResExtracting_v100> _resExtractor;
}

+(T2SubThread *)subThreadWithThread:(T2Thread *)superThread extractPath:(NSString *)extractPath ;
-(id)initSubThreadWithThread:(T2Thread *)superThread extractPath:(NSString *)extractPath ;

-(void)updateExtracting ;
// Accessors
-(void)setExtractedResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)extractedResIndexes ;

// OverRide
-(T2Thread *)subThreadWithExtractPath:(NSString *)extractPath ;

-(void)addStyle:(NSString *)style ofResWithExtractPath:(NSString *)extractPath ;
-(void)removeStylesOfResWithExtractPath:(NSString *)extractPath ;
-(void)removeAllStyles ;
@end

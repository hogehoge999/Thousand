//
//  T2ListHistory.h
//  Thousand
//
//  Created by R. Natori on 06/08/20.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2List.h"

@interface T2ListHistory : T2List {
	unsigned _maxHistoryCount;
	unsigned _waitingHistoryCount;
}
+(id)listHistoryForKey:(NSString *)key ;

-(void)setMaxHistoryCount:(unsigned)count ;
-(unsigned)maxHistoryCount ;

-(void)addHistory:(T2ListFace *)listFace ;
-(void)removeAllHistory ;
@end

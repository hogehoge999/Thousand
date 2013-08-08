//
//  T2ThreadHistory.h
//  Thousand
//
//  Created by R. Natori on 06/02/18.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2ThreadList.h"

@interface T2ThreadHistory : T2ThreadList {
	unsigned _maxHistoryCount;
	unsigned _waitingHistoryCount;
}
+(id)threadHistoryForKey:(NSString *)key ;

-(void)setMaxHistoryCount:(unsigned)count ;
-(unsigned)maxHistoryCount ;

-(void)addHistory:(T2ThreadFace *)threadFace ;
-(void)removeAllHistory ;
@end

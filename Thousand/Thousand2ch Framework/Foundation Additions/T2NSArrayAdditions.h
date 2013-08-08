//
//  T2NSArrayAdditions.h
//  Thousand
//
//  Created by R. Natori on 06/04/17.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (T2NSArrayAdditions) 
-(NSArray *)objectsAtIndexes_panther:(NSIndexSet *)indexSet ;

@end

@interface NSMutableArray (T2NSMutableArrayAdditions)
+(NSMutableArray *)mutableArrayWithoutRetainingObjects ;

- (void)removeObjectsAtIndexes_panther:(NSIndexSet *)indexes ;
- (void)insertObjects_panther:(NSArray *)objects atIndexes:(NSIndexSet *)indexes ;
@end
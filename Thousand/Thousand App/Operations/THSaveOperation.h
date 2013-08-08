//
//  THSaveOperation.h
//  Thousand
//
//  Created by R. Natori on 平成 21/03/26.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THSaveOperation : T2Operation {
}
+(id)saveOperationWithIdentifiedObjects:(NSArray *)objects ;
+(id)saveOperationWithIdentifiedObject:(T2IdentifiedObject *)object ;
+(void)saveOnMainThread ;
@end

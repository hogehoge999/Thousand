//
//  THkeepOperation.h
//  Thousand
//
//  Created by R. Natori on 平成 21/04/07.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THKeepOperation : T2Operation {

}

+(id)keepOperationWithObjects:(NSArray *)objects ;
+(id)keepOperationWithObject:(T2IdentifiedObject *)object ;
+(void)keepOnMainThread ;
@end

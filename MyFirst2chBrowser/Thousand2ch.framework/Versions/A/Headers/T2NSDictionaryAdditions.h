//
//  T2NSDictionaryAdditions.h
//  Thousand
//
//  Created by R. Natori on 06/01/12.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDictionary (T2NSDictionaryAdditions)
// NSDictionary <-> .gz file
+(id)dictionaryWithContentsOfGZipFile:(NSString *)path ;
-(BOOL)writeToGZipFile:(NSString *)path ;
@end

@interface NSMutableDictionary (T2NSMutableDictionaryAdditions)
+(NSMutableDictionary *)mutableDictionaryWithoutRetainingValues ;
@end
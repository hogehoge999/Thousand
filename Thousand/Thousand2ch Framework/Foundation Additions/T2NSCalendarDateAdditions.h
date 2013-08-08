//
//  T2NSCalendarDateAdditions.h
//  Thousand
//
//  Created by R. Natori on 05/12/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSCalendarDate (T2NSCalendarDateAdditions)
+(NSCalendarDate *)dateWithRFC1123String:(NSString *)aString ;
-(NSString *)descriptionWithRFC1123 ;
@end

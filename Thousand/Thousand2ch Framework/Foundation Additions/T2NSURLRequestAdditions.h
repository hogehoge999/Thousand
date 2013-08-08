//
//  T2NSURLRequestAdditions.h
//  Thousand
//
//  Created by R. Natori on 06/02/04.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURLRequest (T2NSURLRequestAdditions)
+(NSURLRequest *)requestUsingGzipWithURL:(NSURL *)URL ;
+(NSURLRequest *)requestWith2chURL:(NSURL *)URL ifModifiedSince:(NSString *)dateString 
							 range:(unsigned)length ;
-(NSURLRequest *)requestByAddingUserAgentAndImporterName:(NSString *)importerName ;
-(NSURLRequest *)requestByAddingCookies ;
@end

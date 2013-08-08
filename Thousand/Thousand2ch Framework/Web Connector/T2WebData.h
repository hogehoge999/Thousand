//
//  T2WebData.h
//  Thousand
//
//  Created by R. Natori on 05/07/09.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface T2WebData : NSObject {
	NSString *_urlString;
	NSData *_contentData;
	NSDictionary *_headers;
	int _code;
}

+(T2WebData *)webDataWithData:(NSData *)data URLString:(NSString *)urlString headers:(NSDictionary *)dic code:(int)code ;
-(id)initWithData:(NSData *)data URLString:(NSString *)urlString headers:(NSDictionary *)dic code:(int)code ;

//+(T2WebData *)webDataWithData:(NSData *)data headers:(NSDictionary *)dic code:(int)code ;
//-(id)initWithData:(NSData *)data headers:(NSDictionary *)dic code:(int)code ;

// Accessors
-(void)setURLString:(NSString *)urlString;
-(NSString *)URLString ;

-(void)setContentData:(NSData *)data ;
-(NSData *)contentData ;

-(void)setHeaders:(NSDictionary *)dic ;
-(NSDictionary *)headers ;
-(id)headerForKey:(id)key ;

-(void)setCode:(int)code ;
-(int)code ;

-(NSString *)charsetName ;
-(NSString *)decodedString ;
-(NSDate *)lastModified ;
@end

//
//  T2NSStringAdditions.h
//  Thousand
//
//  Created by R. Natori on 05/06/19.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (T2NSStringAdditions)
//decoding
+(NSString *)stringWithData:(NSData *)data iconvEncoding:(NSString *)encodingString ;
+(NSString *)stringUsingIconvWithData:(NSData *)data encoding:(NSStringEncoding)encoding ;
//+(NSString *)stringUsingTECwith2chData:(NSData *)data encoding:(NSStringEncoding)encoding ;
//-(NSString *)stringByReplacingAmpersandEscapes ;
-(NSString *)stringFromHTML ;

-(NSString *)stringByReplacingPercentEscapes_T2_UsingEncoding:(NSStringEncoding)encoding ;

//range_general
-(NSRange)rangeOfLastString:(NSString *)aString options:(unsigned)mask ;
-(NSString *)substringBetweenPrefix:(NSString *)prefix andPostfix:(NSString *)postfix ;

//file path utility
-(NSString *)stringByResolvingAliasesInPath ;
-(NSString *)stringByDeletingfirstPathComponent ;
-(NSString *)firstPathComponent ;
-(NSString *)pathComponentAtIndex:(int)index ;
-(NSString *)stringByReplacingReservedCharacters ;


-(BOOL)isExistentPath ;

@end

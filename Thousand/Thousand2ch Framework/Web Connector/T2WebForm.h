//
//  T2WebForm.h
//  Thousand
//
//  Created by R. Natori on 09/02/17.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface T2WebForm : NSObject {
	NSString *_method;
	NSString *_action;
	NSString *_submitKey;
	NSString *_submitValue;
	NSMutableDictionary *_formDictionary;
	NSArray *_parameterkeys;
	NSArray *_hiddenParameterkeys;
	NSDictionary *_submitDictionary;
}
+(id)webFormWithHTMLString:(NSString *)htmlString baseURLString:(NSString *)baseURLString;
-(id)initWithHTMLString:(NSString *)htmlString baseURLString:(NSString *)baseURLString;

-(NSString *)method ;
-(NSString *)action ;

-(void)setSubmitKey:(NSString *)submitKey;
-(NSString *)submitKey ;
-(NSString *)submitValue ;
-(NSDictionary *)submitDictionary ;

-(void)setFormValue:(NSString *)value forKey:(NSString *)key ;
-(NSString *)formValueForKey:(NSString *)key ;
-(NSMutableDictionary *)formDictionary ;

-(NSArray *)parameterkeys ;
-(NSArray *)hiddenParameterkeys ;

-(NSURLRequest *)formRequestUsingEncoding:(NSStringEncoding)encoding;
@end

@interface NSString (T2WebFormAdditions)
-(NSString *)quotationRemovedString ;
@end
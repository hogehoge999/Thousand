//
//  T2NSObjectAdditions.h
//  Thousand
//
//  Created by R. Natori on 05/07/17.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	T2DictionaryEncoding = 0,
	T2DictionaryDecoding
} T2DictionaryConvertingUse;


@protocol T2DictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use ;
@end

@interface NSObject (T2NSObjectAdditions)
+(id)objectWithDictionary:(id)dic ;
-(id)initWithEncodedDictionary:(NSDictionary *)dic ;
-(void)setValuesWithEncodedDictionary:(NSDictionary *)dic ;
-(id)encodedDictionary ;

+(id)loadObjectFromFile:(NSString *)filePath ;
-(BOOL)saveObjectToFile:(NSString *)filePath ;
-(void)setValuesFromFile:(NSString *)filePath ;

-(id)releaseAfterDelay ;
+(void)addObjectToReleaseAfterDelay:(id)anObject ;
@end

//
//  T2IdentifiedObject.h
//  Thousand
//
//  Created by R. Natori on 05/11/26.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2UtilityHeader.h"


@interface T2IdentifiedObject : NSObject <T2DictionaryConverting> {
	NSString *_internalPath;
	NSMutableDictionary *_extraInfo;
	BOOL	_shouldSaveFile;
}
+(NSMutableDictionary *)createMutableDictionaryForIdentify ;
+(NSMutableDictionary *)dictionaryForIndentify ;
-(NSMutableDictionary *)dictionaryForIndentify ;

+(NSArray *)availableObjectsWithInternalPaths:(NSArray *)internalPaths ;
+(NSArray *)internalPathsForObjects:(NSArray *)objects ;

+(id)availableObjectWithInternalPath:(NSString *)internalPath ;
+(id)objectWithInternalPath:(NSString *)internalPath ;
-(id)initWithInternalPath:(NSString *)internalPath ;
//- (oneway void)release ;
-(void)dealloc ;

#pragma mark -
#pragma mark Basic Object
-(unsigned)hash ;
-(BOOL)isEqual:(id)anObject ;

#pragma mark -
#pragma mark Accessors
-(void)setInternalPath:(NSString *)internalPath ;
-(NSString *)internalPath ;

#pragma mark -
#pragma mark Automaticaly Saving & Loading
+(NSArray *)extensions ;
-(NSString *)filePath ;
-(NSString *)recommendedFilePath ;
-(NSString *)availableFilePath ;
-(void)loadFromFile ;
-(void)saveToFile ;
-(void)setShouldSaveFile:(BOOL)aBool ;
-(BOOL)shouldSaveFile ;

#pragma mark -
#pragma mark Score or Other Property
-(void)setExtraInfo:(NSDictionary *)dic ;
-(NSDictionary *)extraInfo ;
- (void)setValue:(id)value forUndefinedKey:(NSString *)key ;
- (id)valueForUndefinedKey:(NSString *)key ;

#pragma mark -
#pragma mark Deprecated

//-(void)setSaved:(BOOL)aBool ;
//-(BOOL)saved ;
	/*Use setShouldSaveFile: instead.*/
@end

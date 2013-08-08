//
//  T2ThreadFace.h
//  Thousand
//
//  Created by R. Natori on 05/07/03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2IdentifiedObject.h"
#import "T2UtilityHeader.h"
#import "T2PluginProtocols.h"

typedef enum {
	T2ThreadFaceStateUndefined = 0,
	T2ThreadFaceStateNew,
	T2ThreadFaceStateUpdated,
	T2ThreadFaceStateNotUpdated,
	T2ThreadFaceStateNone,
	T2ThreadFaceStateFallen,
	T2ThreadFaceStateFallenNoLog
} T2ThreadFaceState;

typedef enum {
	T2ThreadHasFallenMask = 1,
	T2ThreadIsCheckedMask = 2,
	T2ThreadFaceAnimatingMask = 16
	
} T2ThreadFaceBoolsMask;

@interface T2ThreadFace : T2IdentifiedObject <T2DictionaryConverting> {
	NSString	*_title;
	//NSString	*_replacedTitle;
	
	int	_order;
	int	_resCount;
	int	_resCountNew;
	
	NSDate	*_createdDate;
	NSDate	*_modifiedDate;
	
	T2ThreadFaceState	_state;
	
	int			_boolsMask;
	int			_label;
}

#pragma mark -
#pragma mark Class Properties

+(void)setClassStateNewImage:(NSImage *)anImage ;
+(NSImage *)classStateNewImage ;
+(void)setClassStateUpdatedImage:(NSImage *)anImage ;
+(NSImage *)classStateUpdatedImage ;
+(void)setClassStateNoUpdatedImage:(NSImage *)anImage ;
+(NSImage *)classStateNoUpdatedImage ;
+(void)setClassStateFallenImage:(NSImage *)anImage ;
+(NSImage *)classStateFallenImage ;
+(void)setClassStateFallenNoLogImage:(NSImage *)anImage ;
+(NSImage *)classStateFallenNoLogImage ;


#pragma mark -
#pragma mark dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use ;

#pragma mark -
#pragma mark Factory and Init

+(id)threadFaceWithURLString:(NSString *)URLString ;
+(id)threadFaceWithInternalPath:(NSString *)internalPath ;
+(id)threadFaceWithInternalPath:(NSString *)internalPath title:(NSString *)title
						  order:(int)order resCount:(int)resCount resCountNew:(int)resCountNew ;
-(id)initWithInternalPath:(NSString *)internalPath title:(NSString *)title
					order:(int)order resCount:(int)resCount resCountNew:(int)resCountNew ;

#pragma mark -
#pragma mark Getting Thread
-(T2Thread *)thread ;

#pragma mark -
#pragma mark Basic Properties

-(void)setTitle:(NSString *)aString ;
-(NSString *)title ;
-(void)setOrder:(int)anInt ;
-(int)order ;
-(void)setResCount:(int)anInt ;
-(int)resCount ;
-(void)setResCountNew:(int)anInt ;
-(int)resCountNew ;
-(void)setStateFromResCount ;
-(int)resCountGap ;

#pragma mark -
#pragma mark Optional Properties

-(T2ListFace *)threadListFace ;
-(NSString *)threadListTitle ;
-(NSString *)threadListInternalPath ;

-(void)setCreatedDate:(NSDate *)aDate ;
-(NSDate *)createdDate ;
-(void)setModifiedDate:(NSDate *)aDate ;
-(NSDate *)modifiedDate ;

//-(void)setResCountNew:(int)anInt atModifiedDate:(NSDate *)aDate ;

-(float)velocity ;

-(void)setState:(int)state ;
-(int)state ;
-(NSImage *)stateImage ;

/*
-(void)setHasFallen:(BOOL)aBool ;
-(BOOL)hasFallen ;
-(void)setChecked:(BOOL)aBool ;
-(BOOL)checked ;
-(void)setChanged:(BOOL)aBool ;
-(BOOL)changed ;
 */

-(void)setLabel:(int)anInt ;
-(int)label ;

#pragma mark -
#pragma mark Score or Other Property
-(NSString *)voidProperty ;
- (id)valueForUndefinedKey:(NSString *)key ;

#pragma mark -
#pragma mark Other
-(id <T2ThreadImporting_v100>)threadImpoerterPlug ;
-(NSString *)logFilePath ;
-(void)recycleThreadLogFile ;
//-(void)removeThread ;

#pragma mark -
#pragma mark Animation Support
+(void)setClassAnimationImages:(NSArray *)images ;
+(void)startAnimation ;
+(void)stopAnimation ;
+(void)animate:(NSTimer *)timer ;
	// use these methods
-(void)startAnimation ;
-(void)stopAnimation ;
@end

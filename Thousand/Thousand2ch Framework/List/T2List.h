//
//  T2List.h
//  Thousand
//
//  Created by R. Natori on 05/07/03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2IdentifiedObject.h"
#import "T2UtilityHeader.h"
#import "T2Protocols.h"
#import "T2PluginProtocols.h"

#define T2ListHoldersPboardType  @"T2ListHoldersPboardType"

@class T2ListFace, T2WebConnector;

// Notifications

extern NSString *T2ListDidStartLoadingNotification;
extern NSString *T2ListDidProgressLoadingNotification;
extern NSString *T2ListDidEndLoadingNotification;

@interface T2List : T2IdentifiedObject <T2DictionaryConverting, T2AsynchronousLoading> {
	T2ListFace *_listFace;
	
	NSArray		*_objects;
	T2WebConnector	*_connector;
	
	BOOL		_isLoading;
	float		_progress;
	NSString	*_progressInfo;
	
	NSTimeInterval	_loadingInterval;
	NSDate			*_lastLoadingDate;
}

#pragma mark -
#pragma mark dictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use ;

#pragma mark -
#pragma mark Factory and init

+(id)listWithListFace:(T2ListFace *)listFace ;
+(id)listWithListFace:(T2ListFace *)listFace objects:(NSArray *)objects ;
+(id)listWithInternalPath:(NSString *)internalPath title:(NSString *)title
					image:(NSImage *)image objects:(NSArray *)objects ;

-(id)initWithListFace:(T2ListFace *)listFace ;
-(id)initWithListFace:(T2ListFace *)listFace objects:(NSArray *)objects ;
-(id)initWithInternalPath:(NSString *)internalPath title:(NSString *)title
					image:(NSImage *)image objects:(NSArray *)objects ;

#pragma mark -
#pragma mark Basic

//-(unsigned)hash ;
//-(BOOL)isEqual:(id)anObject ;
//-(BOOL)isEqualToList:(T2List *)list;

#pragma mark -
#pragma mark Accessors

-(void)setListFace:(T2ListFace *)listFace ;
-(T2ListFace *)listFace ;
-(void)setImage:(NSImage *)anImage ;
-(NSImage *)image ;
-(void)setTitle:(NSString *)aString ;
-(NSString *)title ;
-(void)setObjects:(NSArray *)anArray ;
-(NSArray *)objects ;
//-(NSMutableArray *)mutableList ;
-(void)setWebConnector:(T2WebConnector *)webConnector ;
-(T2WebConnector *)webConnector ;

-(BOOL)allowsRemovingObjects ;
-(BOOL)allowsEditingObjects ;

-(void)setLoadingInterval:(NSTimeInterval)timeInterval ;
-(NSTimeInterval)loadingInterval;
-(void)setLastLoadingDate:(NSDate *)date ;
-(NSDate *)lastLoadingDate ;
-(BOOL)loadableInterval;

#pragma mark -
#pragma mark Automaticaly Saving & Loading
-(NSString *)filePath ;

#pragma mark -
#pragma mark  Methods

-(void)addObject:(id)anObject ;
-(void)addObjects:(NSArray *)objects ;
-(void)insertObject:(id)anObject atIndex:(unsigned)anInt ;
-(void)insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes ;
-(void)removeObject:(id)anObject ;
-(void)removeObjects:(NSArray *)objects ;
-(void)removeObjectAtIndex:(unsigned)anInt ;
-(void)removeObjectsAtIndexes:(NSIndexSet *)indexes ;

#pragma mark -
#pragma mark protocol T2AsynchronousLoading
-(void)load ;
-(void)cancelLoading ;

-(void)setIsLoading:(BOOL)aBool ;
-(BOOL)isLoading ;

-(void)setProgress:(float)aFloat ;
-(float)progress ;
-(void)setProgressInfo:(NSString *)aString ; 
-(NSString *)progressInfo ;

@end

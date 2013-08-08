//
//  T2Thread.h
//  Thousand
//
//  Created by R. Natori on 05/06/19.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2IdentifiedObject.h"
#import "T2UtilityHeader.h"
#import "T2Protocols.h"
#import "T2PluginProtocols.h"

@class T2Res, T2ThreadFace, T2WebConnector;

// Notifications

extern NSString *T2ThreadDidStartLoadingNotification;
extern NSString *T2ThreadDidProgressLoadingNotification;
extern NSString *T2ThreadDidLoadResIndexesNotification;
extern NSString *T2ThreadDidUpdateStyleOfResIndexesNotification;
extern NSString *T2ThreadResIndexes;

// informal protocol
@interface NSObject ( T2ThreadDelegate )
-(void)thread:(T2Thread *)thread didLoadResIndexes:(NSIndexSet *)indexSet
	 location:(unsigned)location;
-(void)thread:(T2Thread *)thread didUpdateStyleOfResIndexes:(NSIndexSet *)indexSet ;
@end

@interface T2Thread : T2IdentifiedObject <T2DictionaryConverting, T2AsynchronousLoading> {
	T2ThreadFace *_threadFace;
	NSArray *_resArray;
	NSIndexSet *_loadedResIndexes;
	
	T2Res *_myRes;
	NSIndexSet *_myResIndexes;
	
	NSMutableDictionary *_idDictionary;
	NSMutableDictionary *_tripDictionary;
	
	NSMutableDictionary *_pathStyleDictionary;
	NSMutableDictionary *_indexesStyleDictionary;
	NSIndexSet 			*_styleUpdatedresIndexes;
	BOOL				_isStyleApplied;
	
	NSString *_draft;
	
	T2WebConnector	*_connector;
	//id _delegate;
	
	BOOL		_isLoading;
	float		_progress;
	NSString	*_progressInfo;
	BOOL		_shouldSavePList;
	BOOL		_shouldUseSharedCookies;
	
	NSTimeInterval	_loadingInterval;
	NSDate			*_lastLoadingDate;
	unsigned		_retryCount;
	
	unsigned		_newResIndex;
	int				_savedResIndex;
	float			_savedScrollOffset;
	
	NSString *_webBrowserURLString;
	NSDictionary *_oldSavedDictionary;
}

// Do not call these factory method directly (without T2PluginManager or plugin)
// To get thread object, use T2ThreadFace instance method -thread.
+(id)threadWithThreadFace:(T2ThreadFace *)threadFace ;
+(id)threadWithThreadFace:(T2ThreadFace *)threadFace resArray:(NSArray *)resArray ;
-(id)initWithThreadFace:(T2ThreadFace *)threadFace resArray:(NSArray *)resArray ;

-(void)dealloc ;


#pragma mark -
#pragma mark Accessors

-(void)setThreadFace:(T2ThreadFace *)threadFace ;
-(T2ThreadFace *)threadFace ;

-(void)setResArray:(NSArray *)anArray ;
-(NSArray *)resArray;
-(NSArray *)originalResArray;
-(void)setLoadedResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)loadedResIndexes ;
-(void)setMyResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)myResIndexes ;

-(void)setDraft:(NSString *)aString ;
-(NSString *)draft ;

-(void)setWebConnector:(T2WebConnector *)webConnector ;
-(T2WebConnector *)webConnector ;

#pragma mark -
#pragma mark Optional Accessors
-(void)setIdDictionary:(NSDictionary *)dictionary ;
-(NSDictionary *)idDictionary ;

-(void)setTripDictionary:(NSDictionary *)dictionary ;
-(NSDictionary *)tripDictionary ;

-(void)setLoadingInterval:(NSTimeInterval)timeInterval ;
-(NSTimeInterval)loadingInterval ;
-(void)setLastLoadingDate:(NSDate *)date ;
-(NSDate *)lastLoadingDate ;
-(BOOL)loadableInterval ;

-(void)setNewResIndex:(unsigned)index ;
-(unsigned)newResIndex ;

-(void)setSavedResIndex:(int)index ;
-(int)savedResIndex ;
-(void)setSavedScrollOffset:(float)offset ;
-(float)savedScrollOffset ;

-(void)setWebBrowserURLString:(NSString *)urlString ;
-(NSString *)webBrowserURLString ;

-(void)setShouldUseSharedCookies:(BOOL)aBool ;
-(BOOL)shouldUseSharedCookies ;

#pragma mark -
#pragma mark Getting Posting
-(T2Posting *)postingWithRes:(T2Res *)res ;
-(BOOL)addPostedMyRes:(T2Res *)res ;
-(void)registerPostedMyRes:(T2Res *)res ;

#pragma mark -
#pragma mark Delegate
//-(void)setDelegate:(id)object ;
//-(id)delegate ;
-(void)notifyLoadedResIndexes:(NSIndexSet *)resIndexes location:(unsigned)location ;
-(void)notifyUpdatedStyleOfResIndexes:(NSIndexSet *)resIndexes ;

#pragma mark -
#pragma mark Trace reply
-(NSIndexSet *)forwardResIndexesFromResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)backwardResIndexesFromResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)traceResIndexes:(NSIndexSet *)indexSet depth:(unsigned)depth ;
-(NSIndexSet *)backtraceResIndexes:(NSIndexSet *)indexSet depth:(unsigned)depth ;
-(NSIndexSet *)backwardAndSeriesResIndexesFromResIndexes:(NSIndexSet *)indexSet ;
	
#pragma mark -
#pragma mark Res Extracting and sub thread
-(T2Thread *)subThreadWithExtractPath:(NSString *)extractPath ;
-(NSIndexSet *)resIndexesWithExtractPath:(NSString *)extractPath ;

-(BOOL)newResIndexIsIn2ndToLast ;

#pragma mark -
#pragma mark  Styles
-(void)setPathStyleDictionary:(NSDictionary *)dic ;
-(NSDictionary *)pathStyleDictionary ;
-(void)setIndexesStyleDictionary:(NSDictionary *)dic ;
-(NSDictionary *)indexesStyleDictionary ;
-(void)setStyleUpdatedResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)styleUpdatedResIndexes ;
-(BOOL)hasStyles ;

#pragma mark -
-(void)addStyle:(NSString *)style ofResWithExtractPath:(NSString *)extractPath ;
-(void)addInternalStyle:(NSString *)style ofResWithExtractPath:(NSString *)extractPath ;
-(void)addInternalStyle:(NSString *)style ofResWithIndexes:(NSIndexSet *)indexes ;
-(void)applyAllStyles ;
-(void)removeStylesOfResWithExtractPath:(NSString *)extractPath ;
-(void)removeInternalStylesOfResWithExtractPath:(NSString *)extractPath ;
-(void)removeInternalStylesOfResWithIndexes:(NSIndexSet *)indexes ;
-(void)removeAllStyles ;

#pragma mark -
#pragma mark Web representation
-(NSString *)HTMLForResWithExtractPath:(NSString *)extractPath baseURL:(NSURL **)baseURL
							  forPopUp:(BOOL)forPopUp ;
-(NSString *)HTMLForAllResAndbaseURL:(NSURL **)baseURL forPopUp:(BOOL)forPopUp ;
-(NSString *)HTMLForResInRange:(NSRange)range andFirstRes:(BOOL)firstRes
					   baseURL:(NSURL **)baseURL forPopUp:(BOOL)forPopUp ;
-(NSString *)HTMLForResIndexes:(NSIndexSet *)resIndexes baseURL:(NSURL **)baseURL
					  forPopUp:(BOOL)forPopUp ;

-(NSString *)extensibleHTMLFromResIndex:(int)resIndex toResIndex:(int)toResIndex baseURL:(NSURL **)baseURL ;
-(NSString *)extensionHTMLFromResIndex:(int)fromResIndex toResIndex:(int)toResIndex
						  onDownstream:(BOOL)onDownstream ;

-(NSString *)excerptHTMLForResIndexes:(NSIndexSet *)resIndexes ;
-(NSString *)HTMLWithOtherInsertion:(NSString *)htmlString baseURL:(NSURL **)baseURL
						   forPopUp:(BOOL)forPopUp ;
-(NSString *)CSSPathsLinkString ;


#pragma mark -
#pragma mark ThreadFace Methods And Skin Supports
-(void)setTitle:(NSString *)aString ;
-(NSString *)title ;
//-(NSString *)replacedTitle ;

-(int)resCount ;
-(int)resCountNew ;

-(T2ListFace *)threadListFace ;
-(NSString *)threadListTitle ;
-(NSString *)resCountString ;
-(NSString *)labelColorString ;
-(NSString *)lightLabelColorString ;
-(NSString *)darkLabelColorString ;

#pragma mark -
#pragma mark Score or Other Property
//- (void)setValue:(id)value forUndefinedKey:(NSString *)key ;
//- (id)valueForUndefinedKey:(NSString *)key ;


#pragma mark -
#pragma mark Automaticaly Saving & Loading
+(void)setExtensions:(NSArray *)extensions ;
+(NSArray *)extensions ;
-(NSString *)filePath ;

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


#pragma mark -
#pragma mark Deprecated
//-(void)setShouldSavePList:(BOOL)aBool ;
//-(BOOL)shouldSavePList ;
	/*Use setShouldSaveFile: (T2IdentifiedObject) instead.*/
@end

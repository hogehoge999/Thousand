//
//  T2Res.h
//  Thousand
//
//  Created by R. Natori on 05/06/19.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class T2Thread;

@interface T2Res : NSObject {
	// primary properties
	int 		_resNumber;
	NSString *	_name;
	NSString *	_mail;
	NSDate *	_date;
	NSString *	_identifier;
	NSString *	_content;
	
	// optional properties
	NSString *	_trip;
	NSString *	_dateString;
	NSString *	_hostName;
	NSString *	_beString;
	
	// connections
	T2Thread		  * _thread;
	NSMutableIndexSet *	_backwardResIndexes;
	NSMutableIndexSet *	_forwardResIndexes;
	
	// html element classes
	NSMutableArray *_htmlClasses;
	
	// other property container
	NSMutableDictionary *_container;
}

#pragma mark -
#pragma mark factory method
+(T2Res *)resWithResNumber:(int)resNumber name:(NSString *)name mail:(NSString *)mail
					  date:(NSDate *)date identifier:(NSString *)identifier
				   content:(NSString *)content thread:(T2Thread *)thread;

#pragma mark -
#pragma mark initWith- methods
-(id)initWithResNumber:(int)resNumber name:(NSString *)name mail:(NSString *)mail
				  date:(NSDate *)date identifier:(NSString *)identifier
			   content:(NSString *)content thread:(T2Thread *)thread;

-(void)dealloc ;

#pragma mark -
#pragma mark Accessors for primary
-(void)setResNumber:(int)anInt ;
-(int)resNumber ;
-(void)setName:(NSString *)aString ;
-(NSString *)name ;
-(void)setMail:(NSString *)aString ;
-(NSString *)mail ;
-(void)setDate:(NSDate *)aDate ;
-(NSDate *)date ;
-(void)setIdentifier:(NSString *)aString ;
-(NSString *)identifier ;
-(unsigned)identifierCount ;
-(void)setContent:(NSString *)aString ;
-(NSString *)content ;

#pragma mark -
#pragma mark Accessors for option
-(void)setTrip:(NSString *)aString ;
-(NSString *)trip ;
-(unsigned)tripCount ;
-(void)setHostName:(NSString *)aString ;
-(NSString *)hostName ;
-(void)setDateString:(NSString *)aString ;
-(NSString *)dateString ;
-(void)setBeString:(NSString *)aString ;
-(NSString *)beString ;

#pragma mark -
#pragma mark Accessors for connection
-(void)setThread:(T2Thread *)thread ;
-(T2Thread *)thread ;

-(void)setBackwardResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)backwardResIndexes ;
-(void)addBackwardResIndexes:(NSIndexSet *)indexSet ;
-(void)addBackwardResIndex:(unsigned)index ;
-(int)backwardResCount ;
-(NSString *)backwardResCountString ;

-(void)setForwardResIndexes:(NSIndexSet *)indexSet ;
-(NSIndexSet *)forwardResIndexes ;
-(void)addForwardResIndexes:(NSIndexSet *)indexSet ;
-(void)addForwardResIndex:(unsigned)index ;
-(int)forwardResCount ;
-(NSString *)forwardResCountString ;

#pragma mark -
#pragma mark html element classes
-(void)setHTMLClasses:(NSArray *)anArray ;
-(NSArray *)HTMLClasses ;
-(void)addHTMLClass:(NSString *)aString ;
-(void)removeHTMLClass:(NSString *)aString ;
-(NSString *)HTMLClassesString ;

#pragma mark -
#pragma mark Accessors for HTML
-(NSString *)resNumberString ;
-(NSString *)escapedIdentifier ;
-(NSString *)identifierCountString ;
-(NSString *)escapedTrip ;
-(NSString *)tripCountString ;

	// other property? use Key-Value-Coding. value will be set automatically in NSMutableDictionary
- (void)setValue:(id)value forUndefinedKey:(NSString *)key ;
- (id)valueForUndefinedKey:(NSString *)key ;
@end

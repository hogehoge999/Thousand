//
//  T2Res.m
//  Thousand
//
//  Created by R. Natori on 05/06/19.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2Res.h"
#import "T2Thread.h"
#import "T2UtilityHeader.h"

@implementation T2Res
#pragma mark -
#pragma mark factory method
+(T2Res *)resWithResNumber:(int)resNumber name:(NSString *)name mail:(NSString *)mail
					  date:(NSDate *)date identifier:(NSString *)identifier
				   content:(NSString *)content thread:(T2Thread *)thread {
	return [[[self alloc] initWithResNumber:resNumber name:name mail:mail
									   date:date identifier:identifier
									content:content thread:thread] autorelease];
}
#pragma mark -
#pragma mark initWith- methods
-(id)initWithResNumber:(int)resNumber name:(NSString *)name mail:(NSString *)mail
			date:(NSDate *)date identifier:(NSString *)identifier
			   content:(NSString *)content thread:(T2Thread *)thread {
	self = [super init];
	_resNumber = resNumber;
	_name = [name retain];
	_mail = [mail retain];
	_date = [date retain];
	_identifier = [identifier retain];
	_content = [content retain];
	_thread = thread;
	return self;
}

-(void)dealloc {
	[_name release];
	[_mail release];
	[_date release];
	[_identifier release];
	[_content release];
	
	[_trip release];
	[_dateString release];
	[_hostName release];
	[_beString release];
	
	[_backwardResIndexes release];
	[_forwardResIndexes release];
	[_container release];
	[_htmlClasses release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors for primary
-(void)setResNumber:(int)anInt { _resNumber = anInt; }
-(int)resNumber { return _resNumber; }

-(void)setName:(NSString *)aString { setObjectWithRetain(_name, aString); }
-(NSString *)name { return _name; }

-(void)setMail:(NSString *)aString { setObjectWithRetain(_mail, aString); }
-(NSString *)mail { return _mail; }

-(void)setDate:(NSDate *)aDate { setObjectWithRetain(_date, aDate); }
-(NSDate *)date { return _date; }

-(void)setIdentifier:(NSString *)aString { setObjectWithRetain(_identifier, aString); }
-(NSString *)identifier { return _identifier; }
-(unsigned)identifierCount {
	if (_identifier && _thread) {
		NSDictionary *idDic = [_thread idDictionary];
		NSIndexSet *indexes = [idDic objectForKey:_identifier];
		return [indexes count];
	}
	return 0;
}

-(void)setContent:(NSString *)aString { setObjectWithRetain(_content, aString); }
-(NSString *)content { return _content; }


#pragma mark -
#pragma mark Accessors for option
-(void)setTrip:(NSString *)aString { setObjectWithRetain(_trip, aString); }
-(NSString *)trip { return _trip; }
-(unsigned)tripCount {
	if (_trip && _thread) {
		NSDictionary *tripDic = [_thread tripDictionary];
		NSIndexSet *indexes = [tripDic objectForKey:_trip];
		return [indexes count];
	}
	return 0;
}

-(void)setDateString:(NSString *)aString { setObjectWithRetain(_dateString, aString); }
-(NSString *)dateString { 
	if (!_dateString && _date) [self setDateString:[_date descriptionWithCalendarFormat:@"%y/%m/%d %H:%M:%S"
																			   timeZone:[NSTimeZone localTimeZone]
																				 locale:nil]];
	return _dateString;
}

-(void)setHostName:(NSString *)aString { setObjectWithRetain(_hostName, aString); }
-(NSString *)hostName { return _hostName; }

-(void)setBeString:(NSString *)aString { setObjectWithRetain(_beString, aString); }
-(NSString *)beString { return _beString; }

#pragma mark -
#pragma mark Accessors for connection

-(void)setThread:(T2Thread *)thread { _thread = thread; }
-(T2Thread *)thread { return _thread; }

-(void)setBackwardResIndexes:(NSIndexSet *)indexSet {
	[_backwardResIndexes release];
	_backwardResIndexes = [indexSet mutableCopy];
}
-(NSIndexSet *)backwardResIndexes {
	return _backwardResIndexes;
}
-(void)addBackwardResIndexes:(NSIndexSet *)indexSet {
	if (!_backwardResIndexes) _backwardResIndexes = [[NSMutableIndexSet alloc] init];
	[_backwardResIndexes addIndexes:indexSet];
}
-(void)addBackwardResIndex:(unsigned)index {
	if (!_backwardResIndexes) _backwardResIndexes = [[NSMutableIndexSet alloc] init];
	[_backwardResIndexes addIndex:index];
}
-(int)backwardResCount { return [_backwardResIndexes count]; }
-(NSString *)backwardResCountString { return [NSString stringWithFormat:@"%d",[_backwardResIndexes count]]; }

-(void)setForwardResIndexes:(NSIndexSet *)indexSet {
	[_forwardResIndexes release];
	_forwardResIndexes = [indexSet mutableCopy];
}
-(NSIndexSet *)forwardResIndexes {
	return _forwardResIndexes;
}
-(void)addForwardResIndexes:(NSIndexSet *)indexSet {
	if (!_forwardResIndexes) _forwardResIndexes = [[NSMutableIndexSet alloc] init];
	[_forwardResIndexes addIndexes:indexSet];
}
-(void)addForwardResIndex:(unsigned)index {
	if (!_forwardResIndexes) _forwardResIndexes = [[NSMutableIndexSet alloc] init];
	[_forwardResIndexes addIndex:index];
}
-(int)forwardResCount { return [_forwardResIndexes count]; }
-(NSString *)forwardResCountString { return [NSString stringWithFormat:@"%d",[_forwardResIndexes count]]; }

#pragma mark -
#pragma mark html element classes
-(void)setHTMLClasses:(NSArray *)anArray { 
	if (!_htmlClasses) _htmlClasses = [[NSMutableArray alloc] init];
	[_htmlClasses setArray:anArray];
}
-(NSArray *)HTMLClasses {
	return _htmlClasses;
}
-(void)addHTMLClass:(NSString *)aString {
	if (!_htmlClasses) _htmlClasses = [[NSMutableArray alloc] init];
	[_htmlClasses addObject:aString];
}
-(void)removeHTMLClass:(NSString *)aString {
	if (_htmlClasses) {
		[_htmlClasses removeObject:aString];
	}
}
-(NSString *)HTMLClassesString {
	if (_htmlClasses) return [_htmlClasses componentsJoinedByString:@" "];
	else return @"";
}

#pragma mark -
#pragma mark Accessors for HTML
-(NSString *)resNumberString { return [NSString stringWithFormat:@"%d", _resNumber]; }

-(NSString *)escapedIdentifier {
	if (!_identifier) return nil;
	return [_identifier stringByAddingUTF8PercentEscapesForce];
}
-(NSString *)identifierCountString {
	if (_identifier && _thread) {
		NSDictionary *idDic = [_thread idDictionary];
		NSIndexSet *indexes = [idDic objectForKey:_identifier];
		if (indexes) return [NSString stringWithFormat:@"%d", [indexes count]];
	}
	return @"0";
}


-(NSString *)escapedTrip {
	if (!_trip) return nil;
	return [_trip stringByAddingUTF8PercentEscapesForce];
}
-(NSString *)tripCountString {
	if (_trip && _thread) {
		NSDictionary *tripDic = [_thread tripDictionary];
		NSIndexSet *indexes = [tripDic objectForKey:_trip];
		if (indexes) return [NSString stringWithFormat:@"%d", [indexes count]];
	}
	return @"0";
}

#pragma mark -
#pragma mark other property
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	if (!_container) _container = [[NSMutableDictionary alloc] init];
	[_container setValue:value forKey:key];
}
- (id)valueForUndefinedKey:(NSString *)key {
	if (!_container) return nil;
	return [_container valueForKey:key];
}
@end

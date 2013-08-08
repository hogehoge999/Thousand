//
//  T2WebForm.m
//  Thousand
//
//  Created by R. Natori on 09/02/17.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import "T2WebForm.h"
#import "T2NSStringAdditions.h"
#import "T2NSScannerAdditions.h"
#import "T2UtilityHeader.h"


@implementation T2WebForm

+(id)webFormWithHTMLString:(NSString *)htmlString baseURLString:(NSString *)baseURLString {
	return [[[self alloc] initWithHTMLString:htmlString baseURLString:baseURLString] autorelease];
}
-(id)initWithHTMLString:(NSString *)htmlString baseURLString:(NSString *)baseURLString{
	self = [super init];
	
	//NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	
	// Scan form
	NSScanner *scanner = [NSScanner scannerWithString:htmlString];
	if (![scanner scanUpAndThroughString:@"<form" intoString:NULL]) {
		[self autorelease];
		return nil;
	}
	
	// Scan Action and Method
	unsigned scanLocation = [scanner scanLocation];
	
	NSString *action = nil;
	if (!([scanner scanUpAndThroughString:@"action" intoString:NULL] &&
		  [scanner scanUpAndThroughString:@"=" intoString:NULL])) {
		[self autorelease];
		return nil;
	}
	[scanner scanTokenString:&action];
	
	if (action && baseURLString) {
		action = [action quotationRemovedString];
		NSURL *baseURL = [NSURL URLWithString:baseURLString];
		NSURL *absoluteURL = [NSURL URLWithString:action relativeToURL:baseURL];
		action = [absoluteURL absoluteString];
	}
	
	_action = [action retain];
	
	[scanner setScanLocation:scanLocation];
	NSString *method;
	[scanner scanUpAndThroughString:@"method" intoString:NULL];
	[scanner scanUpAndThroughString:@"=" intoString:NULL];
	[scanner scanTokenString:&method];
	_method = [method retain];
	
	[scanner setScanLocation:scanLocation];
	[scanner scanUpToString:@">" intoString:NULL];
	[scanner scanString:@">" intoString:NULL];
	
	// Scan Inputs
	NSString *inputString;
	[scanner scanUpToString:@"</form>" intoString:&inputString];
	
	NSArray *inputComponents = [inputString componentsSeparatedByString:@"<input"];
	NSEnumerator *inputEnumerator = [inputComponents objectEnumerator];
	NSString *inputComponent = [inputEnumerator nextObject];
	
	NSMutableDictionary *formDictionary = [NSMutableDictionary dictionary];
	NSMutableDictionary *submitDictionary = [NSMutableDictionary dictionary];
	NSMutableArray *parameterkeys = [NSMutableArray array];
	NSMutableArray *hiddenParameterkeys = [NSMutableArray array];
	
	while (inputComponent = [inputEnumerator nextObject]) {
		NSRange endRange = [inputComponent rangeOfString:@">"];
		if (endRange.location != NSNotFound) {
			inputComponent = [inputComponent substringToIndex:endRange.location];
			
			scanner = [NSScanner scannerWithString:inputComponent];
			
			NSString *type;
			[scanner scanUpAndThroughString:@"type" intoString:NULL];
			[scanner scanUpAndThroughString:@"=" intoString:NULL];
			[scanner scanTokenString:&type];
			
			[scanner setScanLocation:0];
			NSString *name;
			[scanner scanUpAndThroughString:@"name" intoString:NULL];
			[scanner scanUpAndThroughString:@"=" intoString:NULL];
			[scanner scanTokenString:&name];
			
			[scanner setScanLocation:0];
			NSString *value;
			[scanner scanUpAndThroughString:@"value" intoString:NULL];
			[scanner scanUpAndThroughString:@"=" intoString:NULL];
			[scanner scanTokenString:&value];
			
			if (name) {
				if (!value) {
					value = @"";
				}
				if ([type isEqualToString:@"submit"]) {
					[submitDictionary setObject:value forKey:name];
					setObjectWithCopy(_submitKey, name);
					setObjectWithCopy(_submitValue, value);
				} else {
					[formDictionary setObject:value forKey:name];
					if ([type isEqualToString:@"hidden"]) {
						[hiddenParameterkeys addObject:name];
					} else {
						[parameterkeys addObject:name];
					}
				}
			}
		}
	}
	
	_submitDictionary = [submitDictionary copy];
	_formDictionary = [formDictionary retain];
	
	_parameterkeys = [parameterkeys copy];
	_hiddenParameterkeys = [hiddenParameterkeys copy];
	
	return self;
}

-(void)dealloc {
	[_method release];
	[_action release];
	[_submitKey release];
	[_submitValue release];
	[_formDictionary release];
	[_parameterkeys release];
	[_hiddenParameterkeys release];
	[_submitDictionary release];
	
	[super dealloc];
}

-(NSString *)method { return _method; }
-(NSString *)action { return _action; }

-(void)setSubmitKey:(NSString *)submitKey {
	setObjectWithCopy(_submitKey, submitKey);
	NSString *value = [_submitDictionary objectForKey:submitKey];
	setObjectWithCopy(_submitValue, value);
}
-(NSString *)submitKey { return _submitKey; }
-(NSString *)submitValue { return _submitValue; }
-(NSDictionary *)submitDictionary { return _submitDictionary; }

-(void)setFormValue:(NSString *)value forKey:(NSString *)key {
	[_formDictionary setObject:value forKey:key];
}
-(NSString *)formValueForKey:(NSString *)key {
	return [_formDictionary objectForKey:key];
}
-(NSMutableDictionary *)formDictionary { return _formDictionary; }

-(NSArray *)parameterkeys { return _parameterkeys; }
-(NSArray *)hiddenParameterkeys { return _hiddenParameterkeys; }


-(NSURLRequest *)formRequestUsingEncoding:(NSStringEncoding)encoding {

	if (!_action || !_method || !_formDictionary || !_submitKey || !_submitValue) return nil;
	
	NSMutableDictionary *bodyDictionary = [[_formDictionary mutableCopy] autorelease];
	[bodyDictionary setObject:_submitValue forKey:_submitKey];
	
	NSMutableString *bodyString = [NSMutableString string];
	NSEnumerator *nameEnumerator = [bodyDictionary keyEnumerator];
	NSString *name;
	BOOL isFirst = YES;
	while (name = [nameEnumerator nextObject]) {
		NSString *value = [[bodyDictionary objectForKey:name] stringByReplacingCharacterReferences];
		value = [value stringByAddingCharacterReferencesForEncoding:encoding];
		
		if (!isFirst) {
			[bodyString appendString:@"&"];
		} else {
			isFirst = NO;
		}
		[bodyString appendFormat:@"%@=%@",
		 [name stringByAddingPercentEscapes_T2_UsingEncoding:encoding],
		 [value stringByAddingPercentEscapes_T2_UsingEncoding:encoding]];
	}
	
	if ([_method isEqualToString:@"POST"] || [_method isEqualToString:@"post"]) {
		NSMutableURLRequest *urlRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_action]] autorelease];
		
		[urlRequest setHTTPMethod:@"POST"];
		NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
		unsigned bodyLength = [bodyData length];
		[urlRequest setHTTPBody:bodyData];
		[urlRequest setValue:[NSString stringWithFormat:@"%d",bodyLength]
		  forHTTPHeaderField:@"Content-length"];
		
		return urlRequest;
	} else if ([_method isEqualToString:@"GET"] || [_method isEqualToString:@"get"]) {
		NSURLRequest *urlRequest = [[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:
																	   [NSString stringWithFormat:@"%@?%@",
																		_action,
																		bodyString]]] autorelease];
		return urlRequest;
		
	}
	return nil;	
}
@end

@implementation NSString (T2WebFormAdditions)
-(NSString *)quotationRemovedString {
	unsigned length = [self length];
	if (self && length >= 2) {
		NSRange range = [self rangeOfString:@"\"" options:NSCaseInsensitiveSearch];
		if (range.location != NSNotFound && range.location+1 < length) {
			NSString *string = [self substringFromIndex:range.location+1];
			range = [string rangeOfString:@"\"" options:NSCaseInsensitiveSearch];
			if (range.location != NSNotFound) {
				string = [string substringToIndex:range.location];
				return string;
			}
		}
		
		range = [self rangeOfString:@"'" options:NSCaseInsensitiveSearch];
		if (range.location != NSNotFound && range.location+1 < length) {
			NSString *string = [self substringFromIndex:range.location+1];
			range = [string rangeOfString:@"'" options:NSCaseInsensitiveSearch];
			if (range.location != NSNotFound) {
				string = [string substringToIndex:range.location];
				return string;
			}
		}
	}
	return self;
}
@end
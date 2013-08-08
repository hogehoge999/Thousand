//
//  T2KeyValueReplace.h
//  Thousand
//
//  Created by R. Natori on 平成 19/11/18.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum T2KeyValueReplaceDirection {
	T2KeyValueReplaceDirectionNotConditional = 0,
	T2KeyValueReplaceDirectionConditional = 1,
	T2KeyValueReplaceDirectionConditionalStart = 2,
	T2KeyValueReplaceDirectionConditionalEnd = 4,
} ;

@interface T2KeyValueReplace : NSObject {
	NSArray *_parts;
	NSArray *_keys;
	
	unsigned _capacity;
}

+(id)keyReplaceWithTemplateString:(NSString *)aString ;
-(id)initWithTemplateString:(NSString *)aString ;
-(NSString *)replacedStringUsingObject:(NSObject *)anObject ;
@end

@interface T2KeyValueReplaceConditional : T2KeyValueReplace {
	int *_directionsPtr;
}
@end

@interface T2KeyValueReplaceNoReplace : T2KeyValueReplace {
	NSString *_templateString;
}
@end

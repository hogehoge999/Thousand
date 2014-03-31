//
//  T2FilterArrayController.m
//  Thousand
//
//  Created by R. Natori on 05/12/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2FilterArrayController.h"
#import "T2ThreadFace.h"


@implementation T2FilterArrayController

-(void)setSearchString:(NSString *)searchString {
	[searchString retain];
	[_searchString release];
	_searchString = searchString;
	
	if (_compareOptionFlags == 0) {
        if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_5) {
            _compareOptionFlags = kCFCompareCaseInsensitive | kCFCompareNonliteral | 128 | 256;
        } else {
            _compareOptionFlags = kCFCompareCaseInsensitive | kCFCompareNonliteral;
        }
	}
}
-(NSString *)searchString { return _searchString; }
/*
-(void)setCopmpareOptionFlags:(CFOptionFlags)compareOptionFlags {
}
-(CFOptionFlags)compareOptionFlags {
}
 */

- (NSArray *)arrangeObjects:(NSArray *)objects {
	if (!_searchString || [_searchString isEqualToString:@""]) return [super arrangeObjects:objects];
		
	NSString *searchString = [[_searchString copy] autorelease];
	NSMutableArray *resultArray = [NSMutableArray array];
	NSEnumerator *enumerator = [objects objectEnumerator];
	T2ThreadFace *object;
	while (object = [enumerator nextObject]) {
		CFStringRef title = (CFStringRef)[object title];
		CFRange foundRange = CFStringFind(title, (CFStringRef)searchString, _compareOptionFlags);
		if (foundRange.location != kCFNotFound) {
			[resultArray addObject:object];
		}
	}
	return [super arrangeObjects:resultArray];
}
@end

//
//  THT2ResAdditions.m
//  Thousand
//
//  Created by R. Natori on 06/08/22.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "THT2ResAdditions.h"


@implementation T2Res (THT2ResAdditions)
-(NSString *)forwardLinkedResNumberString {
	if (_forwardResIndexes && [_forwardResIndexes count]>0) {
		return [NSString stringWithFormat:@"<a href=\"internal://trace/1/resNumber/%d\">%d +%d</a>",
			_resNumber, _resNumber, [_forwardResIndexes count]];
	}
	return [NSString stringWithFormat:@"%d", _resNumber];
}

-(NSString *)tripLinkedName {
	if (_trip) {
		unsigned count = [self tripCount];
		if (count > 1) {
			return [NSString stringWithFormat:@"<a href=\"internal://trip/%@\">%@ (%d)</a>",
				[self escapedTrip], _name, count];
		} else {
			return [NSString stringWithFormat:@"%@ (1)", _name];
		}
	}
	return _name;
}

-(NSString *)linkedIdentifier {
	if (_identifier) {
		unsigned count = [self identifierCount];
		if (count > 1) {
			return [NSString stringWithFormat:@"<a href=\"internal://identifier/%@\">ID: %@ (%d)</a>",
				[self escapedIdentifier], _identifier, count];
		} else {
			return [NSString stringWithFormat:@"ID: %@ (1)", _identifier];
		}
	}
	return nil;
}

-(NSString *)linkedBeString {
	if (_beString && _thread) {
		unsigned beDelimiterIndex = [_beString rangeOfString:@"-" options:NSLiteralSearch].location;
		unsigned beStringLength = [_beString length];
		if (beDelimiterIndex != NSNotFound && beDelimiterIndex>0 && beDelimiterIndex+1<beStringLength) {
			NSString *beID = [_beString substringToIndex:beDelimiterIndex];
			NSString *beLevel = [_beString substringFromIndex:beDelimiterIndex+1];
			
			NSString *browserURLString = [_thread webBrowserURLString];
			if (browserURLString) {
				return [NSString stringWithFormat:
								 @"<a href=\"http://be.2ch.net/test/p.php?i=%@&u=d:%@%d\">Be:%@</a>",
					beID, browserURLString, _resNumber, beLevel];
			}
		}
	}
	return nil;
}
@end

//
//  T2NSColorAdditions.m
//  Thousand
//
//  Created by R. Natori on 平成 20/02/06.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "T2NSColorAdditions.h"


@implementation NSColor (T2NSColorAdditions)
-(NSString *)webDecimalRGBRepresentation {
	float red = [self redComponent];
	float green = [self greenComponent];
	float blue = [self blueComponent];
	return [NSString stringWithFormat:@"rgb(%d,%d,%d)", (int)(red*255.0), (int)(green*255.0), (int)(blue*255.0)];
}
@end

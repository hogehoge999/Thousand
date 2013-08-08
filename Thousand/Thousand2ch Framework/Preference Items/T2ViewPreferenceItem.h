//
//  T2ViewPreferenceItem.h
//  Thousand
//
//  Created by R. Natori on 06/10/20.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2PreferenceItem.h"

@interface T2ViewPreferenceItem : T2PreferenceItem {
	NSView *_view;
}

-(void)setView:(NSView *)view ;
-(NSView *)view ;
@end

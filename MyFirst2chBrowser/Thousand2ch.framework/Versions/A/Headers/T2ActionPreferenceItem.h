//
//  T2ActionPreferenceItem.h
//  Thousand
//
//  Created by R. Natori on 06/10/21.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2PreferenceItem.h"


@interface T2ActionPreferenceItem : T2PreferenceItem {
	
	SEL _action;
	id _target;
}

-(void)setAction:(SEL)selector ;
-(SEL)action ;
-(void)setTarget:(id)object ;
-(id)target ;
@end

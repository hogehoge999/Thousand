//
//  T2ListPreferenceItem.h
//  Thousand
//
//  Created by R. Natori on 06/10/20.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2PreferenceItem.h"

@interface T2ListPreferenceItem : T2PreferenceItem {
	NSArray *_listItems;
}
-(void)setListItems:(NSArray *)listItems ;
-(NSArray *)listItems ;
@end

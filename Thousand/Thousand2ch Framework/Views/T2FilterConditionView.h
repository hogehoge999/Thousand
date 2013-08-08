//
//  T2FilterConditionView.h
//  Thousand
//
//  Created by R. Natori on 平成 20/02/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2FilterCondition.h"

@interface T2FilterConditionView : NSView {
	NSPopUpButton	*_filterNamePopUpButton ;
	NSPopUpButton	*_filterOperatorPopUpButton ;
	NSPopUpButton	*_filterParameterPopUpButton ;
	NSTextField		*_filterParameterTextField ;
	NSTextField		*_filterAppendixTextField ;
}
-(IBAction)filterNameChanged ;
-(IBAction)filterOperatorChanged ;
@end

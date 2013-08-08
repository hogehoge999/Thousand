//
//  TFInputWindowController.m
//  THFind2ch
//
//  Created by R. Natori on  07/02/20.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TFInputWindowController.h"


@implementation TFInputWindowController

+(id)runModalInputWindowController {
	id inputWindowController = [[self alloc] initInputWindowController];
	[inputWindowController runModal];
	return inputWindowController;
}
	
-(id)initInputWindowController {
	self = [super initWithWindowNibName:@"TFInputWindow"];
	return self;
}

	//Accessors
-(void)setInputString:(NSString *)aString {
	setObjectWithRetain(_inputString, aString);
}
-(NSString *)inputString { return _inputString; }
-(int)button { return _button; }

	//Methods
-(int)runModal {
	return [NSApp runModalForWindow:[self window]];
}

	//Actions
-(IBAction)okAction:(id)sender {
	_button = NSOKButton;
	[self setInputString:[_textField stringValue]];
	[[self window] orderOut:nil];
	[NSApp stopModal];
}
-(IBAction)cancelAction:(id)sender {
	_button = NSCancelButton;
	[[self window] orderOut:nil];
	[NSApp stopModal];
}
@end

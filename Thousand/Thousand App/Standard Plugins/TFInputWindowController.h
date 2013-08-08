//
//  TFInputWindowController.h
//  THFind2ch
//
//  Created by R. Natori on  07/02/20.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface TFInputWindowController : NSWindowController {
	NSString *_inputString;
	int _button;
	
	IBOutlet NSTextField *_textField;
}

+(id)runModalInputWindowController ;
-(id)initInputWindowController ;

//Accessors
-(void)setInputString:(NSString *)aString ;
-(NSString *)inputString ;
-(int)button ;

//Methods
-(int)runModal ;

//Actions
-(IBAction)okAction:(id)sender ;
-(IBAction)cancelAction:(id)sender ;
@end

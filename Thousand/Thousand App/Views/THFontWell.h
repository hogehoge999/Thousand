//
//  THFontWell.h
//  THFontWell
//
//  Created by R. Natori on 06/12/15.
//

#import <Cocoa/Cocoa.h>


@interface THFontWell : NSButton {
	NSString	*_TH_keyPath;
	id			_TH_controller;
	
	unsigned	_validModeMask;
}


-(void)activate:(BOOL)exclusive ;
-(void)deactivate ;
+(void)deactivateAllFontWells ;
-(BOOL)isActive ;

-(void)setValidModeMask:(unsigned)validModeMask ;
-(unsigned)validModeMask ;
@end

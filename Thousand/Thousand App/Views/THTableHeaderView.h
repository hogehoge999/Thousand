//
//  THTableHeaderView.h
//  Thousand
//
//  Created by R. Natori on 05/10/23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface THTableHeaderView : NSTableHeaderView {
	NSPopUpButton *_sorterPopUpButton;
}
-(void)setPopUpButton:(NSPopUpButton *)popUpButton ;
-(NSPopUpButton *)popUpButton ;

-(void)fitPopUpButton ;
@end

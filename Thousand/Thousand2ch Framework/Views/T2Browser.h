//
//  T2Browser.h
//  Thousand
//
//  Created by R. Natori on 08/08/12.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "T2UtilityHeader.h"

extern  NSString *T2BrowserRowPboardType;

@interface T2Browser : NSBrowser {
	NSScrollView *_T2Browser_scrollView;
	NSBorderType _T2Browser_borderType;
	NSFont *_rowFont;
	float _rowHeight;
}
- (void)setBorderType:(NSBorderType)borderType ;
- (NSBorderType)borderType ;

-(void)setRowFont:(NSFont *)font ;
-(NSFont *)rowFont ;
-(void)setRowHeight:(float)height ;
-(float)rowHeight ;

-(void)dragWillStartFromColumn:(int)column row:(int)row ;
@end

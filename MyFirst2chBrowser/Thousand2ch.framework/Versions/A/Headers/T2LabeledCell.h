//
//  T2LabeledTextFieldCell.h
//  Thousand
//
//  Created by R. Natori on 平成 20/01/14.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

extern NSString *T2LabelColorsChangedNotification;

@interface T2LabeledCellManager : NSObject {
}
+(id)sharedManager ;

-(void)flushCachedObjects ;

-(void)setLabelColors:(NSArray *)colors labelNames:(NSArray *)names ;
-(void)setLabelColors:(NSArray *)colors ;
-(NSArray *)labelColors ;
-(void)setLabelNames:(NSArray *)names ;
-(NSArray *)labelNames ;

-(NSArray *)lightLabelColors ;
-(NSArray *)selectedLabelColors ;
-(NSArray *)secondSelectedLabelColors ;

-(NSArray *)smallColorImages ;
-(NSArray *)menuItems ;

-(void)setLabelPopUpBaseImage:(NSImage *)anImage ;
-(NSImage *)labelPopUpBaseImage ;
-(void)setLabelPopUpMaskImage:(NSImage *)anImage ;
-(NSImage *)labelPopUpMaskImage ;

-(NSArray *)labelPopUpImages ;
-(NSImage *)popUpImageForLabel:(int)label ;

+(void)registerInvalidationOfCachedControlView ;
+(void)invalidateCachedControlView:(id)object ;

+(void)drawWithFrame:(NSRect)cellFrame withLabel:(int)label inView:(NSView *)controlView ;
void T2Label_drawWithFrame_withLabel_inView(NSRect cellFrame, int label, NSView *controlView) ;
void T2Label_drawWithFrame_withLabel_inView_highlighted(NSRect cellFrame, int label, NSView *controlView, BOOL highlighted) ;
+(NSColor *)highlightColorWithLabel:(int)label inView:(NSView *)controlView ;
NSColor *T2Label_highlightColor_withLabel_inView(int label, NSView *controlView) ;
@end

@protocol T2Labeling
-(void)setLabel:(int)label ;
-(int)label ;
@end

@interface T2LabeledTextFieldCell : NSTextFieldCell <T2Labeling> {
	int _label;
}
@end


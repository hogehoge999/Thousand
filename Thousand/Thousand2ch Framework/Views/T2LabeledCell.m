//
//  T2LabeledTextFieldCell.m
//  Thousand
//
//  Created by R. Natori on 平成 20/01/14.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "T2LabeledCell.h"

NSString *T2LabelColorsChangedNotification = @"T2LabelColorsChangedNotificationName";

static float __lightLabelColorFraction = 0.6;
static float __selectedLabelColorFraction = 0.5;
static float __secondSelectedLabelColorFraction = 0.5;

static float __smallImageWidth = 16;
static float __smallImageHeight = 12;

static unsigned __colorsCount = 0;
static NSArray *__labelColors = nil;
static NSArray *__lightLabelColors = nil;
static NSArray *__selectedLabelColors = nil;
static NSArray *__secondSelectedLabelColors = nil;

static NSArray *__labelNames = nil;

static NSArray *__smallColorImages = nil;

static NSImage *__labelPopUpBaseImage = nil;
static NSImage *__labelPopUpMaskImage = nil;
static NSArray *__labelPopUpImages = nil;

static NSView *__cachedControlView = nil;
static BOOL __cachedControlViewIsKeyed = NO;
static BOOL __invalidationRegistered = NO;
static NSArray *__runLoopMode = nil;

static T2LabeledCellManager *__sharedManager = nil;

@implementation T2LabeledCellManager

+(id)sharedManager {
	if (!__sharedManager) {
		__sharedManager = [[T2LabeledCellManager alloc] init];
	}
	return __sharedManager;
}
-(id)init {
	self = [super init];
	if (!__sharedManager) {
		self = [super init];
		[self setLabelColors:[NSArray arrayWithObjects:
							  [NSColor redColor],
							  [NSColor orangeColor],
							  [NSColor yellowColor],
							  [NSColor greenColor],
							  [NSColor blueColor],
							  [NSColor purpleColor],
							  [NSColor grayColor],
							  [NSColor blackColor], nil]];
		[self setLabelNames:[NSArray arrayWithObjects:
							 @"None",
							 @"Red",
							 @"Orange",
							 @"Yellow",
							 @"Green",
							 @"Blue",
							 @"Purple",
							 @"Gray",
							 @"Black", nil]];
		__runLoopMode = [[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, nil];
		__sharedManager = self;
	} else {
		[self autorelease];
	}
	return __sharedManager;
}
-(oneway void)release {
	if (self != __sharedManager) {
		[super release];
	}
}

-(void)flushCachedObjects {
	
	id smallColorImages = __smallColorImages;
	__smallColorImages = nil;
	[smallColorImages release];
	
	id labelPopUpImages = __labelPopUpImages;
	__labelPopUpImages = nil;
	[labelPopUpImages release];
}

-(void)setLabelColors:(NSArray *)colors labelNames:(NSArray *)names {
	if ([colors count]+1 == [names count]) {
		[self setLabelColors:colors];
		[self setLabelNames:names];
		[[NSNotificationCenter defaultCenter] postNotificationName:T2LabelColorsChangedNotification object:self];
	}
}

-(void)setLabelColors:(NSArray *)colors {
	setObjectWithCopy(__labelColors, colors);
	
	NSColor *whiteColor = [NSColor whiteColor];
	NSColor *selectedTintColor = [NSColor darkGrayColor];
	NSColor *notKeyedSelectedTintColor = [NSColor lightGrayColor];
	
	NSMutableArray *lightLabelColors = [NSMutableArray array];
	NSMutableArray *selectedLabelColors = [NSMutableArray array];
	NSMutableArray *secondSelectedLabelColors = [NSMutableArray array];
	
	NSEnumerator *enumerator = [__labelColors objectEnumerator];
	NSColor *color;
	while (color = [enumerator nextObject]) {
		NSColor *paleColor = [color blendedColorWithFraction:__lightLabelColorFraction
															ofColor:whiteColor];
		[lightLabelColors addObject:paleColor];
		
		NSColor *selectedLabelColor = [color blendedColorWithFraction:__selectedLabelColorFraction
															  ofColor:selectedTintColor];
		[selectedLabelColors addObject:selectedLabelColor];
		
		NSColor *secondSelectedLabelColor = [paleColor blendedColorWithFraction:__secondSelectedLabelColorFraction
																				 ofColor:notKeyedSelectedTintColor];
		[secondSelectedLabelColors addObject:secondSelectedLabelColor];
	}
	[__lightLabelColors autorelease];
	__lightLabelColors = [lightLabelColors copy];
	[__selectedLabelColors autorelease];
	__selectedLabelColors = [selectedLabelColors copy];
	[__secondSelectedLabelColors autorelease];
	__secondSelectedLabelColors = [secondSelectedLabelColors copy];
	
	__colorsCount = [__labelColors count];
	[self flushCachedObjects];
}
-(NSArray *)labelColors {
	return __labelColors;
}
-(NSArray *)lightLabelColors { return __lightLabelColors; }
-(NSArray *)selectedLabelColors { return __selectedLabelColors; }
-(NSArray *)secondSelectedLabelColors { return __secondSelectedLabelColors; }

-(void)setLabelNames:(NSArray *)names {
	setObjectWithCopy(__labelNames, names);
}
-(NSArray *)labelNames { return __labelNames; }

-(NSArray *)smallColorImages {
	if (!__smallColorImages) {
		NSMutableArray *array = [NSMutableArray array];
		NSEnumerator *enumerator = [__labelColors objectEnumerator];
		NSColor *color;
		while (color = [enumerator nextObject]) {
			NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(__smallImageWidth, __smallImageHeight)] autorelease];
			[image lockFocus];
			[color set];
			NSRectFill(NSMakeRect(0, 0, __smallImageWidth, __smallImageHeight));
			[image unlockFocus];
			[array addObject:image];
		}
		__smallColorImages = [array copy];
	}
	return __smallColorImages;
}
-(NSArray *)menuItems {
	NSMutableArray *menuItems = [NSMutableArray array];
	NSArray *smallColorImages = [self smallColorImages];
	NSArray *labelNames = [self labelNames];
	
	unsigned i, count = [labelNames count];
	for (i=0; i<count; i++) {
		NSString *name = [labelNames objectAtIndex:i];
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:name
														   action:@selector(selectLabelAction:)
													keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:[NSNumber numberWithUnsignedInt:i]];
		if (i>0) {
			NSImage *image = [smallColorImages objectAtIndex:i-1];
			[menuItem setImage:image];
		}
		[menuItems addObject:menuItem];
	}
	return [[menuItems copy] autorelease];
}

-(void)setLabelPopUpBaseImage:(NSImage *)anImage {
	setObjectWithRetain(__labelPopUpBaseImage, anImage);
	
	id labelPopUpImages = __labelPopUpImages;
	__labelPopUpImages = nil;
	[labelPopUpImages release];
}
-(NSImage *)labelPopUpBaseImage { return __labelPopUpBaseImage; }
-(void)setLabelPopUpMaskImage:(NSImage *)anImage {
	setObjectWithRetain(__labelPopUpMaskImage, anImage);
	
	id labelPopUpImages = __labelPopUpImages;
	__labelPopUpImages = nil;
	[labelPopUpImages release];
}
-(NSImage *)labelPopUpMaskImage { return __labelPopUpMaskImage; }

-(NSArray *)labelPopUpImages {
	if (!__labelPopUpImages) {
		if (__labelPopUpBaseImage && __labelPopUpMaskImage) {
			NSSize size = [__labelPopUpBaseImage size];
			NSRect rect = (NSMakeRect(0, 0, size.width, size.height));
			
			NSMutableArray *labelPopUpImages = [NSMutableArray array];
			NSEnumerator *colorEnumerator = [[self lightLabelColors] objectEnumerator];
			NSColor *color;
			while (color = [colorEnumerator nextObject]) {
				NSImage *colorImage = [[__labelPopUpMaskImage copy] autorelease];
				[colorImage lockFocus];
				[color set];
				NSRectFill(rect);
				[__labelPopUpMaskImage drawAtPoint:NSMakePoint(0, 0)
										  fromRect:rect
										 operation:NSCompositeDestinationIn
										  fraction:1.0];
				[colorImage unlockFocus];
				
				NSImage *baseImage = [[__labelPopUpBaseImage copy] autorelease];
				[baseImage lockFocus];
				[colorImage drawAtPoint:NSMakePoint(0, 0)
							   fromRect:rect
							  operation:NSCompositeSourceOver
							   fraction:1.0];
				[baseImage unlockFocus];
				
				[labelPopUpImages addObject:baseImage];
			}
			__labelPopUpImages = [labelPopUpImages copy];
		}
	}
	return __labelPopUpImages;
}
-(NSImage *)popUpImageForLabel:(int)label {
	if (label <= 0 || label > [__labelColors count]) {
		return __labelPopUpBaseImage;
	}
	NSArray *images = [self labelPopUpImages];
	if (!images) return __labelPopUpBaseImage;
	return [images objectAtIndex:label-1];
}

+(void)registerInvalidationOfCachedControlView {
	if (!__invalidationRegistered) {
		[[NSRunLoop currentRunLoop] performSelector:@selector(invalidateCachedControlView:) target:self
										   argument:nil order:1000
											  modes:__runLoopMode];
		__invalidationRegistered = YES;
	}
}
+(void)invalidateCachedControlView:(id)object {
	__cachedControlView = nil;
	__cachedControlViewIsKeyed = NO;
	__invalidationRegistered = NO;
}

+(void)drawWithFrame:(NSRect)cellFrame withLabel:(int)label inView:(NSView *)controlView {
	T2Label_drawWithFrame_withLabel_inView(cellFrame, label, controlView);
}
void T2Label_drawWithFrame_withLabel_inView(NSRect cellFrame, int label, NSView *controlView) {
	if (label > 0 && label < __colorsCount+1) {
		
		NSRect wideRect = cellFrame;
		wideRect.origin.x -= 1.0;
		wideRect.size.width +=3.0;
		wideRect.origin.y -= 1.0;
		wideRect.size.height += 1.0;
		
		[[__lightLabelColors objectAtIndex:label-1] set];
		NSRectFill(wideRect);
	}
}
void T2Label_drawWithFrame_withLabel_inView_highlighted(NSRect cellFrame, int label, NSView *controlView, BOOL highlighted) {
	if (label > 0 && label < __colorsCount+1) {
		
		NSRect wideRect = cellFrame;
		wideRect.origin.x -= 1.0;
		wideRect.size.width +=3.0;
		wideRect.origin.y -= 1.0;
		wideRect.size.height += 1.0;
		
		if (highlighted)
			[T2Label_highlightColor_withLabel_inView(label, controlView) set];
		else
			[[__lightLabelColors objectAtIndex:label-1] set];
		
		NSRectFill(wideRect);
		//[NSBezierPath fillRect:wideRect];
	}
}
+(NSColor *)highlightColorWithLabel:(int)label inView:(NSView *)controlView {
	return T2Label_highlightColor_withLabel_inView(label, controlView);
}
NSColor *T2Label_highlightColor_withLabel_inView(int label, NSView *controlView) {
	if (label > 0 && label < __colorsCount+1) {
		if (controlView != __cachedControlView) {
			if (!__cachedControlView) {
				[T2LabeledCellManager registerInvalidationOfCachedControlView];
			}
			__cachedControlView = controlView;
			NSWindow *window = [controlView window];
			if ([window isKeyWindow] && [window firstResponder] == controlView) {
				__cachedControlViewIsKeyed = YES;
			} else {
				__cachedControlViewIsKeyed = NO;
			}
		}
		if (__cachedControlViewIsKeyed) {
			return [__selectedLabelColors objectAtIndex:label-1];
		} else {
			return [__secondSelectedLabelColors objectAtIndex:label-1];
		}
	}
	return nil;
}

@end


@implementation T2LabeledTextFieldCell
+(void)initialize {
	[T2LabeledCellManager sharedManager];
}

-(id)init {
	self = [super init];
	_label = 0;
	return self;
}
-(void)setLabel:(int)label { _label = label; }
-(int)label { return _label; }


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	T2Label_drawWithFrame_withLabel_inView_highlighted(cellFrame, _label, controlView, [self isHighlighted]);
	[super drawWithFrame:cellFrame inView:controlView];
}

/*
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	T2Label_drawWithFrame_withLabel_inView_highlighted(cellFrame, _label, controlView, [self isHighlighted]);
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}
*/

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSColor *color = T2Label_highlightColor_withLabel_inView(_label, controlView);
	if (!color)
		color = [super highlightColorWithFrame:cellFrame inView:controlView ];
	return color;
}

@end


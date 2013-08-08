//
//  THImagePopUpButton.m
//  Thousand
//
//  Created by R. Natori on 平成 20/04/02.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "THImagePopUpButton.h"


@implementation THImagePopUpButton
+ (Class)cellClass {
	return [THImagePopUpButtonCell class];
}

- (BOOL)isFlipped { return NO; }

+(id)imagePopUpButtonForToolBar:(NSToolbar *)toolBar {
	THImagePopUpButton *imagePopUpButton = [[[self alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)] autorelease];
	[imagePopUpButton setAutoresizingMask:NSViewNotSizable];
	[imagePopUpButton setBordered:NO];
	[imagePopUpButton setPullsDown:YES];
	[(THImagePopUpButtonCell *)[imagePopUpButton cell] setUsesItemFromMenu:NO];
	[imagePopUpButton setToolBar:toolBar];
	return imagePopUpButton;
}
/*
-(void)setFrame:(NSRect)frame {
	if (frame.size.height < 32) {
		if ([_toolBar sizeMode] != NSToolbarSizeModeSmall) {
			frame.size.height = 32;
			//frame.origin.y -= 8;
		}
	}
	[super setFrame:frame];
}


- (void)setFrameSize:(NSSize)newSize {
	newSize.height = 32;
	if (_toolBar) {
		if ([_toolBar sizeMode] == NSToolbarSizeModeSmall) {
			newSize.height = 24;
		}
	}
	[super setFrameSize:newSize];
}

- (void)setFrameOrigin:(NSPoint)newOrigin {
	NSRect selfFrame = [self frame];
	NSLog(@"%f", newOrigin.y);
	if ([_toolBar sizeMode] != NSToolbarSizeModeSmall && newOrigin.y == 17.0) {
		newOrigin.y -= 4;
		_originFixed = YES;
	}
	//}
	[super setFrameOrigin:newOrigin];
}
*/

-(void)setToolBar:(NSToolbar *)toolBar {
	_toolBar = toolBar;
}
-(NSToolbar *)toolBar { return _toolBar; }
-(void)setImage:(NSImage *)anImage {
	[(THImagePopUpButtonCell *)[self cell] setImageForPopUpButtonCell:anImage];
}
-(NSImage *)image { return [(THImagePopUpButtonCell *)[self cell] imageForPopUpButtonCell]; }
@end

@implementation THImagePopUpButtonCell

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if ([decoder isKindOfClass:[NSKeyedUnarchiver class]]) {
		[self setImageForPopUpButtonCell:[(NSKeyedUnarchiver *)decoder decodeObjectForKey:@"imageForPopUpButtonCell"]];
	} else {
		[self setImageForPopUpButtonCell:[decoder decodeObject]];
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	if ([encoder isKindOfClass:[NSKeyedArchiver class]]) {
		[(NSKeyedArchiver *)encoder encodeObject:[self imageForPopUpButtonCell] forKey:@"imageForPopUpButtonCell"];
	} else {
		[encoder encodeObject:[self imageForPopUpButtonCell]];
	}
}

-(void)dealloc {
	[_imageForPopUpButtonCell release];
	[super dealloc];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSImage *image = _imageForPopUpButtonCell;
	if (!image) {
		[super drawWithFrame:cellFrame inView:controlView];
		return;
	}
	NSSize imageSize = [image size];
	float ratio = imageSize.width / imageSize.height;
	
	NSRect destinationRect = cellFrame;
	destinationRect.size.width = (int)(cellFrame.size.height * ratio);
	destinationRect.origin.x += (int)((cellFrame.size.width - destinationRect.size.width)/2);
	
	if ([self isHighlighted]) {
		[image drawInRect:destinationRect
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeXOR
				 fraction:1.0];
		[image drawInRect:destinationRect
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeSourceOver
				 fraction:0.5];
	} else if ([self isEnabled]) {
		[image drawInRect:destinationRect
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
	} else {
		[image drawInRect:destinationRect
				 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				operation:NSCompositeSourceOver
				 fraction:0.5];
	}
}

-(void)setImageForPopUpButtonCell:(NSImage *)anImage {
	setObjectWithRetain(_imageForPopUpButtonCell, anImage);
	[[self controlView] setNeedsDisplay:YES];
}
-(NSImage *)imageForPopUpButtonCell { return _imageForPopUpButtonCell; }
@end
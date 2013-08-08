//
//  T2PluginPrefView.m
//  Thousand
//
//  Created by R. Natori on 06/10/02.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2PluginPrefView.h"
#import "T2PreferenceItem.h"
#import "T2PluginProtocols.h"
#import "T2PluginManager.h"

@implementation T2PluginPrefView

+(void)initialize {
	[self exposeBinding:@"plugin"];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
	
	NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:[self bounds]] autorelease];
	[scrollView setHasHorizontalScroller:NO];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setAutohidesScrollers:YES];
	[scrollView setDrawsBackground:NO];
	[self addSubview:scrollView];
	
	_pluginPrefInternalView = [[T2PluginPrefInternalView alloc] initWithFrame:[scrollView bounds]];
	[scrollView setDocumentView:_pluginPrefInternalView];
	
    return self;
}
-(void)dealloc {
	[_pluginPrefInternalView release];
	[super dealloc];
}

-(void)setPlugin:(id <NSObject>)plugin { [_pluginPrefInternalView setPlugin:plugin]; }
-(id <NSObject>)plugin { return [_pluginPrefInternalView plugin]; }

-(void)setPreferenceItemsSelector:(SEL)selector { [_pluginPrefInternalView setPreferenceItemsSelector:selector]; }
-(SEL)preferenceItemsSelector { return [_pluginPrefInternalView preferenceItemsSelector]; }

-(void)setDisplayInfo:(BOOL)aBool { [_pluginPrefInternalView setDisplayInfo:aBool]; }
-(BOOL)displayInfo { return [_pluginPrefInternalView displayInfo]; }

-(T2PluginPrefInternalView *)pluginPrefInternalView { return _pluginPrefInternalView; }

@end

@implementation T2PluginPrefInternalView

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
    if (!self) return nil;
	
	_preferenceItemsSelector = @selector(preferenceItems);
	_bindingController = [[NSObjectController alloc] init];
	return self;
}

-(void)dealloc {
	[_bindingController setContent:nil];
	[_bindingController release];
	[super dealloc];
}

-(void)awakeFromNib {
	if (!_bindingController)
		_bindingController = [[NSObjectController alloc] init];
}

- (BOOL)isFlipped { return YES; }

-(void)setPlugin:(id <NSObject>)plugin {
	NSWindow *myWindow = [self window];
	if (myWindow) [myWindow endEditingFor:nil];
	
	[plugin retain];
	[_plugin release];
	_plugin = plugin;
	
	[_bindingController setContent:nil];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *oldViews = [[[self subviews] copy] autorelease];
	if (oldViews && [oldViews count]>0) {
		NSEnumerator *oldViewsEnumerator = [oldViews objectEnumerator];
		NSView *oldView;
		while (oldView = [oldViewsEnumerator nextObject]) {
			[oldView removeFromSuperview];
		}
	}
	[pool release];
	
	if (!plugin || ![[plugin class] conformsToProtocol:@protocol(T2PluginInterface_v100)]) return;
	[_bindingController setContent:plugin];
	
	
	NSMutableArray *prefItems = [NSMutableArray array];
	if (_displayInfo) {
		[prefItems addObjectsFromArray:[NSArray arrayWithObject:
			[T2PreferenceItem topTitleItemWithTitle:[(id <T2PluginInterface_v100>)plugin localizedName]
											   info:[(id <T2PluginInterface_v100>)plugin localizedPluginInfo]]]];
		if ([plugin respondsToSelector:_preferenceItemsSelector]) {
			[prefItems addObject:[T2PreferenceItem separateLineItem]];
		}
	}
	if ([plugin respondsToSelector:_preferenceItemsSelector]) {
		[prefItems addObjectsFromArray:(NSArray *)[plugin performSelector:_preferenceItemsSelector]];
	}
	
	if ([prefItems count] == 0) return;
	NSEnumerator *prefItemsEnumerator = [prefItems objectEnumerator];
	T2PreferenceItem *prefItem;
	float verticalLoc = 10.0;
	float superViewWidth = [self frame].size.width ;
	while (prefItem = [prefItemsEnumerator nextObject]) {
		NSArray *views = [prefItem boundViewsWithBasePath:@"selection"
											   controller:_bindingController superViewWidth:superViewWidth];
		if (!views || [views count]==0) return;
		NSEnumerator *viewsEnumerator = [views objectEnumerator];
		NSView *view = [viewsEnumerator nextObject];
		NSRect frame = [view frame];
		float verticalDelta = verticalLoc - frame.origin.y;
		frame.origin.y += verticalDelta;
		[view setFrame:frame];
		[self addSubview:view];
		
		while (view = [viewsEnumerator nextObject]) {
			frame = [view frame];
			frame.origin.y += verticalDelta;
			[view setFrame:frame];
			[self addSubview:view];
		}
		verticalLoc = frame.size.height + frame.origin.y + 10.0;
	}
	NSRect frame = [self frame];
	frame.size.height = verticalLoc;
	[self setFrame:frame];
	
	
}
-(id <NSObject>)plugin { return _plugin; }
-(void)setPreferenceItemsSelector:(SEL)selector { _preferenceItemsSelector = selector; }
-(SEL)preferenceItemsSelector { return _preferenceItemsSelector; }

-(void)setDisplayInfo:(BOOL)aBool { _displayInfo = aBool; }
-(BOOL)displayInfo { return _displayInfo; }
@end

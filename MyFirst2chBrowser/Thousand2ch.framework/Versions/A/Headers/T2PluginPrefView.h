//
//  T2PluginPrefView.h
//  Thousand
//
//  Created by R. Natori on 06/10/02.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class T2PluginPrefInternalView;

@interface T2PluginPrefView : NSView {
	T2PluginPrefInternalView	*_pluginPrefInternalView;
}

-(void)setPlugin:(id <NSObject>)plugin ;
-(id <NSObject>)plugin ;

-(void)setPreferenceItemsSelector:(SEL)selector ;
-(SEL)preferenceItemsSelector ;

-(void)setDisplayInfo:(BOOL)aBool ;
-(BOOL)displayInfo ;

-(T2PluginPrefInternalView *)pluginPrefInternalView ;
@end



@interface T2PluginPrefInternalView : NSView {
	id <NSObject> _plugin;
	SEL _preferenceItemsSelector;
	NSObjectController *_bindingController;
	
	BOOL _displayInfo;
}

-(void)setPlugin:(id <NSObject>)plugin ;
-(id <NSObject>)plugin ;
-(void)setPreferenceItemsSelector:(SEL)selector ;
-(SEL)preferenceItemsSelector ;

-(void)setDisplayInfo:(BOOL)aBool ;
-(BOOL)displayInfo ;
@end
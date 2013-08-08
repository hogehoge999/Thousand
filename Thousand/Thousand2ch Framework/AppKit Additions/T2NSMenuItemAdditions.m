//
//  T2NSMenuItemAdditions.m
//  Thousand
//
//  Created by R. Natori on 08/05/16.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "T2NSMenuItemAdditions.h"


@implementation NSMenuItem (T2NSMenuItemAdditions)

+(id)menuItemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent {
	return [[[self alloc] initWithTitle:title action:action keyEquivalent:keyEquivalent] autorelease];
}
+(id)indentedMenuItemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent {
	NSMenuItem *menuItem = [self menuItemWithTitle:title action:action keyEquivalent:keyEquivalent];
	[menuItem setIndentationLevel:1];
	return menuItem;
}

+(id)menuItemWithTitle:(NSString *)title action:(SEL)action target:(id)target {
	NSMenuItem *menuItem = [self menuItemWithTitle:title action:action keyEquivalent:@""];
	[menuItem setTarget:target];
	return menuItem;
}
+(id)indentedMenuItemWithTitle:(NSString *)title action:(SEL)action target:(id)target {
	NSMenuItem *menuItem = [self menuItemWithTitle:title action:action keyEquivalent:@""];
	[menuItem setTarget:target];
	[menuItem setIndentationLevel:1];
	return menuItem;
}

+(id)menuItemWithTitle:(NSString *)title action:(SEL)action target:(id)target representedObject:(id)representedObject {
	NSMenuItem *menuItem = [self menuItemWithTitle:title action:action target:target];
	[menuItem setRepresentedObject:representedObject];
	return menuItem;
}
+(id)indentedMenuItemWithTitle:(NSString *)title action:(SEL)action target:(id)target representedObject:(id)representedObject {
	NSMenuItem *menuItem = [self indentedMenuItemWithTitle:title action:action target:target];
	[menuItem setRepresentedObject:representedObject];
	return menuItem;
}
@end

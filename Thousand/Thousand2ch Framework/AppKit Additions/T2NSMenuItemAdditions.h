//
//  T2NSMenuItemAdditions.h
//  Thousand
//
//  Created by R. Natori on 08/05/16.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMenuItem (T2NSMenuItemAdditions)
+(id)menuItemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent ;
+(id)indentedMenuItemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent ;

+(id)menuItemWithTitle:(NSString *)title action:(SEL)action target:(id)target ;
+(id)indentedMenuItemWithTitle:(NSString *)title action:(SEL)action target:(id)target ;

+(id)menuItemWithTitle:(NSString *)title action:(SEL)action target:(id)target representedObject:(id)representedObject ;
+(id)indentedMenuItemWithTitle:(NSString *)title action:(SEL)action target:(id)target representedObject:(id)representedObject ;
@end

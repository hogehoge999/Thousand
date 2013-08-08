//
//  THT2TableViewAdditions.m
//  Thousand
//
//  Created by R. Natori on 08/12/20.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "THT2TableViewAdditions.h"


@implementation T2TableView (THT2TableViewAdditions)

+(void)setVisible:(BOOL)visible ofTableColumnWithIdentifier:(NSString *)tableColumnIdentifier inDefaultsName:(NSString *)defaultsName {
	if (!defaultsName || !tableColumnIdentifier) return;
	defaultsName = [@"THTableView_" stringByAppendingString:defaultsName];
	
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *tableColumnSettings = [standardUserDefaults objectForKey:defaultsName];
	NSArray *identifiers = [tableColumnSettings valueForKey:@"identifier"];
	
	NSArray *newTableColumnSettings = nil;
	
	if (visible) {
		if (![identifiers containsObject:tableColumnIdentifier]) {
			NSDictionary *dictionary = [NSDictionary dictionaryWithObject:tableColumnIdentifier forKey:@"identifier"];
			newTableColumnSettings = [tableColumnSettings arrayByAddingObject:dictionary];
		}
	} else {
		unsigned index = [identifiers indexOfObject:tableColumnIdentifier];
		if (index != NSNotFound) {
			NSMutableArray *tempTableColumnSettings = [[tableColumnSettings mutableCopy] autorelease];
			[tempTableColumnSettings removeObjectAtIndex:index];
			newTableColumnSettings = [[tempTableColumnSettings copy] autorelease];
		}
	}
	if (newTableColumnSettings) {
		[standardUserDefaults setObject:newTableColumnSettings forKey:defaultsName];
	}
}

+(BOOL)visibleOfTableColumnWithIdentifier:(NSString *)tableColumnIdentifier inDefaultsName:(NSString *)defaultsName {
	if (!defaultsName || !tableColumnIdentifier) return NO;
	defaultsName = [@"THTableView_" stringByAppendingString:defaultsName];
	
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *tableColumnSettings = [standardUserDefaults objectForKey:defaultsName];
	if (tableColumnSettings) {
		NSArray *identifiers = [tableColumnSettings valueForKey:@"identifier"];
		return [identifiers containsObject:tableColumnIdentifier];
	}
	return YES;
}

-(void)loadTHTableViewDefaultsWithName:(NSString *)defaultsName {
	if (!defaultsName) return;
	defaultsName = [@"THTableView_" stringByAppendingString:defaultsName];
	
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *tableColumnSettings = [standardUserDefaults objectForKey:defaultsName];
	if (tableColumnSettings)
		[self setTableColumnSettings:tableColumnSettings];
}
-(void)saveTHTableViewDefaultsWithName:(NSString *)defaultsName {
	if (!defaultsName) return;
	defaultsName = [@"THTableView_" stringByAppendingString:defaultsName];
	
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	[standardUserDefaults setObject:[self tableColumnSettings] forKey:defaultsName];
}
@end

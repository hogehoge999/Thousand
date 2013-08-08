//
//  MyAppDelegate.m
//  MyFirst2chBrowser
//
//  Created by 名取 恒平 on 08/05/19.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MyAppDelegate.h"


@implementation MyAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	
	// Thousand 2ch Setup
	T2SetupManager *setupManager = [T2SetupManager sharedManager];
	// Insert Application-specific setup code here
	
	[setupManager setup];
	
	// update 2ch menu
	NSObject <T2ListImporting_v100> *listImporter = (NSObject <T2ListImporting_v100> *)[[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	T2List *list = [[[listImporter rootListFaces] objectAtIndex:0] list];
	[list load];
	
}
@end

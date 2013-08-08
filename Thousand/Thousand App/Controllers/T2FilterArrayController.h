//
//  T2FilterArrayController.h
//  Thousand
//
//  Created by R. Natori on 05/12/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface T2FilterArrayController : NSArrayController {
	NSString *_searchString;
	CFOptionFlags _compareOptionFlags;
}
-(void)setSearchString:(NSString *)searchString ;
-(NSString *)searchString ;
/*
-(void)setCopmpareOptionFlags:(CFOptionFlags)compareOptionFlags ;
-(CFOptionFlags)compareOptionFlags ;
 */
@end

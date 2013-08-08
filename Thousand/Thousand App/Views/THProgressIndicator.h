//
//  THProgressIndicator.h
//  Thousand
//
//  Created by R. Natori on 06/02/12.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface THProgressIndicator : NSProgressIndicator {
	IBOutlet NSTextField *_infoTextField;
	BOOL _isLoaded;
}

@end

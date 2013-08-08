//
//  THCompatibility.h
//  Thousand
//
//  Created by R. Natori on 06/09/30.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface T2List (THCompatibility)
-(void)setList:(NSArray *)anArray ;
-(NSArray *)list;
@end

@interface T2ListHolder : T2IdentifiedObject {
}
@end

@interface T2ThreadListHolder : T2IdentifiedObject {
}
@end

@interface T2BookmarkListHolder : T2IdentifiedObject {
}
@end

@interface T2ThreadListItem : T2IdentifiedObject {
}
@end

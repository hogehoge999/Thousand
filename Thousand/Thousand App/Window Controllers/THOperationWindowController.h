//
//  THOperationWindowController.h
//  Thousand
//
//  Created by R. Natori on 08/11/12.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THOperationWindowController : NSWindowController {
	T2Operation *_operation;
}
+(void)startWatchingOperations ;
+(void)stopWatchingOperations ;
+(id)operationWindowControllerWithOperation:(T2Operation *)operation ;
-(id)initWithOperation:(T2Operation *)operation ;
-(T2Operation *)operation ;

+(void)operationDidStart:(NSNotification *)notification ;
-(void)operationDidFinish:(NSNotification *)notification ;

-(IBAction)cancel:(id)sender ;
@end

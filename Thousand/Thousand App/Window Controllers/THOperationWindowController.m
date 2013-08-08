//
//  THOperationWindowController.m
//  Thousand
//
//  Created by R. Natori on 08/11/12.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "THOperationWindowController.h"

static THOperationWindowController *__sharedOperationWindowController = nil;

@implementation THOperationWindowController

+(void)startWatchingOperations {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(operationDidStart:)
												 name:T2OperationDidStartNotification
											   object:nil];
}
+(void)stopWatchingOperations {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
+(id)operationWindowControllerWithOperation:(T2Operation *)operation {
	return [[[self alloc] initWithOperation:operation] autorelease];
}
-(id)initWithOperation:(T2Operation *)operation {
	self = [self initWithWindowNibName:@"THOperationWindow"];
	[self setShouldCascadeWindows:YES];
	
	[self willChangeValueForKey:@"operation"];
	_operation = [operation retain];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(operationDidFinish:)
												 name:T2OperationDidFinishedNotification
											   object:_operation];
	[self didChangeValueForKey:@"operation"];
	
	[self setWindowFrameAutosaveName:@"operation"];
	return self;
}
-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_operation release];
	[super dealloc];
}
-(T2Operation *)operation { return _operation; }

+(void)operationDidStart:(NSNotification *)notification {
	if (![(T2Operation *)[notification object] visible]) return;
	THOperationWindowController *operationWindowController = 
	[[self operationWindowControllerWithOperation:[notification object]] retain];
	[[operationWindowController window] orderFront:nil];
}
-(void)operationDidFinish:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self willChangeValueForKey:@"operation"];
	[_operation release];
	_operation = nil;
	[self didChangeValueForKey:@"operation"];
	
	[[self window] orderOut:nil];
	[self autorelease];
}

-(IBAction)cancel:(id)sender {
	[_operation cancel];
}
@end

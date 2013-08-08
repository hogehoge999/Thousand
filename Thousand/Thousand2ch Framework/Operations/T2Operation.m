//
//  T2Operation.m
//  Thousand
//
//  Created by R. Natori on 08/11/12.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2Operation.h"
#import "T2UtilityHeader.h"

NSString *T2OperationDidStartNotification = @"T2OperationDidStartNotification";
NSString *T2OperationDidFinishedNotification = @"T2OperationDidFinishedNotification";
NSString *T2OperationUpdatedProgressNotification = @"T2OperationUpdatedProgressNotification";

static NSMutableArray *__runningOperations = nil;

@interface T2Operation (T2OperationPrivate)
-(void)setIsFinished:(BOOL)isFinished ;
-(void)setIsExecuting:(BOOL)isExecuting ;
-(void)postDidStartNotification ;
-(void)postDidEndNotification ;
-(void)postUpdateProgressNotification ;
@end

@implementation T2Operation

+(NSArray *)runningOperations {
	return [[__runningOperations copy] autorelease];
}

-(void)dealloc {
	[_name release];
	[_statusString release];
	[super dealloc];
}

-(BOOL)visible { return NO; }

-(void)setName:(NSString *)name {
	@synchronized(self) {
		setObjectWithRetain(_name, name);
	}
}
-(NSString *)name { return _name; }
-(void)setStatusString:(NSString *)statusString {
	@synchronized(self) {
		setObjectWithRetain(_statusString, statusString);
	}
}
-(NSString *)statusString { return _statusString; }

-(void)setIsCancelled:(BOOL)isCancelled {
	_isCancelled = isCancelled;
}
-(BOOL)isCancelled { return _isCancelled; }
-(void)setIsFinished:(BOOL)isFinished { _isFinished = isFinished; }
-(BOOL)isFinished { return _isFinished; }
-(void)setIsExecuting:(BOOL)isExecuting { _isExecuting = isExecuting; }
-(BOOL)isExecuting { return _isExecuting; }
-(void)setProgress:(float)progress {
	@synchronized(self) {
		_progress = progress;
		[self performSelectorOnMainThread:@selector(postUpdateProgressNotification)
							   withObject:nil waitUntilDone:NO];
	}
}
-(float)progress { return _progress; }

-(void)start {
	if ([self class] == [T2Operation class]) return;
	if (_isExecuting) return;
	[self setIsExecuting:YES];
	[NSThread detachNewThreadSelector:@selector(startInWorkingThread)
							 toTarget:self withObject:nil];
}
-(void)startInWorkingThread {
	if ([self class] == [T2Operation class]) return;
	[NSThread setThreadPriority:0.1];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@synchronized(self) {
		if (!__runningOperations) {
			__runningOperations = [[NSMutableArray alloc] init];
		}
		[__runningOperations addObject:self];
		[self performSelectorOnMainThread:@selector(postDidStartNotification)
							   withObject:nil waitUntilDone:YES];
	}
	
	@try {
		[self main];
	}
	@catch (NSException *exception) {
		NSLog(@"%@", exception);
	}
	@finally {
		
		@synchronized(self) {
			[self setIsExecuting:NO];
			[self performSelectorOnMainThread:@selector(postDidEndNotification)
								   withObject:nil waitUntilDone:NO];
			[__runningOperations removeObject:self];
		}
		
		[pool release];
	}
}
-(void)cancel {
	[self setIsCancelled:YES];
}

-(void)main {
}

-(void)postDidStartNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:T2OperationDidStartNotification
														object:self];
}
-(void)postDidEndNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:T2OperationDidFinishedNotification
														object:self];
}
-(void)postUpdateProgressNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:T2OperationUpdatedProgressNotification
														object:self];
}
@end

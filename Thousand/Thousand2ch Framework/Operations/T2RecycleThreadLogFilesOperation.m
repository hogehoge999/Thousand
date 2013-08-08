//
//  T2RecycleThreadLogFilesOperation.m
//  Thousand
//
//  Created by R. Natori on 08/11/17.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2RecycleThreadLogFilesOperation.h"
#import "T2ThreadFace.h"

@implementation T2RecycleThreadLogFilesOperation

+(T2Operation *)recycleThreadLogFilesOperationWithThreadFaces:(NSArray *)threadFaces {
	return [[[self alloc] initWithThreadFaces:threadFaces] autorelease];
}
-(T2Operation *)initWithThreadFaces:(NSArray *)threadFaces {
	self = [super init];
	_threadFaces = [threadFaces copy];
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	[self setName:NSLocalizedStringFromTableInBundle(@"Moving Files to Trash", @"Thousand2chLocalizable", bundle, nil)];
	[self setStatusString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Moving %d Files to Trash", @"Thousand2chLocalizable", bundle, nil), [_threadFaces count]]];
	
	return self;
}
-(void)dealloc {
	[_threadFaces release];
	[super dealloc];
}
-(void)main {
	unsigned threadFacesCount = [_threadFaces count];
	unsigned i;
	for (i=0; i<threadFacesCount; i++) {
		if ([self isCancelled]) return;
		if (threadFacesCount < 10 || i%5 == 0 || i+1==threadFacesCount) {
			[self setProgress:(float)i / (float)threadFacesCount];
		}
		T2ThreadFace *threadFace = [_threadFaces objectAtIndex:i];
		[threadFace recycleThreadLogFile];
	}
}

-(BOOL)visible { return YES; }
@end

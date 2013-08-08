//
//  THLoadThreadOperation.h
//  Thousand
//
//  Created by R. Natori on 平成 21/04/07.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THLoadThreadOperation : T2Operation {
	NSArray *_threadFaces;
	NSMutableArray *_threads;
}
+(id)loadOperationWithThreadFaces:(NSArray *)threadFaces ;
+(id)loadOperationWithThreadFace:(T2ThreadFace *)threadFace ;
-(id)initWithThreadFaces:(NSArray *)threadFaces ;
-(NSArray *)threads ;
@end

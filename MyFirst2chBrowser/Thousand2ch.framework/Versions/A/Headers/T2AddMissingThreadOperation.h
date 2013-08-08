//
//  T2AddMissingThreadOperation.h
//  Thousand
//
//  Created by R. Natori on 08/12/10.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2Operation.h"

@class T2ThreadFace, T2ListFace;

@interface T2AddMissingThreadOperation : T2Operation {
	T2ThreadFace *_threadFace;
	T2ListFace *_threadListFace;
}

+(T2Operation *)addMissingThreadOperationWithThreadFace:(T2ThreadFace *)threadFace threadListFace:(T2ListFace *)threadListFace ;
+(T2Operation *)addMissingThreadOperationWithThreadFace:(T2ThreadFace *)threadFace ;
-(T2Operation *)initWithThreadFace:(T2ThreadFace *)threadFace threadListFace:(T2ListFace *)threadListFace ;
-(T2Operation *)initWithThreadFace:(T2ThreadFace *)threadFace ;
@end

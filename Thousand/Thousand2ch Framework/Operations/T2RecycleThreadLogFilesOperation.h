//
//  T2RecycleThreadLogFilesOperation.h
//  Thousand
//
//  Created by R. Natori on 08/11/17.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2Operation.h"

@interface T2RecycleThreadLogFilesOperation : T2Operation {
	NSArray *_threadFaces;
}
+(T2Operation *)recycleThreadLogFilesOperationWithThreadFaces:(NSArray *)threadFaces ;
-(T2Operation *)initWithThreadFaces:(NSArray *)threadFaces ;
@end

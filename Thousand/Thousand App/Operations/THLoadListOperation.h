//
//  THLoadListOperation.h
//  Thousand
//
//  Created by R. Natori on 平成 21/04/07.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THLoadListOperation : T2Operation {
	NSArray *_listFaces;
	NSMutableArray *_lists;
}

+(id)loadOperationWithListFaces:(NSArray *)listFaces ;
+(id)loadOperationWithListFace:(T2ListFace *)listFace ;
-(id)initWithListFaces:(NSArray *)listFaces ;
-(NSArray *)lists ;
@end

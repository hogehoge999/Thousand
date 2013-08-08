//
//  T2FilterCondition.h
//  Thousand
//
//  Created by R. Natori on 平成 20/02/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface T2FilterCondition : NSObject {
	NSString	*_filterName;
	NSString	*_filterOperator;
	id 			_filterparameter;
}

-(void)setFilterName:(NSString *)filterName ;
-(NSString *)filterName ;
-(void)setFilterOperator:(NSString *)filterOperator ;
-(NSString *)filterOperator ;
-(void)setFilterParameter:(id)filterParameter ;
-(id)filterParameter ;

-(NSArray *)filterThreadFaces:(NSArray *)threadFaces ;

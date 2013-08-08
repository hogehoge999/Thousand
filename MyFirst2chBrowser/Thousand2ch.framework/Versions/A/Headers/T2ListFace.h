//
//  T2ListFace.h
//  Thousand
//
//  Created by R. Natori on 06/09/22.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2IdentifiedObject.h"

@class T2List;

@interface T2ListFace : T2IdentifiedObject {
	NSString	*_title;
	NSImage		*_image;
	BOOL		_animating;
	BOOL		_isLeaf;
}

#pragma mark -
#pragma mark Factory and Init
+(id)listFaceWithInternalPath:(NSString *)internalPath
						title:(NSString *)title
						image:(NSImage *)image ;
-(id)initWithInternalPath:(NSString *)internalPath
					title:(NSString *)title
					image:(NSImage *)image ;

#pragma mark -
#pragma mark Accessors
-(void)setTitle:(NSString *)aString ;
-(NSString *)title ;

-(void)setImage:(NSImage *)anImage ;
-(NSImage *)image ;
-(void)setImageByListImporter ;

-(void)setLeaf:(BOOL)aBool ;
-(BOOL)isLeaf ;

-(BOOL)allowsEditingTitle ;

-(T2List *)list ;

#pragma mark -
#pragma mark Animation Support
+(void)setClassAnimationImages:(NSArray *)images ;
+(void)startAnimation ;
+(void)stopAnimation ;
+(void)animate:(NSTimer *)timer ;
// use these methods
-(void)startAnimation ;
-(void)stopAnimation ;
@end

//
//  T2Operation.h
//  Thousand
//
//  Created by R. Natori on 08/11/12.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *T2OperationDidStartNotification;
extern NSString *T2OperationDidFinishedNotification;
extern NSString *T2OperationUpdatedProgressNotification;


@interface T2Operation : NSObject {
	NSThread *_thread;
	NSString *_name;
	NSString *_statusString;
	BOOL _isCancelled;
	BOOL _isFinished;
	BOOL _isExecuting;
	float _progress;
}

+(NSArray *)runningOperations ;

-(BOOL)visible ;

-(void)setName:(NSString *)name;
-(NSString *)name;
-(void)setStatusString:(NSString *)statusString;
-(NSString *)statusString;

-(void)setIsCancelled:(BOOL)isCancelled ;
-(BOOL)isCancelled ;
-(BOOL)isFinished ;
-(BOOL)isExecuting ;
-(void)setProgress:(float)progress ;
-(float)progress ;

-(void)start ;
-(void)cancel ;

-(void)main ;
@end

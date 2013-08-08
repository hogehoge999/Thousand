//
//  T2ThreadListTableView.h
//  Thousand
//
//  Created by R. Natori on 08/12/23.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "T2TableView.h"

@class T2ThreadListTableView, T2ThreadListTableViewInternalDelegate, T2ThreadView, T2ListFace, T2ThreadList;

@interface NSObject (T2ThreadListTableViewDelegate)
-(void)threadListTableView:(T2ThreadListTableView *)threadListTableView didSelectThreadFaces:(NSArray *)threadFaces ;
-(void)threadListTableView:(T2ThreadListTableView *)threadListTableView didClickThreadFaces:(NSArray *)threadFaces ;
-(void)threadListTableView:(T2ThreadListTableView *)threadListTableView didDoubleClickThreadFaces:(NSArray *)threadFaces ;
-(BOOL)threadListTableView:(T2ThreadListTableView *)threadListTableView shouldDeleteThreadFaces:(NSArray *)threadFaces ;
@end

@interface T2ThreadListTableView : T2TableView {
	T2ThreadListTableViewInternalDelegate *_internalDelegate;
	IBOutlet NSObject * _threadListTableViewDelegate;
	IBOutlet T2ThreadView *_threadView;
}

-(void)setThreadListFace:(T2ListFace *)threadListFace ;
-(T2ListFace *)threadListFace ;
-(void)setThreadList:(T2ThreadList *)threadList ;
-(T2ThreadList *)threadList ;

-(void)setInternalDelegate:(T2ThreadListTableViewInternalDelegate *)delegate ;
-(T2ThreadListTableViewInternalDelegate *)internalDelegate ;

-(void)setThreadListTableViewDelegate:(NSObject *)delegate ;
-(NSObject *)threadListTableViewDelegate ;
@end

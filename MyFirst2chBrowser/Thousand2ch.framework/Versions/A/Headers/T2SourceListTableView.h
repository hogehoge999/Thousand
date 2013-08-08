//
//  T2SourceListTableView.h
//  Thousand
//
//  Created by R. Natori on 08/12/19.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "T2TableView.h"
#import "T2ListBrowser.h"
#import "T2PluginProtocols.h"

@class T2SourceListTableView, T2SourceListTableViewInternalDelegate, T2SourceList, T2ThreadListTableView;

@interface NSObject (T2SourceListTableViewDelegate)
-(void)sourceListTableView:(T2SourceListTableView *)sourceListTableView didSelectListFaces:(NSArray *)listFaces ;
-(void)sourceListTableView:(T2SourceListTableView *)sourceListTableView didClickListFaces:(NSArray *)listFaces ;
-(void)sourceListTableView:(T2SourceListTableView *)sourceListTableView didDoubleClickListFaces:(NSArray *)listFaces ;
-(void)sourceListTableView:(T2SourceListTableView *)sourceListTableView didDeleteListFaces:(NSArray *)listFaces ;
@end

@interface T2SourceListTableView : T2TableView {
	T2SourceListTableViewInternalDelegate *_internalDelegate;
	IBOutlet NSObject * _sourceListTableViewDelegate;
	IBOutlet T2ListBrowser *_listBrowser;
	IBOutlet T2ThreadListTableView *_threadListTableView;
}
+(void)setClassLocalFileImporter:(id <T2ThreadImporting_v100>)localFileImporter ;

-(void)setInternalDelegate:(T2SourceListTableViewInternalDelegate *)delegate ;
-(T2SourceListTableViewInternalDelegate *)internalDelegate ;

-(void)setSourceListTableViewDelegate:(NSObject *)delegate ;
-(NSObject *)sourceListTableViewDelegate ;

@end



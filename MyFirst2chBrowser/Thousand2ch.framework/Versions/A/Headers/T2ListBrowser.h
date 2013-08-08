//
//  T2ListBrowser.h
//  Thousand
//
//  Created by R. Natori on 08/12/21.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "T2Browser.h"

@class T2ListBrowser, T2ListBrowserInternalDelegate, T2List, T2ListFace;

@interface NSObject (T2ListBrowserDelegate)
-(void)listBrowser:(T2ListBrowser *)listBrowser didSelectListFace:(T2ListFace *)listFace ;
@end

@interface T2ListBrowser : T2Browser {
	T2ListBrowserInternalDelegate *_internalDelegate;
	IBOutlet NSObject * _listBrowserDelegate;
}
-(void)setRootListFace:(T2ListFace *)rootListFace ;
-(T2ListFace *)rootListFace ;
-(void)setRootList:(T2List *)rootList ;
-(T2List *)rootList ;
-(void)setRowHeight:(float)rowHeight ;
-(float)rowHeight ;

-(void)setInternalDelegate:(T2ListBrowserInternalDelegate *)delegate ;
-(T2ListBrowserInternalDelegate *)internalDelegate ;

-(void)setListBrowserDelegate:(NSObject *)delegate ;
-(NSObject *)listBrowserDelegate ;
@end

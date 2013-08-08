//
//  T2TableView.h
//  Thousand
//
//  Created by R. Natori on 05/09/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface T2TableView : NSTableView {
	SEL _deleteKeyAction;
	SEL _otherMouseAction;
	NSDictionary *_tableColumnsDictionary ;
}

-(NSArray *)initialTableColumns ;
-(void)setTableColumnSettings:(NSArray *)columnSettings ;
-(NSArray *)tableColumnSettings ;
-(void)setVisible:(BOOL)visible ofTableColumnWithIdentifier:(NSString *)tableColumnIdentifier ;
-(BOOL)visibleOfTableColumnWithIdentifier:(NSString *)tableColumnIdentifier ;

-(void)setDeleteKeyAction:(SEL)selector ;
-(SEL)deleteKeyAction ;
-(void)setOtherMouseAction:(SEL)selector ;
-(SEL)otherMouseAction ;
@end

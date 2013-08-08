//
//  T2NSPasteboardAdditions.h
//  Thousand
//
//  Created by R. Natori on 08/12/19.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *T2IdentifiedThreadFacesPasteboardType ;
extern NSString *T2IdentifiedListFacesPasteboardType ;
extern NSString *T2TableRowIndexesPasteboardType ;

@interface NSPasteboard (T2NSPasteboardAdditions)
-(BOOL)setIdentifiedThreadFaces:(NSArray *)threadFaces ;
-(NSArray *)identifiedThreadFaces ;
-(BOOL)setIdentifiedListFaces:(NSArray *)listFaces ;
-(NSArray *)identifiedListFaces ;

-(BOOL)setTableRowIndexes:(NSIndexSet *)indexes ;
-(NSIndexSet *)tableRowIndexes ;
@end

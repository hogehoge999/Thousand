//
//  T2NSPasteboardAdditions.m
//  Thousand
//
//  Created by R. Natori on 08/12/19.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2NSPasteboardAdditions.h"
#import "T2ThreadFace.h"
#import "T2ListFace.h"

NSString *T2IdentifiedThreadFacesPasteboardType = @"T2IdentifiedThreadFacesPasteboardType";
NSString *T2IdentifiedListFacesPasteboardType = @"T2IdentifiedListFacesPasteboardType";
NSString *T2TableRowIndexesPasteboardType = @"T2TableRowIndexesPasteboardType";

@implementation NSPasteboard (T2NSPasteboardAdditions)

-(BOOL)setIdentifiedThreadFaces:(NSArray *)threadFaces {
	NSArray *internalPaths = [T2ThreadFace internalPathsForObjects:threadFaces];
	return [self setPropertyList:internalPaths forType:T2IdentifiedThreadFacesPasteboardType];
}
-(NSArray *)identifiedThreadFaces {
	return [self propertyListForType:T2IdentifiedThreadFacesPasteboardType];
}
-(BOOL)setIdentifiedListFaces:(NSArray *)listFaces {
	NSArray *internalPaths = [T2ListFace internalPathsForObjects:listFaces];
	return [self setPropertyList:internalPaths forType:T2IdentifiedListFacesPasteboardType];
}
-(NSArray *)identifiedListFaces {
	return [self propertyListForType:T2IdentifiedListFacesPasteboardType];
}

-(BOOL)setTableRowIndexes:(NSIndexSet *)indexes {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:indexes];
	return [self setData:data forType:T2TableRowIndexesPasteboardType];
}
-(NSIndexSet *)tableRowIndexes {
	NSData *data = [self dataForType:T2TableRowIndexesPasteboardType];
	return (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
}
@end

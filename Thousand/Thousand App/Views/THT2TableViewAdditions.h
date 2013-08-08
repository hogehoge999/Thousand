//
//  THT2TableViewAdditions.h
//  Thousand
//
//  Created by R. Natori on 08/12/20.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface T2TableView (THT2TableViewAdditions)

+(void)setVisible:(BOOL)visible ofTableColumnWithIdentifier:(NSString *)tableColumnIdentifier inDefaultsName:(NSString *)defaultsName ;
+(BOOL)visibleOfTableColumnWithIdentifier:(NSString *)tableColumnIdentifier inDefaultsName:(NSString *)defaultsName ;

-(void)loadTHTableViewDefaultsWithName:(NSString *)defaultsName ;
-(void)saveTHTableViewDefaultsWithName:(NSString *)defaultsName ;
@end

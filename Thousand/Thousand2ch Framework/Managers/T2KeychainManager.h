//
//  T2KeychainManager.h
//  Thousand
//
//  Created by R. Natori on 08/12/08.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>

@interface T2KeychainManager : NSObject {

}
+(id)sharedManager ;
-(BOOL)setGenericPassword:(NSString *)password accountName:(NSString *)accountName serviceName:(NSString *)serviceName ;
-(NSString *)genericPasswordForAccountName:(NSString *)accountName serviceName:(NSString *)serviceName ;
@end

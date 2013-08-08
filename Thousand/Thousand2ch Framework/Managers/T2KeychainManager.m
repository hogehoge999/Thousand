//
//  T2KeychainManager.m
//  Thousand
//
//  Created by R. Natori on 08/12/08.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2KeychainManager.h"

static id __sharedManager = nil;

@implementation T2KeychainManager

+(id)sharedManager {
	if (!__sharedManager) {
		__sharedManager = [[self alloc] init];
	}
	return __sharedManager;
}
-(id)init {
	@synchronized([self class]) {
		if (!__sharedManager) {
			__sharedManager = [super init];
		}
	}
	return __sharedManager;
}
-(oneway void)release {
}

-(BOOL)setGenericPassword:(NSString *)password accountName:(NSString *)accountName serviceName:(NSString *)serviceName {
	if (!password || !accountName || !serviceName) return NO;
	
	const char *accountNameChars = [accountName UTF8String];
	size_t accountNameLength = strlen(accountNameChars);
	
	const char *serviceNameChars = [serviceName UTF8String];
	size_t serviceNameLength = strlen(serviceNameChars);
	
	UInt32 passwordLength = 0;
	void *passwordChars = NULL;
	
	const char *newPasswordChars = [password UTF8String];
	size_t newPasswordLength = strlen(newPasswordChars);
	
	SecKeychainItemRef itemRef = NULL;
	
	OSStatus result = SecKeychainFindGenericPassword(NULL,
													  serviceNameLength,
													  serviceNameChars,
													  accountNameLength,
													  accountNameChars,
													  &passwordLength,
													  &passwordChars,
													  &itemRef);
	
	if (result == noErr && itemRef) {  // Keychain item already exists
		NSData *availablePasswordData = [NSData dataWithBytes:(const void *)passwordChars length:passwordLength];
		NSString *availablePassword = [[[NSString alloc] initWithData:availablePasswordData encoding:NSUTF8StringEncoding] autorelease];
			
		if ([availablePassword isEqualToString:password]) return YES;
		
		result = SecKeychainItemModifyAttributesAndData(itemRef,
														 NULL,
														 newPasswordLength,
														 newPasswordChars);
		if (result == noErr) return YES;
		return NO;
	}
	// Create Keychain item
	
	result = SecKeychainAddGenericPassword(NULL,
											serviceNameLength,
											serviceNameChars,
											accountNameLength,
											accountNameChars,
											newPasswordLength,
											newPasswordChars,
											NULL);
	if (result == noErr) return YES;
	return NO;
}

-(NSString *)genericPasswordForAccountName:(NSString *)accountName serviceName:(NSString *)serviceName {
	if (!accountName || !serviceName) return nil;
	
	const char *accountNameChars = [accountName UTF8String];
	size_t accountNameLength = strlen(accountNameChars);
	
	const char *serviceNameChars = [serviceName UTF8String];
	size_t serviceNameLength = strlen(serviceNameChars);
	
	UInt32 passwordLength = 0;
	void *passwordChars = NULL;
	
	OSStatus result = SecKeychainFindGenericPassword(NULL,
													  serviceNameLength,
													  serviceNameChars,
													  accountNameLength,
													  accountNameChars,
													  &passwordLength,
													  &passwordChars,
													  NULL);
	if (result == noErr) {
		NSData *resultPasswordData = [NSData dataWithBytes:(const void *)passwordChars length:passwordLength];
		NSString *resultPassword = [[[NSString alloc] initWithData:resultPasswordData encoding:NSUTF8StringEncoding] autorelease];
		if (resultPassword) return resultPassword;
	}
	return nil;
}
@end

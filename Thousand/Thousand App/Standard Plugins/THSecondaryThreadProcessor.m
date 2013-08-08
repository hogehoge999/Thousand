//
//  THSecondaryThreadProcessor.m
//  Thousand
//
//  Created by R. Natori on  07/09/08.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "THSecondaryThreadProcessor.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"AdditionalPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_Thousand_SecondaryThreadProcessor";

@implementation THSecondaryThreadProcessor

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	
	_aaDetectorEnabled = YES;
	_mineDetectorEnabled = YES;
	
	_skipCharSet = [[NSCharacterSet controlCharacterSet] retain];
	[self setAACharSetString:plugLocalizedString(@"AACharSetString")];
	[self setMinesString:plugLocalizedString(@"minesString")];
	
	_extractKeys = [[NSArray arrayWithObjects:
					 @"style",
					 @"myRes",
					 @"repliesToMyRes",
					 
		nil] retain];
	
	return self;
}

-(void)dealloc {
	[_skipCharSet release];
	[_AACharSet release];
	[_AACharSetString release];
	[_minesString release];
	[_mineStrings release];
	
	[super dealloc];
}
#pragma mark -
#pragma mark Protocol T2DictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:
		@"aaDetectorEnabled",
		@"mineDetectorEnabled",
		@"AACharSetString",
		@"minesString",
		nil];
}

//Accessors
-(void)setAaDetectorEnabled:(BOOL)aBool { _aaDetectorEnabled = aBool; }
-(BOOL)aaDetectorEnabled { return _aaDetectorEnabled; }
-(void)setMineDetectorEnabled:(BOOL)aBool { _mineDetectorEnabled = aBool; }
-(BOOL)mineDetectorEnabled { return _mineDetectorEnabled; }

-(void)setAACharSetString:(NSString *)string {
	setObjectWithRetain(_AACharSetString, string);
	setObjectWithRetain(_AACharSet, [NSCharacterSet characterSetWithCharactersInString:string]);
}
-(NSString *)AACharSetString { return _AACharSetString; }
-(void)setMinesString:(NSString *)aString {
	setObjectWithRetain(_minesString, aString);
	setObjectWithRetain(_mineStrings, [aString componentsSeparatedByString:@","]);
}
-(NSString *)minesString { return _minesString; }

	//protocol T2PluginInterface_v100
+(NSArray *)pluginInstances { return [NSArray arrayWithObject:[[[self alloc] init] autorelease]]; }
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName); }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]); }
-(T2PluginType)pluginType { return T2StandardPlugin; }
-(int)pluginOrder { return T2PluginOrderMiddle+1; }
-(NSArray *)uniqueNamesOfdependingPlugins { return nil; }

-(NSArray *)preferenceItems {
	return [NSArray arrayWithObjects:
		[T2PreferenceItem boolItemWithKey:@"aaDetectorEnabled"
									title:plugLocalizedString(@"Enable AA Detector")
									 info:nil],
		
		[T2PreferenceItem stringItemWithKey:@"AACharSetString"
									  title:plugLocalizedString(@"Characters in AA")
									   info:nil],
		
		[T2PreferenceItem boolItemWithKey:@"mineDetectorEnabled"
									title:plugLocalizedString(@"Enable Guro Detector")
									 info:nil],
		
		[T2PreferenceItem stringItemWithKey:@"minesString"
									  title:plugLocalizedString(@"Words in Response for Guro")
									   info:nil],
		nil];
}

	//protocol T2ThreadProcessing_v100
-(void)processThread:(T2Thread *)thread appendingIndex:(unsigned)index {
	NSArray *resArray = [thread resArray];
	unsigned i, maxCount = [resArray count];
	for (i=0; i<maxCount; i++) {
		T2Res *res = [resArray objectAtIndex:i];
		NSString *content = [res content];
		
		if (_aaDetectorEnabled) { //AA detection
			int score = 0;
			NSString *tempString = nil;
			NSScanner *scanner = [NSScanner scannerWithString:content];
			[scanner setCharactersToBeSkipped:_skipCharSet];
			while (![scanner isAtEnd] && [scanner scanLocation] < 256) {
				if ([scanner scanCharactersFromSet:_AACharSet intoString:&tempString]) {
					score += (int)[tempString length]-1;
				} else if ([scanner scanUpToCharactersFromSet:_AACharSet intoString:NULL]) {
					if (score > 2) score -= 2;
				}
				if (score > 10) {
					[res addHTMLClass:@"aa"];
					break;
				}
			}
		}
		
		if (_mineDetectorEnabled) { // guro detection
			NSIndexSet *forwardResIndexes = [res forwardResIndexes];
			if (forwardResIndexes && [forwardResIndexes count]>0) {
				if ([[res content] rangeOfString:@"ttp://" options:NSLiteralSearch].location != NSNotFound) {
					int forwardResIndex = [forwardResIndexes firstIndex];
                    NSLog(@"index6 = %d", forwardResIndex);
					while (forwardResIndex != -1/*NSNotFound*/) {
						T2Res *forwardRes = [resArray objectAtIndex:forwardResIndex];
						NSString *forwardResContent = [forwardRes content];
						
						NSRange range;
						unsigned length = [forwardResContent length];
						if (length<64)
							range = NSMakeRange(0,length);
						else
							range = NSMakeRange(0,64);
						NSString *mine;
						NSEnumerator *mineEnumerator = [_mineStrings objectEnumerator];
						while (mine = [mineEnumerator nextObject]) {
							if ([forwardResContent rangeOfString:mine
														 options:NSCaseInsensitiveSearch
														   range:range].location != NSNotFound) {
								[res addHTMLClass:@"danger"];
								break;
							}
						}
						
						forwardResIndex = [forwardResIndexes indexGreaterThanIndex:forwardResIndex];
                        NSLog(@"index7 = %d", forwardResIndex);
					}
				}
			}
		}
	}
}

	//protocol T2ResExtracting_v100
-(NSArray *)extractKeys {
	return _extractKeys;
}
-(NSIndexSet *)extractResIndexesInThread:(T2Thread *)thread forKey:(NSString *)key path:(NSString *)path {
	switch ([_extractKeys indexOfObject:key]) {
		
		case 0:
		{
			NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
			NSArray *resArray = [thread resArray];
			unsigned i, maxCount = [resArray count];
			for (i=0; i<maxCount; i++) {
				T2Res *res = [resArray objectAtIndex:i];
				if ([[res HTMLClasses] containsObject:path]) {
					[indexes addIndex:i];
				}
			}
			return indexes;
		}
			
		case 1:
		{
			return [thread myResIndexes];
		}
		case 2:
		{
			NSIndexSet *myResIndexes = [thread myResIndexes];
			if (myResIndexes) {
				NSMutableIndexSet *repliesToMyResIndexes = [[[thread forwardResIndexesFromResIndexes:myResIndexes] mutableCopy] autorelease];
				[repliesToMyResIndexes removeIndexes:myResIndexes];
				return [[repliesToMyResIndexes copy] autorelease];
			}
		}
		default:
			return nil;
	}	
}
-(NSString *)localizedDescriptionForKey:(NSString *)key path:(NSString *)path {
	switch ([_extractKeys indexOfObject:key]) {
		
		case 0:
			return [NSString stringWithFormat:plugLocalizedString(@"Style:%@"), path];
		case 1:
			return [NSString stringWithFormat:plugLocalizedString(@"My Postings")];
		case 2:
			return [NSString stringWithFormat:plugLocalizedString(@"Replies To Me")];
		default:
			return nil;
	}
}
-(NSArray *)defaultExtractPaths {
	return [NSArray arrayWithObjects:
			@"style/aa",
			@"myRes",
			@"repliesToMyRes",
			nil];
}
@end

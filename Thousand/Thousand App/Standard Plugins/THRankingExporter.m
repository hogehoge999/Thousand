//
//  THRankingExporter.m
//  Thousand
//
//  Created by R. Natori on 平成 20/04/09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "THRankingExporter.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"AdditionalPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_Thousand_RankingExporter";

@implementation THRankingExporter

#pragma mark -
#pragma mark init
-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	
	_rankingMaxCount = 10;
	return self;
}

#pragma mark -
#pragma mark Accessors
-(void)setRankingMaxCount:(int)count { _rankingMaxCount = count; }
-(int)rankingMaxCount { return _rankingMaxCount; }

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName ; }
-(NSString *)localizedName { return plugLocalizedString([self uniqueName]) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([[self uniqueName] stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderMiddle; }
-(NSArray *)uniqueNamesOfdependingPlugins { return nil; }

-(NSArray *)preferenceItems {
	return [NSArray arrayWithObjects:
			[T2PreferenceItem numberItemWithKey:@"rankingMaxCount"
										  title:plugLocalizedString(@"Max")
										   info:nil]
			,nil];
}


#pragma mark -
#pragma mark protocol T2ThreadHTMLExporting_v100
-(NSString *)HTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL {
	NSMutableString *insertion = [NSMutableString string];
	[insertion appendString:[self identifierRankingWithThread:thread]];
	[insertion appendString:[self responseRankingWithThread:thread]];
	[insertion appendString:[self responseToIdentifierRankingWithThread:thread]];
	
	return [thread HTMLWithOtherInsertion:insertion
								  baseURL:baseURL
								 forPopUp:NO];
}

-(NSString *)identifierRankingWithThread:(T2Thread *)thread {
	
	// making array
	NSDictionary *resIDDictionary = [thread idDictionary];
	NSArray *resIDKeyArray = [resIDDictionary allKeys];
	if ([resIDKeyArray count] == 0) return @"";
	
	NSEnumerator *resIDKeyEnumerator = [resIDKeyArray objectEnumerator];
	NSString *resIDKey;
	NSMutableArray *resIDandCountArray = [NSMutableArray array];
	
	while (resIDKey = [resIDKeyEnumerator nextObject]) {
		NSMutableDictionary *tempDictionary = [[[NSMutableDictionary alloc] init] autorelease];
		unsigned tempCount = [(NSIndexSet *)[resIDDictionary objectForKey:resIDKey] count];
		[tempDictionary setObject:[NSNumber numberWithUnsignedInt:tempCount] forKey:@"count"];
		[tempDictionary setObject:resIDKey forKey:@"identifier"];
		
		[resIDandCountArray addObject:tempDictionary];
	}
	
	// sort
	NSSortDescriptor *resCountDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"count" ascending:NO] autorelease];
	NSArray *sortDescriptors=[NSArray arrayWithObject:resCountDescriptor];
	
	[resIDandCountArray sortUsingDescriptors:sortDescriptors];
	
	//building Table
	NSMutableString *resultString = [NSMutableString string];
	
	[resultString appendString:@"<p><table><tbody>\n"];
	[resultString appendString:plugLocalizedString(@"<caption>Number of Messages (ID)</caption>\n")];
	
	NSEnumerator *resultEnumerator = [resIDandCountArray objectEnumerator];
	NSDictionary *resultDic;
	
	unsigned i=1;
	while (resultDic = [resultEnumerator nextObject]) {
		[resultString appendString:@"<tr>\n"];
		
		NSString *identifier = [resultDic objectForKey:@"identifier"];
		NSNumber *count = [resultDic objectForKey:@"count"];
		
		[resultString appendFormat:@"<td align=right>%d: </td>\n", i];
		[resultString appendFormat:plugLocalizedString(@"<td><a href=\"internal://identifier/%@\">ID: %@</a></td>\n"), [identifier stringByAddingUTF8PercentEscapesForce], identifier];
		[resultString appendFormat:plugLocalizedString(@"<td align=right>%@ Messages</td>\n"), count];
		
		[resultString appendString:@"</tr>\n"];
		
		i++;
		if (i > _rankingMaxCount) break;
	}
	
	[resultString appendString:@"</tbody></table></p>\n"];
	return resultString;
}

-(NSString *)responseRankingWithThread:(T2Thread *)thread {
	
	// making array
	NSMutableArray *resArray = [[[thread resArray] mutableCopy] autorelease];
	if ([resArray count] == 0) return @"";
	
	
	// sort
	NSSortDescriptor *resCountDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"forwardResCount" ascending:NO] autorelease];
	NSArray *sortDescriptors=[NSArray arrayWithObject:resCountDescriptor];
	
	[resArray sortUsingDescriptors:sortDescriptors];
	
	//building Table
	NSMutableString *resultString = [NSMutableString string];
	
	[resultString appendString:@"<p><table><tbody>\n"];
	[resultString appendString:plugLocalizedString(@"<caption>Number of Responses (To Message)</caption>\n")];
	
	NSEnumerator *resultEnumerator = [resArray objectEnumerator];
	T2Res *res;
	
	unsigned i=1;
	while (res = [resultEnumerator nextObject]) {
		[resultString appendString:@"<tr>\n"];
		
		[resultString appendFormat:@"<td align=right>%d: </td>\n", i];
		int resNumber = [res resNumber];
		[resultString appendFormat:plugLocalizedString(@"<td><a href=\"internal://traceOnce/%d\">%d</a> </td> <td> <a href=\"internal://identifier/%@\">ID: %@</a></td>\n"),
		 resNumber, resNumber, [res identifier], [res identifier]];
		[resultString appendFormat:plugLocalizedString(@"<td align=right>%d Responses</td>\n"), [res forwardResCount]];
		
		[resultString appendString:@"</tr>\n"];
		
		i++;
		if (i > _rankingMaxCount) break;
	}
	
	[resultString appendString:@"</tbody></table></p>\n"];
	return resultString;
}

-(NSString *)responseToIdentifierRankingWithThread:(T2Thread *)thread {
	
	
	// making array
	NSArray *resArray = [[[thread resArray] copy] autorelease];
	if ([resArray count] == 0) return @"";
	NSEnumerator *resEnumerator = [resArray objectEnumerator];
	T2Res *res;
	
	NSMutableDictionary *forwardResCountForIdentifier = [NSMutableDictionary dictionary];
	
	while (res = [resEnumerator nextObject]) {
		NSString *identifier = [res identifier];
		if (identifier) {
			NSNumber *totalforwardResCount = [forwardResCountForIdentifier objectForKey:identifier];
			unsigned forwardResCount = [res forwardResCount];
			if (totalforwardResCount) {
				totalforwardResCount = [NSNumber numberWithUnsignedInt:(forwardResCount + [totalforwardResCount unsignedIntValue])];
				
			} else {
				totalforwardResCount = [NSNumber numberWithUnsignedInt:forwardResCount];
				
			}
			[forwardResCountForIdentifier setObject:totalforwardResCount forKey:identifier];
		}
	}
	
	NSEnumerator *identifierEnumerator = [forwardResCountForIdentifier keyEnumerator];
	NSMutableArray *forwardResCountAndIdentifierArray = [NSMutableArray array];
	NSString *identifier;
	
	while (identifier = [identifierEnumerator nextObject]) {
		NSMutableDictionary *tempDictionary = [NSMutableDictionary dictionary];
		[tempDictionary setObject:identifier forKey:@"identifier"];
		[tempDictionary setObject:[forwardResCountForIdentifier objectForKey:identifier]
						   forKey:@"forwardResCount"];
		[forwardResCountAndIdentifierArray addObject:tempDictionary];
	}
	
	
	// sort
	NSSortDescriptor *resCountDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"forwardResCount" ascending:NO] autorelease];
	NSArray *sortDescriptors=[NSArray arrayWithObject:resCountDescriptor];
	
	[forwardResCountAndIdentifierArray sortUsingDescriptors:sortDescriptors];
	
	//building Table
	NSMutableString *resultString = [NSMutableString string];
	
	[resultString appendString:@"<p><table><tbody>\n"];
	[resultString appendString:plugLocalizedString(@"<caption>Number of Responses (To ID)</caption>\n")];
	
	NSEnumerator *resultEnumerator = [forwardResCountAndIdentifierArray objectEnumerator];
	NSDictionary *tempDictionary;
	
	unsigned i=1;
	while (tempDictionary = [resultEnumerator nextObject]) {
		[resultString appendString:@"<tr>\n"];
		
		[resultString appendFormat:@"<td align=right>%d: </td>\n", i];
		NSString *identifier = [tempDictionary objectForKey:@"identifier"];
		int forwardResCount = [[tempDictionary objectForKey:@"forwardResCount"] intValue];
		
		[resultString appendFormat:plugLocalizedString(@"<td><a href=\"internal://identifier/%@\">ID: %@</a></td>\n"),
		 identifier, identifier];
		[resultString appendFormat:plugLocalizedString(@"<td align=right>%d Responses</td>\n"), forwardResCount];
		
		[resultString appendString:@"</tr>\n"];
		
		i++;
		if (i > _rankingMaxCount) break;
	}
	
	[resultString appendString:@"</tbody></table></p>\n"];
	return resultString;
	
}
@end

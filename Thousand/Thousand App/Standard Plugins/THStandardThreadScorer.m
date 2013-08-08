//
//  THStandardThreadScorer.m
//  Thousand
//
//  Created by R. Natori on 05/09/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "THStandardThreadScorer.h"
#import "T2LabeledCell.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"StandardPlugLocalizable"])
#define kFloatDateMax LONG_MAX

static NSBundle *_selfBundle;

static NSString *__uniqueName = @"jp_natori_Thousand_2chScorer";

static NSString *__operatorIs = @"is";
static NSString *__operatorIsNot = @"isNot";
static NSString *__operatorGreaterThan = @"greaterThan";
static NSString *__operatorLessThan = @"lessThan";
static NSString *__operatorWithinDays = @"withinDays";
static NSString *__operatorBeforeDays = @"beforeDays";

static NSString *__velocityStringFormat_d = nil;
static NSString *__velocityStringFormat_h = nil;
static NSString *__velocityStringFormat_m = nil;
static NSString *__velocityStringFormat_s = nil;

@implementation THStandardThreadScorer

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	
	__velocityStringFormat_d = [plugLocalizedString(@"%#.2f /d") retain];
	__velocityStringFormat_h = [plugLocalizedString(@"%#.2f /h") retain];
	__velocityStringFormat_m = [plugLocalizedString(@"%#.2f /m") retain];
	__velocityStringFormat_s = [plugLocalizedString(@"%#.2f /s") retain];
	
	return self;
}

#pragma mark -
#pragma mark Protocol T2PluginInterface_v100

+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName ; }
-(NSString *)localizedName { return plugLocalizedString([self uniqueName]) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([[self uniqueName] stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderFirst; }
-(NSArray *)uniqueNamesOfdependingPlugins { return nil; }


#pragma mark -
#pragma mark T2ThreadFaceScoring_v100

-(NSArray *)scoreKeys {
	return [NSArray arrayWithObjects:
			@"voidProperty",
			@"resCount", @"resCountNew", @"resCountGap",
			@"order",
			@"createdDate", @"modifiedDate", @"createdDateString", @"modifiedDateString",
			@"lastLoadingDate", @"lastLoadingDateString", @"lastPostingDate",  @"lastPostingDateString",
			@"velocity", @"velocityString",
			@"labelScore", @"labelScoreString",
			@"threadListTitle",
			@"combinedScore", @"combinedScoreString",
			nil];
}
-(NSString *)localizedNameForScoreKey:(NSString *)key {
	return plugLocalizedString(key);
}

-(id)scoreValueOfThreadFace:(T2ThreadFace *)threadFace forKey:(NSString *)key {
	/*
	if ([key isEqualToString:@"velocityString"]) {
		float score = [threadFace velocity];
		NSString *format;
		if (score <= 60.0) {
			format = @"%#.2f /h";
			
		} else if (score <= 3600.0) {
			format = @"%#.2f /m";
			score = score/60.0;
		} else {
			format = @"%#.2f /s";
			score = score/3600.0;
		}
		return [NSString stringWithFormat:plugLocalizedString(format), score];
	}
	else if ([key isEqualToString:@"createdDateString"]) {
		NSDate *date = [threadFace createdDate];
		return [date descriptionWithCalendarFormat:@"%y/%m/%d %H:%M:%S" timeZone:nil locale:nil];
	}
	else if ([key isEqualToString:@"modifiedDateString"]) {
		NSDate *date = [threadFace modifiedDate];
		return [date descriptionWithCalendarFormat:@"%y/%m/%d %H:%M:%S" timeZone:nil locale:nil];
	}
	 */
	return nil;
}

#pragma mark
#pragma mark T2ThreadFaceFiltering_v100

-(NSArray *)filterNames {
	return [NSArray arrayWithObjects:
			@"resCountFilter", @"resCountNewFilter", @"resCountGapFilter",
			@"createdDateFilter",
			@"labelFilter",
			@"stateFilter",
			nil];
}
-(NSString *)localizedNameForFilterName:(NSString *)name {
	return plugLocalizedString(name);
}
-(NSArray *)filterOperatorsForFilterName:(NSString *)name {
	if ([name hasPrefix:@"resCount"]) {
		return [NSArray arrayWithObjects:
				__operatorIs,
				__operatorIsNot,
				__operatorGreaterThan,
				__operatorLessThan,
				nil];
	} else if ([name isEqualToString:@"createdDateFilter"]) {
		return [NSArray arrayWithObjects:
				__operatorWithinDays,
				nil];
	} else if ([name isEqualToString:@"labelFilter"] || [name isEqualToString:@"stateFilter"]) {
		return [NSArray arrayWithObjects:
				__operatorIs,
				__operatorIsNot,
				nil];
	}
}
-(NSString *)localizedDescriptionForFilterOperator:(NSString *)filterOperator {
	return plugLocalizedString(filterOperator);
}
-(NSString *)localizedAppendixForFilterOperator:(NSString *)filterOperator {
	NSString *localizedString = plugLocalizedString([filterOperator stringByAppendingString:@"_appendix"]);
	if ([localizedString hasSuffix:@"_appendix"])
		return nil;
	return localizedString;
}
-(T2FilteringParameterType)parameterTypeForFilterName:(NSString *)name {
	if ([name isEqualToString:@"labelFilter"] || [name isEqualToString:@"stateFilter"]) {
		return T2FilteringParameterMenuItemsIndex;
	}
	return T2FilteringParameterString;
}
-(id)parameterInputObjectForFilterName:(NSString *)name {
	if ([name isEqualToString:@"labelFilter"]) {
		if (!_labelMenuItems) {
			NSArray *menuItems = [[T2LabeledCellManager sharedManager] menuItems];
			NSEnumerator *menuItemsEumerator = [menuItems objectEnumerator];
			NSMenuItem *menuItem;
			while (menuItem = [menuItemsEumerator nextObject]) {
				[menuItem setAction:NULL];
			}
			_labelMenuItems = [menuItems retain];
		}
		return _labelMenuItems;
		
	} else if ([name isEqualToString:@"stateFilter"]) {
		if (!_stateMenuItems) {
			NSMutableArray *menuItems = [NSMutableArray array];
			NSEnumerator *menuItemsEumerator = [menuItems objectEnumerator];
			NSMenuItem *menuItem;
			while (menuItem = [menuItemsEumerator nextObject]) {
				[menuItem setAction:NULL];
			}
			_labelMenuItems = [menuItems retain];
		}
		return _labelMenuItems;
	}		
}
-(NSArray *)filteredThreadFaces:(NSArray *)threadFaces forFilterName:(NSString *)name 
				 filterOperator:(NSString *)filterOperator parameter:(id)parameter {
	NSMutableArray *result = [NSMutableArray array];
	NSEnumerator *threadFaceEnumerator = [threadFaces objectEnumerator];
	T2ThreadFace *threadFace;
	
	if ([name isEqualToString:@"labelFilter"]) {							// Label
		int label = [(NSNumber *)parameter intValue];
		BOOL operatorIs = [filterOperator isEqualToString:__operatorIs];
		
		while (threadFace = [threadFaceEnumerator nextObject]) {
			if (([threadFace label] == label) == operatorIs) {
				[result addObject:threadFace];
			}
		}
		return result;
		
	} else if ([name isEqualToString:@"stateFilter"]) {						// State
		T2ThreadFaceState state = [(NSNumber *)parameter intValue]+1;
		BOOL operatorIs = [filterOperator isEqualToString:__operatorIs];
		
		while (threadFace = [threadFaceEnumerator nextObject]) {
			if (([threadFace state] == state) == operatorIs) {
				[result addObject:threadFace];
			}
		}
		return result;
		
	} else if ([name isEqualToString:@"createdDateFilter"]) {				// Date
		int days = [(NSString *)parameter intValue];
		NSDate *date = [NSDate date];
		BOOL operatorWithinDays = [filterOperator isEqualToString:__operatorWithinDays];
		
		while (threadFace = [threadFaceEnumerator nextObject]) {
			if (([date timeIntervalSinceDate:[threadFace createdDate]] <= days*86400) == operatorWithinDays) {
				[result addObject:threadFace];
			}
		}
		return result;
		
	} else if ([name hasPrefix:@"resCount"]) {								// Res Count
		int resCount = [(NSString *)parameter intValue];
		SEL selector = @selector(resCount);
		if ([name isEqualToString:@"resCountNewFilter"])
			selector = @selector(resCountNew);
		if ([name isEqualToString:@"resCountGapFilter"])
			selector = @selector(resCountGap);
		
		if ([filterOperator isEqualToString:__operatorGreaterThan]) {
			while (threadFace = [threadFaceEnumerator nextObject]) {
				if ((int)[threadFace performSelector:selector] > resCount) {
					[result addObject:threadFace];
				}
			}
		} else if ([filterOperator isEqualToString:__operatorLessThan]) {
			while (threadFace = [threadFaceEnumerator nextObject]) {
				if ((int)[threadFace performSelector:selector] < resCount) {
					[result addObject:threadFace];
				}
			}
		} else if ([filterOperator isEqualToString:__operatorIs]) {
			while (threadFace = [threadFaceEnumerator nextObject]) {
				if ((int)[threadFace performSelector:selector] == resCount) {
					[result addObject:threadFace];
				}
			}
		} else if ([filterOperator isEqualToString:__operatorIsNot]) {
			while (threadFace = [threadFaceEnumerator nextObject]) {
				if ((int)[threadFace performSelector:selector] != resCount) {
					[result addObject:threadFace];
				}
			}
		}
		return result;
	}
}
@end

@implementation T2ThreadFace (THStandardThreadScorer)

-(NSString *)velocityString {
	float score = [self velocity];
	NSString *format;
	if (score <= 1.0) {
		format = __velocityStringFormat_d;
		score = score*24.0;
		
	} else if (score <= 60.0) {
		format = __velocityStringFormat_h;
		
	} else if (score <= 3600.0) {
		format = __velocityStringFormat_m;
		score = score/60.0;
	} else {
		format = __velocityStringFormat_s;
		score = score/3600.0;
	}
	return [NSString stringWithFormat:plugLocalizedString(format), score];
	
}
-(NSString *)createdDateString {
	NSDate *date = _createdDate;
	return [date descriptionWithCalendarFormat:@"%y/%m/%d %H:%M:%S" timeZone:nil locale:nil];
}
-(NSString *)modifiedDateString {
	NSDate *date = _modifiedDate;
	return [date descriptionWithCalendarFormat:@"%y/%m/%d %H:%M:%S" timeZone:nil locale:nil];
}

-(NSDate *)lastLoadingDate {
	return [[self extraInfo] objectForKey:@"lastLoadingDate"];
}
 
-(NSString *)lastLoadingDateString {
	NSDate *date = [[self extraInfo] objectForKey:@"lastLoadingDate"];
	if (date)
		return [date descriptionWithCalendarFormat:@"%y/%m/%d %H:%M:%S" timeZone:nil locale:nil];
	return @"";
}

-(NSDate *)lastPostingDate {
	return [[self extraInfo] objectForKey:@"lastPostingDate"];
}

-(NSString *)lastPostingDateString {
	NSDate *date = [[self extraInfo] objectForKey:@"lastPostingDate"];
	if (date)
		return [date descriptionWithCalendarFormat:@"%y/%m/%d %H:%M:%S" timeZone:nil locale:nil];
	return @"";
}

-(double)combinedScore {
	float score = (10-_state)*10000;
	if (_state == T2ThreadFaceStateNew) {
		score += ([_createdDate timeIntervalSince1970] / NSTimeIntervalSince1970);
	} else if (_state == T2ThreadFaceStateUpdated) {
		score += (_resCountNew - _resCount);
	} else if (_state == T2ThreadFaceStateNone) {
		score += [self velocity];
	}
	return score;
}
-(NSString *)combinedScoreString {
	if (_state == T2ThreadFaceStateNew) {
		return [self createdDateString];
		
	} else if (_state == T2ThreadFaceStateUpdated) {
		return [NSString stringWithFormat:@"+%d", (_resCountNew - _resCount)];
		
	} else if (_state == T2ThreadFaceStateNone) {
		return [self velocityString];
		
	}
	return @"";
}
-(int)labelScore {
	if (_label == 0) return 0;
	return 10000-_label;
}
-(NSString *)labelScoreString {
	NSArray *labelNames = [[T2LabeledCellManager sharedManager] labelNames];
	unsigned namesCount = [labelNames count];
	if (_label < namesCount) {
		return [labelNames objectAtIndex:_label];
	}
	return @"";
}
@end

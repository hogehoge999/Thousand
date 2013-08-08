//
//  THStandardThreadScorer.h
//  Thousand
//
//  Created by R. Natori on 05/09/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THStandardThreadScorer : NSObject <T2PluginInterface_v100, T2ThreadFaceScoring_v100> {
	NSArray *_labelMenuItems;
	NSArray *_stateMenuItems;
}

//protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;
-(NSArray *)uniqueNamesOfdependingPlugins ;

// T2ThreadFaceScoring_v100
-(NSArray *)scoreKeys;
-(NSString *)localizedNameForScoreKey:(NSString *)key;
-(id)scoreValueOfThreadFace:(T2ThreadFace *)threadFace forKey:(NSString *)key;

// T2ThreadFaceFiltering_v100
-(NSArray *)filterNames;
-(NSString *)localizedNameForFilterName:(NSString *)name;
-(NSArray *)filterOperatorsForFilterName:(NSString *)name;
-(NSString *)localizedDescriptionForFilterOperator:(NSString *)filterOperator;
-(NSString *)localizedAppendixForFilterOperator:(NSString *)filterOperator;
-(T2FilteringParameterType)parameterTypeForFilterName:(NSString *)name;
-(id)parameterInputObjectForFilterName:(NSString *)name;
-(NSArray *)filteredThreadFaces:(NSArray *)threadFaces forFilterName:(NSString *)name 
				 filterOperator:(NSString *)filterOperator parameter:(id)parameter;
@end

@interface T2ThreadFace (THStandardThreadScorer)
-(NSString *)velocityString ;
-(NSString *)createdDateString ;
-(NSString *)modifiedDateString ;
-(NSDate *)lastLoadingDate ;
-(NSString *)lastLoadingDateString ;
-(NSDate *)lastPostingDate ;
-(NSString *)lastPostingDateString ;


-(double)combinedScore ;
-(NSString *)combinedScoreString ;

-(int)labelScore ;
-(NSString *)labelScoreString ;
@end

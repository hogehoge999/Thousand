
#import <Cocoa/Cocoa.h>

@protocol T2AsynchronousLoading <NSObject>
-(void)load ;
-(void)cancelLoading ;
-(BOOL)isLoading ;
-(float)progress ;
-(NSString *)progressInfo ;
@end
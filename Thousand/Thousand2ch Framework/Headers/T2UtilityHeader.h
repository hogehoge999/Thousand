// Foundation Additions
#import "T2NSObjectAdditions.h"
#import "T2NSDataAdditions.h"
#import "T2NSStringAdditions.h"
#import "T2NSArrayAdditions.h"
#import "T2NSDictionaryAdditions.h"
#import "T2NSCalendarDateAdditions.h"
#import "T2NSURLRequestAdditions.h"
#import "T2NSIndexSetAdditions.h"
#import "T2NSScannerAdditions.h"
#import "T2NSSetAdditions.h"

#define setObjectWithRetain(instanceVariable, inputObject) ({id __T2_tempObject__ = instanceVariable; instanceVariable = [inputObject retain]; [__T2_tempObject__ release];})
#define setObjectWithCopy(instanceVariable, inputObject) ({id __T2_tempObject__ = instanceVariable; instanceVariable = [inputObject copy]; [__T2_tempObject__ release];})
#define setObjectWithRetainSynchronized(instanceVariable, inputObject) ({ @synchronized(self) {id __T2_tempObject__ = instanceVariable; instanceVariable = [inputObject retain]; [__T2_tempObject__ release];}})

#define releaseObjectWithNil(instanceVariable) ({id __T2_tempObject__ = instanceVariable; instanceVariable = nil; [__T2_tempObject__ release];})

#define T2LocalizedStringForClass(string, comment, class) (NSLocalizedStringFromTableInBundle(string, nil, [NSBundle bundleForClass:class], comment))
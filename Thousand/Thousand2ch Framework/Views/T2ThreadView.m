//
//  T2ThreadView.m
//  Thousand
//
//  Created by R. Natori on 06/10/01.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2ThreadView.h"
#import "T2Thread.h"
#import "T2ThreadFace.h"
#import "T2PluginManager.h"
#import "T2PopUpWindowController.h"

//static id <T2ThreadPartialHTMLExporting_v100>	__partialHTMLExporter;
//static T2ThreadViewInternalDelegate *__threadViewSharedDelegate = nil;

static Class __T2ThreadViewInternalDelegate;
//static NSString *__noPreviewHTMLClassName = T2HTMLClassNameNoPreview;

//static unsigned				__noPopUpModifierMask = NSCommandKeyMask;
static NSTimeInterval		__popUpWait = 0.2;

static BOOL				__classAllowsTypeToJump = YES;
static NSTimeInterval	__typeWait = 0.3;

static BOOL	__DOMEventEnabled = NO;
static BOOL __Safari2Debug = NO;

@interface T2ThreadView (T2ThreadViewInternal)

-(void)initThreadView ;
-(void)thread:(T2Thread *)thread didUpdateStyleOfResIndexes:(NSIndexSet *)resIndexes ;
-(void)setThreadLoaded:(BOOL)aBool ;
-(BOOL)threadLoaded ;
@end

@implementation T2ThreadView

+(void)setClassPopUpWait:(float)wait {
	if (wait >= 0) __popUpWait = wait;
}
+(float)classPopUpWait { return __popUpWait; }
+(void)setClassResPopUpWindowWidth:(float)width {
	[T2PopUpWindowController setClassResPopUpWindowWidth:width];
}
+(float)classResPopUpWindowWidth { return [T2PopUpWindowController classResPopUpWindowWidth]; }

+(void)setClassAllowsTypeToJump:(BOOL)aBool { __classAllowsTypeToJump = aBool; }
+(BOOL)classAllowsTypeToJump { return __classAllowsTypeToJump; }
+(void)setClassTypeWait:(NSTimeInterval)wait { 
	if (wait >= 0 && wait < 60) {
		__typeWait = wait;
	}
}
+(NSTimeInterval)classTypeWait { return __typeWait; }

+(void)setClassSafari2Debug:(BOOL)aBool { __Safari2Debug = aBool; }
+(BOOL)classSafari2Debug { return __Safari2Debug; }

- (id)init {
	self = [super init];
	[self initThreadView];
	return self;
}
- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	[self initThreadView];
	return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	[self initThreadView];
	return self;
}
- (id)initWithFrame:(NSRect)frameRect frameName:(NSString *)frameName groupName:(NSString *)groupName {
	self = [super initWithFrame:frameRect frameName:frameName groupName:groupName];
	[self initThreadView];
	return self;
}

-(void)initThreadView {
	if (!_internalDelegate) {
		[self setInternalDelegate:[[[T2ThreadViewInternalDelegate alloc] init] autorelease]];
	}
}

-(void)dealloc {
	[self stopLoading:nil];
	[self setDelegate:nil];
	[self setInternalDelegate:nil];
	
	if (_typeTimer) {
		[_typeTimer invalidate];
		[_typeTimer release];
		_typeTimer = nil;
	}
	[_typeBuffer release];
	_typeBuffer = nil;
	
	if (_styleTimer) {
		[_styleTimer invalidate];
		[_styleTimer release];
		_styleTimer = nil;
	}
	
	[self setThread:nil];
	[_resIndexes release];
	[_resExtractPath release];
	[_selectedResExtractPath release];
	[_HTMLExporter release];
	
	[_baseURL release];
	
	[_loadedResIndexes release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(void)setThreadURLString:(NSString *)URLString {
	[self setThread:[[T2ThreadFace threadFaceWithURLString:URLString] thread]];
}
-(void)setThreadInternalPath:(NSString *)internalPath {
	[self setThread:[[T2ThreadFace threadFaceWithInternalPath:internalPath] thread]];
}
-(void)setThreadFace:(T2ThreadFace *)threadFace {
	[self setThread:[threadFace thread]];
}

-(void)setThread:(T2Thread *)thread {
	[thread retain];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	if (_thread) {
		[notificationCenter removeObserver:self name:T2ThreadDidLoadResIndexesNotification object:_thread];
		[notificationCenter removeObserver:self name:T2ThreadDidUpdateStyleOfResIndexesNotification object:_thread];
		
		[_thread removeObserver:self forKeyPath:@"isLoading"];
		[_thread removeObserver:self forKeyPath:@"estimatedProgress"];
		//[_thread removeObserver:self forKeyPath:@"loadedResIndexes"];
		//[_thread removeObserver:self forKeyPath:@"styleUpdatedResIndexes"];
		[_thread release];
	}
	_thread = thread;
	
	if (_thread) {
		[notificationCenter addObserver:self selector:@selector(threadDidLoadResIndexes:) name:T2ThreadDidLoadResIndexesNotification object:_thread];
		[notificationCenter addObserver:self selector:@selector(threadDidUpdateStyleOfResIndexes:) name:T2ThreadDidUpdateStyleOfResIndexesNotification object:_thread];
		
		[_thread addObserver:self forKeyPath:@"isLoading" options:0 context:NULL];
		[_thread addObserver:self forKeyPath:@"estimatedProgress" options:0 context:NULL];
		//[_thread addObserver:self forKeyPath:@"loadedResIndexes" options:0 context:NULL];
		//[_thread addObserver:self forKeyPath:@"styleUpdatedResIndexes" options:0 context:NULL];
	}
	
	if (_resExtractPath || _resIndexes) {
		//[self setThreadLoaded:NO];
		[self displayThread];
	}
}
-(T2Thread *)thread { return _thread; }

/*
-(void)setInternalBaseURLprefixFromURL:(NSURL *)baseURL {
	if ([baseURL isFileURL]) {
		
		NSString *absoluteString = [baseURL filePath];
		if ([[absoluteString pathExtension] length] > 0) {
			absoluteString = [absoluteString stringByDeletingLastPathComponent];
		}
		setObjectWithRetain(_internalBaseURLprefix, absoluteString);
	} else {
		setObjectWithRetain(_internalBaseURLprefix, nil);
	}
}
-(NSString *)internalBaseURLprefix {
	return _internalBaseURLprefix;
}
 */

-(void)setResIndexes:(NSIndexSet *)indexSet {
	setObjectWithCopy(_resIndexes,indexSet);
	if (!_resExtractPath && _thread) [self displayThread];
}
-(NSIndexSet *)resIndexes { return _resIndexes; }

-(void)setResExtractPath:(NSString *)extractPath {
	setObjectWithCopy(_resExtractPath,extractPath);
	releaseObjectWithNil(_HTMLExporter);
	if (_thread && _resExtractPath) [self displayThread];
}
-(NSString *)resExtractPath { return _resExtractPath; }

-(void)setSelectedResExtractPath:(NSString *)extractPath {
	setObjectWithCopy(_selectedResExtractPath, extractPath);
}
-(NSString *)selectedResExtractPath { return _selectedResExtractPath; }

-(void)setHTMLExporter:(id <T2ThreadHTMLExporting_v100>)HTMLExporter {
	releaseObjectWithNil(_selectedResExtractPath);
	releaseObjectWithNil(_resExtractPath);
	setObjectWithRetain(_HTMLExporter, HTMLExporter);
	if (_HTMLExporter) {
		[self setThreadLoaded:NO];
		[self displayThread];
	}
}
-(id <T2ThreadHTMLExporting_v100>)HTMLExporter { return _HTMLExporter; }

-(void)setBaseURL:(NSURL *)anURL { setObjectWithRetain(_baseURL, anURL); }
-(NSURL *)baseURL { return _baseURL; }

-(void)setInternalDelegate:(T2ThreadViewInternalDelegate *)internalDelegate {
	if (_internalDelegate == internalDelegate) return;
	[_internalDelegate setThreadView:nil];
	setObjectWithRetain(_internalDelegate, internalDelegate);
	[_internalDelegate setThreadView:self];
	[self setFrameLoadDelegate:_internalDelegate];
	[self setResourceLoadDelegate:_internalDelegate];
	[self setPolicyDelegate:_internalDelegate];
	[self setUIDelegate:_internalDelegate];
}
-(T2ThreadViewInternalDelegate *)internalDelegate {
	return _internalDelegate;
}

-(void)setDelegate:(NSObject *)delegate {
	_delegate = delegate;
}
-(NSObject *)delegate {
	return _delegate;
}

-(void)setIsPopup:(BOOL)aBool { _isPopUp = aBool; }
-(BOOL)isPopup { return _isPopUp; }

-(void)setThreadLoaded:(BOOL)aBool {
	_threadLoaded = aBool; 
	//NSLog(@"setThreadLoaded:%d", aBool);
}
-(BOOL)threadLoaded { return _threadLoaded; }

#pragma mark -
#pragma mark WebView Override Methods
- (IBAction)takeStringURLFrom:(id)sender {
	if ([sender respondsToSelector:@selector(stringValue)]) {
		NSString *URLString = [(NSControl *)sender stringValue];
		[self setMainFrameURL:URLString];
	}
}
- (void)setMainFrameURL:(NSString *)URLString {
	if (URLString) {
		NSString *internalPath = [[T2PluginManager sharedManager] threadInternalPathForProposedURLString:URLString];
		if (internalPath)
			[self setThreadInternalPath:internalPath];
		
		else if ([super respondsToSelector:@selector(setMainFrameURL:)])
			[super setMainFrameURL:URLString];
	}
}
- (NSString *)mainFrameURL {
	if (_thread)
		[_thread webBrowserURLString];
	else if ([super respondsToSelector:@selector(mainFrameURL)])
		return [super mainFrameURL];
	return @"";
}
- (IBAction)reload:(id)sender {
	if (_thread)
		[_thread load];
	else
		[super reload:sender];
}
- (IBAction)stopLoading:(id)sender {
	if (_thread)
		[_thread cancelLoading];
	else
		[super stopLoading:sender];
}
- (double)estimatedProgress {
	if (_thread)
		return [_thread progress];
	return [super estimatedProgress];
}
- (BOOL)isLoading {
	if (_thread)
		return [_thread isLoading];
	else if ([super respondsToSelector:@selector(isLoading)])
		return [super isLoading];
	return NO;
}

#pragma mark -
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent { 
	if (__classAllowsTypeToJump && !_isPopUp) {
		NSString *characters = [theEvent characters];
		unichar character = [characters characterAtIndex:0];
		if (character>=48 && character<=57) {
			NSResponder *responder = [[self window] firstResponder];
			if ([responder conformsToProtocol:@protocol(NSTextInput)]) {
				NSRange range = [(id <NSTextInput>)responder selectedRange];
				if (range.location == NSNotFound) {
					if (!_typeBuffer) _typeBuffer = [[NSMutableString alloc] init];
					if ([_typeBuffer length] < 10000) {
						[_typeBuffer appendString:characters];
						if (_typeTimer) {
							[_typeTimer invalidate];
							[_typeTimer release];
							_typeTimer = nil;
						}
						_typeTimer = [[NSTimer scheduledTimerWithTimeInterval:__typeWait target:self
																	 selector:@selector(typeTimerFired:)
																	 userInfo:_typeBuffer repeats:NO] retain];
					} else {
						[_typeBuffer setString:@""];
					}
					return;
				}
			}
		}
	//	NSLog(@"Top is %d", [self resIndexDisplayedOnTop]+1);
	}
	[super keyDown:theEvent];
}
/*
- (void)keyUp:(NSEvent *)theEvent {
	if (__classAllowsTypeToJump && !_isPopUp) {
		
	}
	[super keyUp:theEvent];
}
 */
-(void)typeTimerFired:(NSTimer *)timer {
	if (_typeTimer && timer == _typeTimer) {
		[_typeTimer invalidate];
		[_typeTimer release];
		_typeTimer = nil;
		
		int number = [_typeBuffer intValue];
		if (number > 0 && number <= [_thread resCount]) {
			[self moveToResExtractPath:[NSString stringWithFormat:@"resNumber/%d", number]];
		}
		
		[_typeBuffer setString:@""];
	}
}


#pragma mark -
#pragma mark Methods

-(void)displayThread {
	NSString *resultHTML;
	NSURL *baseURL = nil;
	if (!(_thread && (_resExtractPath || _resIndexes))) return;
	if (_resExtractPath) {
		[self setResIndexes:[_thread resIndexesWithExtractPath:_resExtractPath]];
		
		if ([_resExtractPath isEqualToString:@"automatic"]) {
			unsigned resCount = [_thread resCount];
			int resIndex = [_thread savedResIndex];
			if (resIndex < 0) resIndex = 0;
			int toResIndex;
			
			if (resCount <= 100) {
				resIndex = 0;
				toResIndex = resCount-1;
			} else {
				if (resIndex < 50) {
					toResIndex = 100;
					resIndex = 0;
				} else if (resIndex+50 >= resCount) {
					resIndex = resCount-100;
					toResIndex = resCount-1;
				} else {
					resIndex-=50;
					toResIndex = resIndex + 100;
				}
			}
			
			//NSLog(@"initial:%d-%d", resIndex, toResIndex);
			
			resultHTML =[_thread extensibleHTMLFromResIndex:resIndex toResIndex:toResIndex baseURL:&baseURL];
			if (resultHTML) {
				//[self setInternalBaseURLprefixFromURL:baseURL];
				[[self mainFrame] loadHTMLString:resultHTML baseURL:baseURL];
				//[self performSelector:@selector(extendAll) withObject:nil afterDelay:0.1];
				//[self setNeedsDisplay:YES];
				[self setBaseURL:baseURL];
			}
			return;
		}
	}
	
	if (_HTMLExporter) {
		resultHTML = [_HTMLExporter HTMLWithThread:_thread baseURL:&baseURL];
	} else {
		resultHTML = [_thread HTMLForResIndexes:_resIndexes
										baseURL:&baseURL
									   forPopUp:_isPopUp];
	}
	if (resultHTML) {
		//[self setInternalBaseURLprefixFromURL:baseURL];
		[[self mainFrame] loadHTMLString:resultHTML baseURL:baseURL];
		[self setBaseURL:baseURL];
	}
	[self setNeedsDisplay:YES];
}

-(void)displayPreviewInsertion:(NSString *)htmlString {
	NSString *resultHTML;
	NSURL *baseURL = nil;
	resultHTML = [_thread HTMLWithOtherInsertion:htmlString
										 baseURL:&baseURL forPopUp:_isPopUp];
	if (resultHTML) [[self mainFrame] loadHTMLString:resultHTML baseURL:baseURL];
}

//-(void)updateThreadMenu ;
-(BOOL)displayElementByID:(NSString *)aString {
	NSString *result = [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"%@\").offsetTop;",aString]];
	if (result) {
		[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"scrollTo(0,%@);",result]];
		return YES;
	}
	return NO;
}
-(void)displayResForNumber:(unsigned)resNumber {
	[self displayElementByID:[NSString stringWithFormat:@"res%d", resNumber]];
}
-(DOMHTMLElement *)resElementForNumber:(unsigned)resNumber {
	return (DOMHTMLElement *)[[[self mainFrame] DOMDocument] getElementById:[NSString stringWithFormat:@"res%d", resNumber]];
}

-(void)registerDisplayResForNumber:(unsigned)resNumber {
	[[self internalDelegate] registerDisplayResForNumber:resNumber];
}
-(void)moveToResExtractPath:(NSString *)resExtractPath {
	NSString *selectedResExtractPath = resExtractPath;
	NSIndexSet *selectedResIndexes = [[self thread] resIndexesWithExtractPath:selectedResExtractPath];
	if (!selectedResIndexes) return;
	
	NSIndexSet *resIndexes = [self resIndexes];
	if (resIndexes) {
		if (![resIndexes containsIndexes:selectedResIndexes]) {
			NSMutableIndexSet *resultIndexSet = [[resIndexes mutableCopy] autorelease];
			[resultIndexSet addIndexes:selectedResIndexes];
			
			[self registerDisplayResForNumber:[selectedResIndexes firstIndex]+1];
			[self setResExtractPath:[NSString stringWithFormat:@"resNumber/%d-%d",
											[resultIndexSet firstIndex]+1, [resultIndexSet lastIndex]+1]];
		} else {
			[self displayResForNumber:[selectedResIndexes firstIndex]+1];
		}
	} else {
		[self registerDisplayResForNumber:[selectedResIndexes firstIndex]+1];
		[self setResExtractPath:selectedResExtractPath];
	}
}

-(unsigned)resIndexDisplayedOnTop {
	NSIndexSet *resIndexes = _resIndexes;
	unsigned resIndex = 0;
	resIndex = [resIndexes indexGreaterThanOrEqualToIndex:resIndex];
	
	//float docHeight = [(NSNumber *)[domDocument valueForKey:@"height"] floatValue];
	//float minDeltaY = [self frame].size.height;
	float docTop = [[self stringByEvaluatingJavaScriptFromString:@"window.scrollY;"] floatValue];
	float deltaY = 1;
	//NSLog(@"docTop=%d", (int)docTop);
	
	unsigned overshoot = NSNotFound;
	
	while (deltaY >= 0) {
		deltaY = [[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"res%d\").offsetTop;",resIndex+1]] floatValue];
		
		//NSLog(@"resIndex=%d, deltaY=%d", resIndex, (int)deltaY);
		
		if (deltaY > 0 && deltaY < docTop) {
			if (overshoot != NSNotFound) {
				resIndex = overshoot;
				break;
			}
			unsigned newResIndex = [resIndexes indexGreaterThanOrEqualToIndex:resIndex + 15];
			if (newResIndex == NSNotFound) {
				newResIndex = [resIndexes indexGreaterThanIndex:resIndex];
				if (newResIndex == NSNotFound) break;
			}
			resIndex = newResIndex;
		} else {
			overshoot = resIndex;
			unsigned newResIndex = [resIndexes indexLessThanIndex:resIndex];
			if (newResIndex == NSNotFound) break;
			resIndex = newResIndex;
		}
	}
	return resIndex;
}


-(void)extendTop {
	WebFrame *mainFrame = [self mainFrame];
	DOMDocument *domDocument = [mainFrame DOMDocument];
	if (![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	DOMElement *extensibleFooterElement = [(DOMHTMLDocument *)domDocument getElementById:@"extensibleHeader"];
	
	if (!extensibleFooterElement) return;
	DOMNodeList *childNodes = [extensibleFooterElement childNodes];
	DOMNode *chileNode = [childNodes item:0];
	NSString *extensibleResIndexesString = [(DOMHTMLElement *)chileNode innerText];
	
	if (!extensibleResIndexesString) return;
	int resIndex = [extensibleResIndexesString intValue]-1;
	unsigned toResIndex = resIndex;
	if (resIndex > 100) {
		resIndex = toResIndex-100;
	} else {
		resIndex = 0;
	}
	
	NSString *extensionHTML = [_thread extensionHTMLFromResIndex:resIndex toResIndex:toResIndex onDownstream:NO];
	
	[self storeTempScroll];
	[(DOMHTMLElement *)extensibleFooterElement setOuterHTML:extensionHTML];
	[self performSelector:@selector(loadTempScroll) withObject:nil afterDelay:0];
}

-(void)extendBottom {
	WebFrame *mainFrame = [self mainFrame];
	DOMDocument *domDocument = [mainFrame DOMDocument];
	if (![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	DOMElement *extensibleFooterElement = [(DOMHTMLDocument *)domDocument getElementById:@"extensibleFooter"];
	
	if (!extensibleFooterElement) return;
	DOMNodeList *childNodes = [extensibleFooterElement childNodes];
	DOMNode *chileNode = [childNodes item:0];
	NSString *extensibleResIndexesString = [(DOMHTMLElement *)chileNode innerText];
	
	if (!extensibleResIndexesString) return;
	int resIndex = [extensibleResIndexesString intValue];
	unsigned toResIndex = resIndex+100;
	unsigned resCount = [_thread resCount];
	if (toResIndex+1 > resCount) {
		toResIndex = resCount-1;
	}

	NSString *extensionHTML = [_thread extensionHTMLFromResIndex:resIndex toResIndex:toResIndex onDownstream:YES];
	
	[self storeTempScroll];
	[(DOMHTMLElement *)extensibleFooterElement setOuterHTML:extensionHTML];
	[self performSelector:@selector(loadTempScroll) withObject:nil afterDelay:0];
}

-(NSTimer *)extendTimer {
	return _extendTimer;
}
-(void)registerExtendAll {
	if (_extendTimer) return;
	_extendTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
													target:self
												  selector:@selector(extendAllTimerFired:)
												  userInfo:nil
												   repeats:NO];
}
-(void)extendAllTimerFired:(NSTimer *)timer {
	_extendTimer = nil;
	[self extendAll];
}
-(void)extendAll {
	NSString *headerExtensionHTML = nil;
	NSString *footerExtensionHTML = nil;
	
	WebFrame *mainFrame = [self mainFrame];
	DOMDocument *domDocument = [mainFrame DOMDocument];
	if (![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	DOMElement *extensibleHeaderElement = [(DOMHTMLDocument *)domDocument getElementById:@"extensibleHeader"];
	DOMElement *extensibleFooterElement = [(DOMHTMLDocument *)domDocument getElementById:@"extensibleFooter"];
	
	if (extensibleHeaderElement) {
		DOMNodeList *childNodes = [extensibleHeaderElement childNodes];
		DOMNode *chileNode = [childNodes item:0];
		NSString *extensibleHeaderResIndexesString = [(DOMHTMLElement *)chileNode innerText];
		
		if (extensibleHeaderResIndexesString) {
			int resIndex = [extensibleHeaderResIndexesString intValue]-1;
			headerExtensionHTML = [_thread extensionHTMLFromResIndex:0 toResIndex:resIndex onDownstream:NO];
		}
	}
	if (extensibleFooterElement) {
		DOMNodeList *childNodes = [extensibleFooterElement childNodes];
		DOMNode *chileNode = [childNodes item:0];
		NSString *extensibleFooterResIndexesString = [(DOMHTMLElement *)chileNode innerText];
		
		if (extensibleFooterResIndexesString) {
			unsigned resCount = [_thread resCount];
			int resIndex = [extensibleFooterResIndexesString intValue]-1;
			footerExtensionHTML = [_thread extensionHTMLFromResIndex:resIndex toResIndex:resCount-1 onDownstream:YES];
		}
	}
	//NSLog(@"extendAll:%d-%d", 0, [_thread resCount]-1);
	
	if (extensibleHeaderElement || extensibleFooterElement) {
		//[self storeTempScroll];
		if (extensibleHeaderElement)
			[(DOMHTMLElement *)extensibleHeaderElement setOuterHTML:headerExtensionHTML];
		if (extensibleFooterElement)
			[(DOMHTMLElement *)extensibleFooterElement setOuterHTML:footerExtensionHTML];
		//[self setNeedsDisplay:NO];
		[self loadScrollFromThread];
		//[self performSelector:@selector(loadScrollFromThread) withObject:nil afterDelay:0];
	}
	[_internalDelegate displayRegisteredRes];
	
	
	if (_delegate && [_delegate respondsToSelector:@selector(threadView:didDisplayThread:)]) {
		[_delegate threadView:self didDisplayThread:_thread];
	}
	if (_delegate && [_delegate respondsToSelector:@selector(threadView:didFinishLoadingThread:)]) {
		[_delegate threadView:self didFinishLoadingThread:_thread];
	}
	[self setThreadLoaded:YES];
}

-(void)extendLoadedResIndexs:(NSIndexSet *)resIndexes {
	
	//NSLog(@"extendLoadedResIndexs:%d-%d", [resIndexes firstIndex], [resIndexes firstIndex]+[resIndexes count]);
	
	NSArray *resArray = [_thread resArray];
	
	WebFrame *mainFrame = [self mainFrame];
	DOMDocument *domDocument = [mainFrame DOMDocument];
	if (![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	DOMElement *newMarkerElement = [(DOMHTMLDocument *)domDocument getElementById:@"new"];
	DOMElement *lastMarkerElement = [(DOMHTMLDocument *)domDocument getElementById:@"last"];
	
	if (!lastMarkerElement) return;
	
	[self storeTempScroll];
	unsigned i;
	
	unsigned resIndex = [resIndexes firstIndex];
	unsigned toResIndex = [resIndexes lastIndex];
	
	NSIndexSet *dirtyResIndexes = nil;
	if (resIndexes) {
		dirtyResIndexes = [_thread backwardAndSeriesResIndexesFromResIndexes:resIndexes];
	}
	
	// Remove class new
	
	[(DOMHTMLElement *)newMarkerElement setOuterHTML:@""];
	
	if (_resIndexes) {
		NSMutableIndexSet *mutableOldResIndexes = [[_resIndexes mutableCopy] autorelease];
		[mutableOldResIndexes removeIndexes:dirtyResIndexes];
		NSIndexSet *oldResIndexes = [[mutableOldResIndexes copy] autorelease];
		
		i = [oldResIndexes firstIndex];
		while (i < resIndex) {
			
			DOMHTMLElement *resElement = (DOMHTMLElement *)[(DOMHTMLDocument *)domDocument
															getElementById:[NSString stringWithFormat:@"res%d", i+1]];
			//[resElement removeClassName:@"new"];
			
			NSMutableString *className = [[resElement className] mutableCopy];
			[className replaceOccurrencesOfString:@"new" withString:@"old"
										  options:NSCaseInsensitiveSearch
											range:NSMakeRange(0, [className length])];
			
			/*
			NSString *tempScript = [NSString stringWithFormat:@"var tempElement = document.getElementById(\"%@\"); tempElement.setClassName(%@);",
									[NSString stringWithFormat:@"res%d", i+1],
									[[className copy] autorelease]];
			[[self windowScriptObject] evaluateWebScript:tempScript];
			*/
			
			//[resElement setAttribute:@"class" :[[className copy] autorelease]];
			
			[resElement setClassName:[[className copy] autorelease]];
			[className release];
			
			i = [oldResIndexes indexGreaterThanIndex:i];
		}
	}
	
	
	if (resIndex != NSNotFound && toResIndex != NSNotFound) {
		T2PluginManager *sharedManager = [T2PluginManager sharedManager];
		id <T2ThreadPartialHTMLExporting_v100> partialViewPlug = [sharedManager partialHTMLExporterPlugin];
	
		NSString *extensionHTML = [_thread extensionHTMLFromResIndex:resIndex toResIndex:toResIndex onDownstream:YES];
		/*
		if ([extensionHTML rangeOfString:@"res"].location == NSNotFound) {
			NSLog(@"extension failed at:%d-%d, {%@}", resIndex, toResIndex, extensionHTML);
		}
		 */
		
		// Replace Dirty
		if (dirtyResIndexes) {
			i = [dirtyResIndexes firstIndex];
			while (i < resIndex) {
				T2Res *res = [resArray objectAtIndex:i];
				NSString *processedResHTML = [sharedManager processedHTML:[partialViewPlug resHTMLWithRes:res]
																	ofRes:res
																 inThread:_thread];
				processedResHTML = [NSString stringWithFormat:
									@"<div class=\"%@\" id=\"res%d\">%@</div>",
									[res HTMLClassesString],
									i+1,
									processedResHTML];
				
				DOMHTMLElement *resElement = (DOMHTMLElement *)[(DOMHTMLDocument *)domDocument
																getElementById:[NSString stringWithFormat:@"res%d", i+1]];
				[resElement setOuterHTML:processedResHTML];
				
				i = [dirtyResIndexes indexGreaterThanIndex:i];
			}
		}
		[(DOMHTMLElement *)lastMarkerElement setOuterHTML:extensionHTML];
	}
	
	//setObjectWithRetain(_loadedResIndexes, resIndexes);
	
	//[self setNeedsDisplay:NO];
	//[self performSelector:@selector(loadTempScroll) withObject:nil afterDelay:0];
	[self loadTempScroll];
	[self setNeedsDisplay:YES];
}

-(void)storeTempScroll {
	WebFrame *mainFrame = [self mainFrame];
	DOMDocument *domDocument = [mainFrame DOMDocument];
	if (![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	unsigned resIndex = [self resIndexDisplayedOnTop];
	float docTop = [[self stringByEvaluatingJavaScriptFromString:@"window.scrollY;"] floatValue];
	float resTop = [[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"res%d\").offsetTop;",resIndex+1]] floatValue];
	float offset = docTop - resTop;
	
	_storedResIndex = resIndex;
	_storedScrollOffset = offset;
	//NSLog(@"scroll stored: Res:%d delta:%d", resIndex, (int)offset);
}
-(void)loadTempScroll {
	unsigned resIndex = _storedResIndex;
	if (resIndex < 0) return;
	float offset = _storedScrollOffset;
	float resTop = [[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"res%d\").offsetTop;",resIndex+1]] floatValue];
	float docTop = resTop + offset;
	[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"scrollTo(0,%d);",(int)docTop]];

	//NSLog(@"scroll reverted: Res:%d delta:%d", resIndex, (int)offset);
}

-(void)saveScrollToThread {
	WebFrame *mainFrame = [self mainFrame];
	DOMDocument *domDocument = [mainFrame DOMDocument];
	if (![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	unsigned resIndex = [self resIndexDisplayedOnTop];
	float docTop = [[self stringByEvaluatingJavaScriptFromString:@"window.scrollY;"] floatValue];
	float resTop = [[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"res%d\").offsetTop;",resIndex+1]] floatValue];
	float offset = docTop - resTop;
	
	[_thread setSavedResIndex:resIndex];
	[_thread setSavedScrollOffset:offset];
	//NSLog(@"scroll saved: Res:%d delta:%d", resIndex, (int)offset);
}
-(void)loadScrollFromThread {
	int resIndex = [_thread savedResIndex];
	if (resIndex < 0) return;
	float offset = [_thread savedScrollOffset];
	float resTop = [[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"res%d\").offsetTop;",resIndex+1]] floatValue];
	float docTop = resTop + offset;
	[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"scrollTo(0,%d);",(int)docTop]];
	
	//NSLog(@"scroll loaded: Res:%d delta:%d", resIndex, (int)offset);
}

#pragma mark Preview

-(BOOL)previewAnchorElement:(DOMHTMLAnchorElement *)anchorElement withType:(T2PreviewType)type {
	switch (type) {
		case T2PreviewInPopUp: {
			NSString *urlString = [anchorElement href];
			if (urlString && _thread) {
				T2PopUpWindowController *popUpWindowController = [T2PopUpWindowController popUpWindowControllerWithURLString:urlString
																													inThread:_thread];
				if (popUpWindowController) {
					
					[popUpWindowController retain];
					[_internalDelegate setChildInternalDelegate:[[popUpWindowController threadView] internalDelegate]];
					[_internalDelegate popUpRetain];
					return YES;
				}
			}
			break;
		}
		case T2PreviewInline: {
			NSString *urlString = [anchorElement href];
			if ([urlString hasPrefix:@"internal://"]) {
				if ([self replaceResAnchorElement:anchorElement WithResExtractPath:urlString]) {
					return YES;
				}
			} else if ([[T2PluginManager sharedManager] isPreviewableURLString:urlString type:T2PreviewInline]) {
				if ([self replacePreviewableAnchorElement:anchorElement]) {
					return YES;
				}
			}
			break;
		}
		default:
			break;
	}
	return NO;
}

-(BOOL)replaceResAnchorElement:(DOMHTMLAnchorElement *)anchorElement WithResExtractPath:(NSString *)extractPath {
	if (!_thread) return NO;
	unsigned resNumber = [anchorElement parentResNumber];
	NSIndexSet *resIndexes = [_thread resIndexesWithExtractPath:extractPath];
	if (!resIndexes || [resIndexes count] == 0) return NO;
	if (resNumber != NSNotFound && [resIndexes containsIndex:resNumber-1]) {
		NSMutableIndexSet *resultIndexes = [[resIndexes mutableCopy] autorelease];
		[resultIndexes removeIndex:resNumber-1];
		if ([resIndexes count] == 0) return NO;
		//resIndexes = 
		NSString *excerptHTML = [_thread excerptHTMLForResIndexes:resultIndexes];
		if (!excerptHTML) return NO;
		// Append
		DOMHTMLDivElement *resDivElement = [anchorElement parentResDivElement];
		DOMHTMLDocument *document = (DOMHTMLDocument *)[resDivElement ownerDocument];
		DOMHTMLElement *newElement = (DOMHTMLElement *)[document createElement:@"q"];
		[resDivElement appendChild:newElement];
		[newElement setOuterHTML:excerptHTML];
		
		// disable link
		[anchorElement addClassName:T2HTMLClassNameNoPreview];
	} else {
		[anchorElement addClassName:T2HTMLClassNameNoPreview];
		[anchorElement removeNextWhiteAndBRElement];
		NSString *excerptHTML = [_thread excerptHTMLForResIndexes:resIndexes];
		NSString *html = [[anchorElement outerHTML] stringByAppendingString:excerptHTML];
		[anchorElement replaceWithHTML:html];
	}
	return YES;
}

-(BOOL)replacePreviewableAnchorElement:(DOMHTMLAnchorElement *)anchorElement {
	NSString *urlString = [anchorElement href];
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	if (!urlString || ![pluginManager isPreviewableURLString:urlString
														type:T2PreviewInline])
		return NO;
	NSSize size = NSMakeSize(0, 0);
	NSString *html = [pluginManager partialHTMLforPreviewingURLString:urlString
																 type:T2PreviewInline
															  minSize:&size];
	if (!html) return NO;
	[anchorElement replaceWithHTML:html];
	return YES;
}

-(void)replacePreviewableAnchorElementsInResExtractPath:(NSString *)resExtractPath {
	NSIndexSet *resIndexes = [_thread resIndexesWithExtractPath:resExtractPath];
	[self replacePreviewableAnchorElementsInResIndexes:resIndexes];
}

-(void)replacePreviewableAnchorElementsInResIndexes:(NSIndexSet *)resIndexes {
	if (!resIndexes) return;
	
	DOMDocument *domDocument = [[self mainFrame] DOMDocument];
	if (!domDocument || ![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	
	unsigned resIndex = [resIndexes firstIndex];
	unsigned displayResIndex = [_resIndexes firstIndex];
	if (displayResIndex > resIndex) {
		resIndex = [_resIndexes indexGreaterThanOrEqualToIndex:displayResIndex];
	}
	if (resIndex == NSNotFound) return;
	
	DOMElement *resElement;
	while (resElement = [domDocument getElementById:[NSString stringWithFormat:@"res%d", resIndex+1]]) {
		BOOL continueLoop = YES;
		while (continueLoop) {
			DOMNodeList *anchorElementList = [resElement getElementsByTagName:@"A"];
			DOMHTMLAnchorElement *anchorElement = nil;
			NSMutableSet *urlStringSet = [NSMutableSet set];
			unsigned urlCount = 0, lastResNumber = 0;
			unsigned long i, maxCount = [anchorElementList length];
			for (i=0; i<maxCount; i++) {
				anchorElement = (DOMHTMLAnchorElement *)[anchorElementList item:i];
				if (![anchorElement hasClassName:T2HTMLClassNameNoPreview] &&
					![[anchorElement parentResDivElement] hasClassName:T2HTMLClassNameDanger]) {
					NSString *urlString = [anchorElement href];
					unsigned resNumber = [anchorElement parentResNumber];
					if (![urlString hasPrefix:@"internal://"] &&
						resNumber != NSNotFound &&
						[pluginManager isPreviewableURLString:urlString
														 type:T2PreviewInline]) {
						if (resNumber > lastResNumber) {
							lastResNumber = resNumber;
							[urlStringSet removeAllObjects];
						}
						if (![urlStringSet containsObject:urlString]) {
							[urlStringSet addObject:urlString];
							[self replacePreviewableAnchorElement:anchorElement];
							urlCount++;
							break;
						}
					}
				}
			}
			if (i >= maxCount) continueLoop = NO;
			if (urlCount > 3000) continueLoop = NO;
			
		}
		resIndex = [resIndexes indexGreaterThanIndex:resIndex];
		if (resIndex == NSNotFound) break;
	}
}

-(void)replaceAllPreviewableAnchorElements {
	DOMDocument *domDocument = [[self mainFrame] DOMDocument];
	if (!domDocument || ![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	
	BOOL continueLoop = YES;
	while (continueLoop) {
		DOMNodeList *anchorElementList = [domDocument getElementsByTagName:@"A"];
		DOMHTMLAnchorElement *anchorElement = nil;
		NSMutableSet *urlStringSet = [NSMutableSet set];
		unsigned urlCount = 0, lastResNumber = 0;
		unsigned long i, maxCount = [anchorElementList length];
		for (i=0; i<maxCount; i++) {
			anchorElement = (DOMHTMLAnchorElement *)[anchorElementList item:i];
			if (![anchorElement hasClassName:T2HTMLClassNameNoPreview] &&
				![[anchorElement parentResDivElement] hasClassName:T2HTMLClassNameDanger]) {
				NSString *urlString = [anchorElement href];
				unsigned resNumber = [anchorElement parentResNumber];
				if (![urlString hasPrefix:@"internal://"] &&
					resNumber != NSNotFound &&
					[pluginManager isPreviewableURLString:urlString
													 type:T2PreviewInline]) {
					if (resNumber > lastResNumber) {
						lastResNumber = resNumber;
						[urlStringSet removeAllObjects];
					}
					if (![urlStringSet containsObject:urlString]) {
						[urlStringSet addObject:urlString];
						[self replacePreviewableAnchorElement:anchorElement];
						urlCount++;
						break;
					}
				}
			}
		}
		if (i >= maxCount) continueLoop = NO;
		if (urlCount > 3000) continueLoop = NO;
	}
}

-(NSArray *)urlStringsOfAnchorElementsInResExtractPath:(NSString *)resExtractPath {
	
	NSIndexSet *resIndexes = [_thread resIndexesWithExtractPath:resExtractPath];
	return [self urlStringsOfAnchorElementsInResIndexes:resIndexes];
}
-(NSArray *)urlStringsOfAnchorElementsInResIndexes:(NSIndexSet *)resIndexes {
	if (!resIndexes) return nil;
	
	DOMDocument *domDocument = [[self mainFrame] DOMDocument];
	if (!domDocument || ![domDocument isKindOfClass:[DOMHTMLDocument class]]) return nil;
	
	//T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	
	unsigned resIndex = [resIndexes firstIndex];
	unsigned displayResIndex = [_resIndexes firstIndex];
	if (displayResIndex > resIndex) {
		resIndex = [_resIndexes indexGreaterThanOrEqualToIndex:displayResIndex];
	}
	if (resIndex == NSNotFound) return nil;
	NSMutableSet *urlStringSet = [NSMutableSet set];
	
	DOMElement *resElement;
	while (resElement = [domDocument getElementById:[NSString stringWithFormat:@"res%d", resIndex+1]]) {
		BOOL continueLoop = YES;
		while (continueLoop) {
			DOMNodeList *anchorElementList = [resElement getElementsByTagName:@"A"];
			DOMHTMLAnchorElement *anchorElement = nil;
			unsigned urlCount = 0; //, lastResNumber = 0;
			unsigned long i, maxCount = [anchorElementList length];
			for (i=0; i<maxCount; i++) {
				anchorElement = (DOMHTMLAnchorElement *)[anchorElementList item:i];
				
				NSString *urlString = [anchorElement href];
				unsigned resNumber = [anchorElement parentResNumber];
				if (![urlString hasPrefix:@"internal://"] && resNumber != NSNotFound) {
					[urlStringSet addObject:urlString];
					urlCount++;
				}
			}
			if (i >= maxCount) continueLoop = NO;
			if (urlCount > 3000) continueLoop = NO;
			
		}
		resIndex = [resIndexes indexGreaterThanIndex:resIndex];
		if (resIndex == NSNotFound) break;
	}
	return [urlStringSet allObjects];
}

#pragma mark -
#pragma mark Actions
-(IBAction)setSelectedResStyleAction:(id)sender {
	NSString *style = [(NSMenuItem *)sender representedObject];
	//if ([style isEqualToString:@"invisible"]) {
		DOMDocument *document = [[self mainFrame] DOMDocument];
		DOMRange *range = [document createRange];
		[self setSelectedDOMRange:range affinity:NSSelectionAffinityDownstream];
	//}
	if (_styleTimer) {
		[_styleTimer invalidate];
		[_styleTimer release];
		_styleTimer = nil;
	}
	NSDictionary *timerDic = [NSDictionary dictionaryWithObjectsAndKeys:
							  style, @"style",
							  _selectedResExtractPath, @"selectedResExtractPath",
							  nil];
	
	_styleTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01
												   target:self selector:@selector(styleTimerFired:)
												  userInfo:timerDic repeats:NO] retain];
	//[_thread addStyle:style ofResWithExtractPath:_selectedResExtractPath];	
}
-(void)styleTimerFired:(NSTimer *)timer {
	NSDictionary *timerDic = [timer userInfo];
	NSString *style = [timerDic objectForKey:@"style"];
	NSString *selectedResExtractPath = [timerDic objectForKey:@"selectedResExtractPath"];
	[_thread addStyle:style ofResWithExtractPath:selectedResExtractPath];
	
	[_styleTimer invalidate];
	[_styleTimer release];
	_styleTimer = nil;
}

-(IBAction)removeSelectedResStyleAction:(id)sender {
	[_thread removeStylesOfResWithExtractPath:_selectedResExtractPath];
}
-(IBAction)setResStyleAction:(id)sender {
	NSString *style = [(NSMenuItem *)sender representedObject];
	if ([style isEqualToString:@"invisible"]) {
		DOMDocument *document = [[self mainFrame] DOMDocument];
		DOMRange *range = [document createRange];
		[self setSelectedDOMRange:range affinity:NSSelectionAffinityDownstream];
	}
	[_thread addStyle:style ofResWithExtractPath:_resExtractPath];	
}
-(IBAction)removeResStyleAction:(id)sender {
	[_thread removeStylesOfResWithExtractPath:_resExtractPath];
}
-(IBAction)removeAllResStyleAction:(id)sender {
	[_thread removeAllStyles];
}

#pragma mark -
#pragma mark Internal
#pragma mark -
#pragma mark Notification Observing
-(void)threadDidLoadResIndexes:(NSNotification *)notification {
	NSDictionary *dic = [notification userInfo];
	NSIndexSet *resIndexes = [dic objectForKey:T2ThreadResIndexes];
	
	[self setThreadLoaded:NO];
	if ([_resExtractPath isEqualToString:@"automatic"]) {
		
		if (resIndexes && [resIndexes firstIndex] == 0) {
			[self displayThread];
		} else {
			if (_extendTimer) {
				[_extendTimer invalidate];
				_extendTimer = nil;
				[self extendAll];
			}
			[self extendLoadedResIndexs:resIndexes];
		}
		
		unsigned resCount = [_thread resCount];
		setObjectWithRetain(_resIndexes, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, resCount)]);
	} else {
		[self displayThread];
	}
}

-(void)threadDidUpdateStyleOfResIndexes:(NSNotification *)notification {
	[self thread:_thread didUpdateStyleOfResIndexes:[[notification userInfo] objectForKey:T2ThreadResIndexes]];
}
-(void)thread:(T2Thread *)thread didUpdateStyleOfResIndexes:(NSIndexSet *)resIndexes {
	NSArray *resArray = [_thread originalResArray];
	DOMDocument *document = [[self mainFrame] DOMDocument];
	if (resIndexes && document) {
		[self setSelectedDOMRange:nil affinity:0];
		unsigned resIndex = [resIndexes firstIndex];
		while (resIndex != NSNotFound) {
			NSString *elementID = [NSString stringWithFormat:@"res%d",resIndex+1];
			DOMElement *element = [document getElementById:elementID];
			if (element) {
				T2Res *res = [resArray objectAtIndex:resIndex];
				[element setAttribute:@"class" :[res HTMLClassesString]];
			}
			resIndex = [resIndexes indexGreaterThanIndex:resIndex];
		}
		[self setNeedsDisplay:YES];
	}
}
#pragma mark -
#pragma mark Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([keyPath isEqualToString:@"estimatedProgress"]) {
		[self willChangeValueForKey:@"estimatedProgress"];
		[self didChangeValueForKey:@"estimatedProgress"];
	} else if ([keyPath isEqualToString:@"isLoading"]) {
		[self willChangeValueForKey:@"isLoading"];
		[self didChangeValueForKey:@"isLoading"];
	}
}
@end


@interface T2ThreadViewInternalDelegate (T2ThreadViewInternalDelegatePrivateMethods)
-(void)setParentInternalDelegate:(T2ThreadViewInternalDelegate *)parentInternalDelegate ;

@end

@implementation T2ThreadViewInternalDelegate

#pragma mark -
#pragma mark Init

+(void)initialize {
	if (__T2ThreadViewInternalDelegate) return;
	__T2ThreadViewInternalDelegate = [self class];
}

-(id)init {
	self = [super init];
	//_popUpRetainCount = 1;
	return self;
}

-(void)dealloc {
	[self flushHoverTimer];
	[self flushReleaseTimer];
	[self setChildInternalDelegate:nil];
	[self setParentInternalDelegate:nil];
	[_hoveredAnchorElement release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(void)setThreadView:(T2ThreadView *)threadView {
	_threadView = threadView;
}
-(T2ThreadView *)threadView { return _threadView; }

-(NSWindow *)window { return [_threadView window]; }


#pragma mark -
#pragma mark Child and Parent Control
-(void)setParentInternalDelegate:(T2ThreadViewInternalDelegate *)parentInternalDelegate {
	_parentInternalDelegate = parentInternalDelegate;
}
-(T2ThreadViewInternalDelegate *)parentInternalDelegate {
	return _parentInternalDelegate;
}

-(void)setChildInternalDelegate:(T2ThreadViewInternalDelegate *)childInternalDelegate {
	if (childInternalDelegate == _childInternalDelegate) return;
	
	if (_childInternalDelegate) {
		//[[_childInternalDelegate threadView] setDelegate:nil];
		[_childInternalDelegate setParentInternalDelegate:nil];
		[_childInternalDelegate popUpClose];
		[_childInternalDelegate release];
	}
	
	_childInternalDelegate = childInternalDelegate;
	
	if (_childInternalDelegate) {
		[_childInternalDelegate retain];
		[[_childInternalDelegate threadView] setDelegate:[[self threadView] delegate]];
		[_childInternalDelegate setParentInternalDelegate:self];
		[_childInternalDelegate popUpRetain];
		/*
		 _childWindow = [childInternalDelegate window];
		 [defaultCenter addObserver:self selector:@selector(childWindowWillClose:) name:NSWindowWillCloseNotification
		 object:_childWindow];
		 */
	}
}
-(T2ThreadViewInternalDelegate *)childInternalDelegate {
	return _childInternalDelegate;
}

-(void)childWindowWillClose {
	/*
	 if (_childInternalDelegate) {
	 [_childInternalDelegate setParentInternalDelegate:nil];
	 _childInternalDelegate = nil;
	 _childWindow = nil;
	 }
	 */
	
	if (_childInternalDelegate) {
		[_childInternalDelegate setParentInternalDelegate:nil];
		[_childInternalDelegate release];
		_childInternalDelegate = nil;
	}
	[self popUpRelease];
}
/*
 -(void)childWindowWillClose:(NSNotification *)notification {
 
 [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification
 object:_childWindow];
 
 if (_childInternalDelegate) {
 [_childInternalDelegate setParentInternalDelegate:nil];
 _childInternalDelegate = nil;
 _childWindow = nil;
 }
 [self popUpRelease];
 }
 */
/*
 -(void)becomeParentOfChildInternalDelegate:(T2ThreadViewInternalDelegate *)childInternalDelegate {
 if (self == childInternalDelegate) return;
 [self setChildInternalDelegate:childInternalDelegate];
 [childInternalDelegate setParentInternalDelegate:self];
 }
 
 -(void)setParentInternalDelegate:(T2ThreadViewInternalDelegate *)parentInternalDelegate {
 //@synchronized(self) {
 if (parentInternalDelegate != _parentInternalDelegate) {
 [_parentInternalDelegate setChildInternalDelegate_internal:nil];
 [_parentInternalDelegate popUpRelease];
 }
 _parentInternalDelegate = parentInternalDelegate;
 [parentInternalDelegate popUpRetain];
 //}
 }
 -(void)setParentInternalDelegate_internal:(T2ThreadViewInternalDelegate *)parentInternalDelegate {
 _parentInternalDelegate = parentInternalDelegate;
 }
 -(T2ThreadViewInternalDelegate *)parentInternalDelegate { return _parentInternalDelegate; }
 -(void)setChildInternalDelegate:(T2ThreadViewInternalDelegate *)childInternalDelegate {
 //@synchronized(self) {
 if (childInternalDelegate != _childInternalDelegate)
 [_childInternalDelegate setParentInternalDelegate_internal:nil];
 _childInternalDelegate = childInternalDelegate;
 //}
 }
 -(void)setChildInternalDelegate_internal:(T2ThreadViewInternalDelegate *)childInternalDelegate {
 _childInternalDelegate = childInternalDelegate;
 }
 -(T2ThreadViewInternalDelegate *)childInternalDelegate { return _childInternalDelegate; }
 */

#pragma mark -
#pragma mark PopUp Control
-(void)registerHoveredAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags {
	
	if (anchorElement || _hoveredAnchorElement) {
		NSString *href = [anchorElement href];
		if (anchorElement) {
			if (anchorElement == _hoveredAnchorElement)
				return;
			
			NSString *resExtractPath = [_threadView resExtractPath];
			if (resExtractPath && [href isEqualToString:resExtractPath])
				return;
		}
		
		if (_hoveredAnchorElement && (!anchorElement || !(anchorElement == _hoveredAnchorElement))) {
			if (_childInternalDelegate) {
				[_childInternalDelegate popUpReleaseWithDelay];
			}
		}
		
		[self flushHoverTimer];
		
		setObjectWithRetain(_hoveredAnchorElement, anchorElement);
		if (_hoveredAnchorElement && !_popUpReleaseTimer) {
			if ([href hasPrefix:@"internal://"] ||
				(!([_threadView isPopup] && ![_threadView resExtractPath])  &&
				 [[T2PluginManager sharedManager] isPreviewableURLString:href type:T2PreviewInPopUp])) {
				
				_hoverTimer = [[NSTimer scheduledTimerWithTimeInterval:__popUpWait
																target:self
															  selector:@selector(hoverTimerFired:)
															  userInfo:_hoveredAnchorElement
															   repeats:NO] retain];
				_modifierFlags = modifierFlags;
			}
		}
	}
}

-(void)hoverTimerFired:(NSTimer *)timer {
	if (timer != _hoverTimer) return;
	DOMHTMLAnchorElement *anchorElement = [timer userInfo];
	T2Thread *thread = [[self threadView] thread];
	[self flushHoverTimer];
	if (anchorElement && thread) {
		NSObject *delegate = [_threadView delegate];
		if (delegate && [delegate respondsToSelector:@selector(threadView:shouldHandlePopUpAnchorElement:modifierFlags:)]) {
			if (![delegate threadView:_threadView shouldHandlePopUpAnchorElement:anchorElement modifierFlags:_modifierFlags]) {
				return;
			}
		}
		[_threadView previewAnchorElement:anchorElement withType:T2PreviewInPopUp];
	}
}

-(void)popUpRetain {
	if (![_threadView isPopup]) return;
	_popUpRetainCount++;
}
-(void)popUpRelease {
	if (![_threadView isPopup]) return;
	_popUpRetainCount--;
	if (_popUpRetainCount <= 0) {
		[self popUpClose];
	}
}
-(void)popUpReleaseWithDelay {
	if (_popUpRetainCount <= 0) return;
	if (![_threadView isPopup]) return;
	if (_popUpReleaseTimer) {
		[self flushReleaseTimer];
		if (_popUpRetainCount > 1) {
			[self popUpRelease];
		}
	}
	_popUpReleaseTimer = [[NSTimer scheduledTimerWithTimeInterval:__popUpWait
														   target:self
														 selector:@selector(popUpReleaseTimerFired:)
														 userInfo:nil
														  repeats:NO] retain];	
}
-(void)popUpReleaseTimerFired:(NSTimer *)timer {
	if (timer != _popUpReleaseTimer) return;
	[self flushReleaseTimer];
	[self popUpRelease];
}
-(void)popUpClose {
	if ([_threadView isPopup]) {
		[self flushHoverTimer];
		[self flushReleaseTimer];
		[[_threadView window] close];
	}
}
-(void)popUpCloseWithDelay {
	_popUpRetainCount = 1;
	[self popUpReleaseWithDelay];
}

-(void)flushHoverTimer {
	if (_hoverTimer) {
		[_hoverTimer invalidate];
		[_hoverTimer release];
		_hoverTimer = nil;
	}
}
-(void)flushReleaseTimer {
	if (_popUpReleaseTimer) {
		[_popUpReleaseTimer invalidate];
		[_popUpReleaseTimer release];
		_popUpReleaseTimer = nil;
	}
}
-(void)makeThreadViewToFirstResponder {
	NSWindow *window = [_threadView window];
	[window makeMainWindow];
	[window makeFirstResponder:_threadView];
}
-(void)performClickHoveredAnchorElement {
	if (!_hoveredAnchorElement) return;
	NSEvent *currentEvent = [NSApp currentEvent];
	[self clickAnchorElement:_hoveredAnchorElement modifierFlags:[currentEvent modifierFlags]];
}

#pragma mark -
#pragma mark Other Methods
-(void)registerDisplayResForNumber:(unsigned)resNumber {
	_registeredResNumberToDisplay = resNumber;
}
-(void)displayRegisteredRes {
	if (_registeredResNumberToDisplay > 0) {
		[_threadView displayResForNumber:_registeredResNumberToDisplay];
		_registeredResNumberToDisplay = 0;
	}
}


#pragma mark -
#pragma mark WebFrameLoadingDelegate
- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame {
}
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
	WebFrame *mainFrame = [sender mainFrame];
	DOMDocument *domDocument = [mainFrame DOMDocument];
	if (![domDocument isKindOfClass:[DOMHTMLDocument class]]) return;
	
	DOMHTMLHtmlElement *domElement = (DOMHTMLHtmlElement *)[(DOMHTMLDocument *)domDocument documentElement];
	DOMHTMLBodyElement *body = nil;
	DOMNodeList *nodeList = [domElement childNodes];
	unsigned i, length = [nodeList length];
	for (i=0; i<length; i++) {
		DOMNode *node = [nodeList item:i];
		if ([node isKindOfClass:[DOMHTMLBodyElement class]]) {
			body = (DOMHTMLBodyElement *)node;
		}
	}
	
	if (body && !__Safari2Debug) {
		[body addEventListener:@"mouseover"
							  :self
							  :YES];
		
		[body addEventListener:@"click"
							  :self
							  :YES];
	}
	
	
	if ([[_threadView resExtractPath] isEqualToString:@"automatic"]) {
		[_threadView loadScrollFromThread];
		[_threadView registerExtendAll];
	} else {
		if (_registeredResNumberToDisplay > 0) {
			[_threadView displayResForNumber:_registeredResNumberToDisplay];
			_registeredResNumberToDisplay = 0;
		}
	}
	
	NSObject *delegate = [_threadView delegate];
	
	if (delegate && [delegate respondsToSelector:@selector(threadView:didDisplayThread:)]) {
		[delegate threadView:_threadView didDisplayThread:[_threadView thread]];
	}
	if (![_threadView threadLoaded]) {
		if ([_threadView extendTimer]) {
			return;
		}
		[_threadView setThreadLoaded:YES];
		if (delegate && [delegate respondsToSelector:@selector(threadView:didFinishLoadingThread:)]) {
			[delegate threadView:_threadView didFinishLoadingThread:[_threadView thread]];
		}
	}
}
#pragma mark -
#pragma mark WebResourceLoadDelegate

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	NSURL *url = [request URL];
	if ([url isFileURL]) {
		
		NSString *absoluteString = [url filePath];
		//NSString *prefixString = [_threadView internalBaseURLprefix];
		NSString *prefixString = [[NSBundle mainBundle] bundlePath];
		NSString *prefixString2 = [NSString ownAppSupportFolderPath];

		if (prefixString) {
			if (![absoluteString hasPrefix:prefixString] && ![absoluteString hasPrefix:prefixString2]) {
				return nil;
			}
		}
	}
	return request;
}

-(void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource {
	[[challenge sender] cancelAuthenticationChallenge:challenge];
	return;
}
#pragma mark -
#pragma mark WebPolicyDelegate
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener {
	
	NSURL *url = [request URL];
	NSString *urlString = [url absoluteString];
	//NSURL *url = [NSURL URLWithString:urlString];
	
	if ([url isFileURL]) {
		NSURL *baseURL = [_threadView baseURL];
		if ([baseURL isFileURL]) {
			NSString *absoluteString = [url filePath];
			NSString *prefixString = [baseURL filePath];
			if (prefixString) {
				if ([absoluteString hasPrefix:prefixString]) {
					[listener use];
					return;
				}
			}
		}
	} else if ([urlString hasPrefix:@"applewebdata://"] ||
			   [urlString hasPrefix:@"javascript:"]) {
		[listener use];
		return;
	}
		
	if (__DOMEventEnabled && !__Safari2Debug) {
		NSObject *delegate = [_threadView delegate];
		//int modifierFlags = [[NSApp currentEvent] modifierFlags];
		if ([urlString hasPrefix:@"internal://"]) {
			[listener ignore];
			NSDictionary *elementInfomation = [actionInformation objectForKey:WebActionElementKey];
			if (!elementInfomation) {
				[_threadView setResExtractPath:urlString];
				return;
			}
			if (delegate && [delegate respondsToSelector:@selector(threadView:clickedResPath:)]) {
				[delegate threadView:_threadView clickedResPath:urlString];
			}
			return;
		}
		[listener use];
		
	} else {
		NSDictionary *elementInfomation = [actionInformation objectForKey:WebActionElementKey];
		DOMNode *domNode = [elementInfomation objectForKey:WebElementDOMNodeKey];
		if (domNode) {
			DOMHTMLAnchorElement *anchorElement = [domNode parentAnchorElement];
			if (anchorElement) {
				if ([self clickAnchorElement:anchorElement modifierFlags:[[NSApp currentEvent] modifierFlags]]) {
					[listener ignore];
					return;
				}
			} else { // CAUTION!! for Safari 3.0 bug
				NSObject *delegate = [_threadView delegate];
				if ([urlString hasPrefix:@"internal://"]) {
					if (delegate && [delegate respondsToSelector:@selector(threadView:clickedResPath:)]) {
						[delegate threadView:_threadView clickedResPath:urlString];
					}
				} else {
					NSString *internalPath = [[T2PluginManager sharedManager] threadInternalPathForProposedURLString:urlString];
					if (internalPath) {
						if (delegate && [delegate respondsToSelector:@selector(threadView:clickedThreadPath:)]) {
							[delegate threadView:_threadView clickedThreadPath:internalPath];
						}
						
					} else {
						if (delegate && [delegate respondsToSelector:@selector(threadView:clickedOtherURL:)]) {
							[delegate threadView:_threadView clickedOtherURL:urlString];
						}
					}
				}
				[listener ignore];
				return;
			}
		}
	}
	[listener use];	
}

#pragma mark -
#pragma mark WebUIDelegate

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation
  modifierFlags:(unsigned int)modifierFlags {
	if (__DOMEventEnabled && !__Safari2Debug) return;
	DOMNode *domNode = [elementInformation objectForKey:WebElementDOMNodeKey];
	if (!domNode) return;
	
	NSURL *linkedURL = [elementInformation objectForKey:WebElementLinkURLKey];
	WebFrame *targetFrame = [elementInformation objectForKey:WebElementLinkTargetFrameKey];
	if (linkedURL && targetFrame) {
		
		DOMHTMLAnchorElement *anchorElement = [domNode parentAnchorElement];
		if (anchorElement) {
			[self mouseoverAnchorElement:anchorElement modifierFlags:modifierFlags];
			return;
		}
	}
	[self registerHoveredAnchorElement:nil modifierFlags:0];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element
	defaultMenuItems:(NSArray *)defaultMenuItems {
	T2ThreadView *threadView;
	if ([sender isKindOfClass:[T2ThreadView class]]) {
		threadView = (T2ThreadView *)sender;
	} else {
		return nil;
	}
	
	id delegate = [(T2ThreadView *)sender delegate];
	NSNumber *hasSelection = [element objectForKey:WebElementIsSelectedKey];
	DOMNode *node = [element objectForKey:WebElementDOMNodeKey];
	unsigned resNumber = [node parentResNumber];
	
	NSURL *linkedURL = [element objectForKey:WebElementLinkURLKey];
	
	NSMutableArray *menuItems = [NSMutableArray array];
	
	//
	
	
	if (linkedURL) {
		
		NSString *linkedURLString = [linkedURL absoluteString];
		if ([[linkedURL scheme] isEqualToString:@"internal"]) {
			NSString *resExtractPath = [linkedURLString stringByDeletingfirstPathComponent];
			
			[threadView setSelectedResExtractPath:resExtractPath];
			if (delegate && [delegate respondsToSelector:@selector(threadView:contextMenuItemsForResPath:defaultMenuItems:)]) {
				NSArray *newMenuItems = [delegate threadView:threadView contextMenuItemsForResPath:resExtractPath defaultMenuItems:defaultMenuItems];
				if (newMenuItems) {
					return newMenuItems;
				}
			}
		} else {
			if (delegate && [delegate respondsToSelector:@selector(threadView:contextMenuItemsForOtherURL:defaultMenuItems:)]) {
				NSArray *newMenuItems = [delegate threadView:threadView contextMenuItemsForOtherURL:linkedURLString defaultMenuItems:defaultMenuItems];
				if (newMenuItems) {
					return newMenuItems;
				}
			}
		}
	} else if (hasSelection && [hasSelection boolValue]) {
		
		if (delegate && [delegate respondsToSelector:@selector(threadView:contextMenuItemsForSelectedString:defaultMenuItems:)]) {
			
			NSString *selection = [[threadView selectedDOMRange] toStringContainsLineBreaks];
			NSArray *newMenuItems = [delegate threadView:threadView contextMenuItemsForSelectedString:selection defaultMenuItems:defaultMenuItems];
			if (newMenuItems) {
				[menuItems addObjectsFromArray:newMenuItems];
				
				if (resNumber != NSNotFound && resNumber > 0) {
					
					NSString *extractPath = [NSString stringWithFormat:@"resNumber/%d",resNumber];
					[threadView setSelectedResExtractPath:extractPath];
					if (delegate && [delegate respondsToSelector:@selector(threadView:contextMenuItemsForResPath:defaultMenuItems:)]) {
						NSArray *newMenuItems2 = [delegate threadView:threadView contextMenuItemsForResPath:extractPath defaultMenuItems:defaultMenuItems];
						if (newMenuItems2) {
							[menuItems addObject:[NSMenuItem separatorItem]];
							[menuItems addObjectsFromArray:newMenuItems2];
							return menuItems;
						}				
					}
				}
				
				return newMenuItems;
			}
		}
	} else {
		if (resNumber != NSNotFound && resNumber > 0) {
			
			NSString *extractPath = [NSString stringWithFormat:@"resNumber/%d",resNumber];
			[threadView setSelectedResExtractPath:extractPath];
			if (delegate && [delegate respondsToSelector:@selector(threadView:contextMenuItemsForResPath:defaultMenuItems:)]) {
				NSArray *newMenuItems = [delegate threadView:threadView contextMenuItemsForResPath:extractPath defaultMenuItems:defaultMenuItems];
				if (newMenuItems) {
					return newMenuItems;
				}				
			}
		}
	}
	
	if (delegate && [delegate respondsToSelector:@selector(threadView:contextMenuItemsForOtherElement:defaultMenuItems:)]) {
		NSArray *newMenuItems = [delegate threadView:threadView contextMenuItemsForOtherElement:element defaultMenuItems:defaultMenuItems];
		if ([menuItems count]>0) [menuItems addObject:[NSMenuItem separatorItem]];
		[menuItems addObjectsFromArray:newMenuItems];
		return menuItems;
	}
	return defaultMenuItems;
}



#pragma mark -
#pragma mark DOMEvent
- (void)handleEvent:(DOMEvent *)event {
	if (__Safari2Debug) return;
	__DOMEventEnabled = YES;
	DOMNode *target = [event target];
	NSString *type = [event type];
	
	if ([type isEqualToString:@"mouseover"]) {
		DOMHTMLAnchorElement *parentAnchorElement = [target parentAnchorElement];
		if (parentAnchorElement) {
			if ([self mouseoverAnchorElement:parentAnchorElement modifierFlags:[(DOMMouseEvent *)event modifierFlags]])
				[event preventDefault];
		} else {
			[self registerHoveredAnchorElement:nil modifierFlags:0];
		}
	} else if ([type isEqualToString:@"scroll"]) {
		if ([[_threadView resExtractPath] isEqualToString:@"automatic"]) {
			DOMHTMLDocument *domDocument = (DOMHTMLDocument *)target;
			float docHeight = [(NSNumber *)[domDocument valueForKey:@"height"] floatValue];
			//float windowHeight = [_threadView frame].size.height;
			float docTop = [[_threadView stringByEvaluatingJavaScriptFromString:@"window.scrollY;"] floatValue];
			if (docTop > docHeight * 0.66) { //
				[_threadView extendBottom];
			} else if (docTop < docHeight * 0.33) {
				[_threadView extendTop];
			}
		}
		
	} else if ([type isEqualToString:@"click"]) {
		if ([target isKindOfClass:[DOMHTMLElement class]]) {
			DOMHTMLAnchorElement *anchorElement = [(DOMHTMLElement *)target parentAnchorElement];
			if (anchorElement) {
				if ([self clickAnchorElement:anchorElement modifierFlags:[(DOMMouseEvent *)event modifierFlags]])
					[event preventDefault];
			}
		}
	}
}
-(BOOL)mouseoverAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags {
	if (!(modifierFlags & NSCommandKeyMask)) {
		NSString *urlString = [anchorElement urlStringForPreviewInPopUp];
		if (urlString) {
			[self registerHoveredAnchorElement:anchorElement modifierFlags:modifierFlags];
			return YES;
		}
	}
	[self registerHoveredAnchorElement:nil modifierFlags:0];
	return NO;
}

-(BOOL)clickAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags {
	
	NSObject *delegate = [_threadView delegate];
	NSString *urlString = [anchorElement href];
	NSURL *url = [NSURL URLWithString:urlString];
	//NSString *frameUrlString = [[_threadView baseURL] absoluteString];
	
	if ([url isFileURL]) {
		NSURL *baseURL = [_threadView baseURL];
		if ([baseURL isFileURL]) {
			NSString *absoluteString = [url filePath];
			NSString *prefixString = [baseURL filePath];
			if (prefixString) {
				if ([absoluteString hasPrefix:prefixString]) {
					return NO;
				}
			}
		}
	} else if ([urlString hasPrefix:@"applewebdata://"] ||
		[urlString hasPrefix:@"javascript:"]) {
		return NO;
	}
	
	if (delegate && [delegate respondsToSelector:@selector(threadView:shouldHandleClickAnchorElement:modifierFlags:)]) {
		if (![delegate threadView:_threadView shouldHandleClickAnchorElement:anchorElement modifierFlags:_modifierFlags]) {
			return YES;
		}
	}
	
	if ([anchorElement allowsPreviewResInline] && ![_threadView isPopup] &&
		!(modifierFlags & (NSCommandKeyMask | NSAlternateKeyMask | NSShiftKeyMask))  ) {
		if ([urlString hasPrefix:@"internal://"]) {
			if ([_threadView replaceResAnchorElement:anchorElement WithResExtractPath:urlString]) {
				return YES;
			}
		} else if ([[T2PluginManager sharedManager] isPreviewableURLString:urlString type:T2PreviewInline]) {
			if ([_threadView replacePreviewableAnchorElement:anchorElement]) {
				return YES;
			}
		}
	}
	
	if ([urlString hasPrefix:@"internal://"]) {
		if (delegate && [delegate respondsToSelector:@selector(threadView:clickedResPath:)]) {
			NSString *resExtractPath = [urlString stringByDeletingfirstPathComponent];
			[delegate threadView:_threadView clickedResPath:resExtractPath];
		}
		return YES;
	}
	
	NSString *internalPath = [[T2PluginManager sharedManager] threadInternalPathForProposedURLString:urlString];
	if (internalPath) {
		if (delegate && [delegate respondsToSelector:@selector(threadView:clickedThreadPath:)]) {
			[delegate threadView:_threadView clickedThreadPath:internalPath];
		}
		return YES;
	} else {
		if (delegate && [delegate respondsToSelector:@selector(threadView:clickedOtherURL:)]) {
			[delegate threadView:_threadView clickedOtherURL:urlString];
			return YES;
		}
	}
	return YES;
}
@end

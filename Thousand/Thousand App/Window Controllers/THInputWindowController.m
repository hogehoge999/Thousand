#import "THInputWindowController.h"

static NSMutableSet *__instances = nil;

@implementation THInputWindowController

+(id)beginSearchInputSheetForWindow:(NSWindow *)docWindow defaultString:(NSString *)defaultString delegate:(id)delegate selector:(SEL)selector {
	
	THInputWindowController *winController = [[[self alloc] initInputSheetUsingNibName:@"THSearchInputWindow"
																				window:docWindow
																		 defaultString:defaultString
																			  delegate:delegate
																			  selector:selector]
											  autorelease];
	[winController beginSheet];
	return winController;
	
}
+(id)beginURLOpenSheetForWindow:(NSWindow *)docWindow defaultString:(NSString *)defaultString delegate:(id)delegate selector:(SEL)selector {
	THInputWindowController *winController = [[[self alloc] initInputSheetUsingNibName:@"THURLOpenWindow"
																				window:docWindow
																		 defaultString:defaultString
																			  delegate:delegate
																			  selector:selector]
											  autorelease];
	[winController beginSheet];
	return winController;
}

-(id)initInputSheetUsingNibName:(NSString *)nibName window:(NSWindow *)docWindow defaultString:(NSString *)defaultString
					   delegate:(id)delegate selector:(SEL)selector {
	self = [self initWithWindowNibName:nibName];
	_docWindow = docWindow;
	_delegate = delegate;
	_selector = selector;
	_string = [defaultString copy];
	
	return self;
}


-(void)beginSheet {
	[NSApp beginSheet:[self window]
	   modalForWindow:_docWindow
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
	if (!__instances) __instances = [[NSMutableSet alloc] init];
	[__instances addObject:self];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
	if ([_delegate respondsToSelector:_selector]) {
		[_delegate performSelector:_selector withObject:_string];
	}
	[__instances removeObject:self];
}

- (void)windowDidLoad {
	if (_string) {
		[_textField setStringValue:_string];
	}
}

- (IBAction)close:(id)sender {
	_string = nil;
	[NSApp endSheet:[self window]];
}

- (IBAction)open:(id)sender {
	_string = [[_textField stringValue] retain];
	[NSApp endSheet:[self window]];
}

-(void)dealloc {
	[_string release];
	[super dealloc];
}

@end

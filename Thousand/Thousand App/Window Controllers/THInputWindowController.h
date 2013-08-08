/* THURLOpenWindowController */

#import <Cocoa/Cocoa.h>

@interface THInputWindowController : NSWindowController
{
	NSWindow *_docWindow;
	id _delegate;
	SEL _selector;
	NSString *_string;
    IBOutlet NSTextField *_textField;
}

+(id)beginSearchInputSheetForWindow:(NSWindow *)docWindow defaultString:(NSString *)defaultString delegate:(id)delegate selector:(SEL)selector ;
+(id)beginURLOpenSheetForWindow:(NSWindow *)docWindow defaultString:(NSString *)defaultString delegate:(id)delegate selector:(SEL)selector ;
-(id)initInputSheetUsingNibName:(NSString *)nibName window:(NSWindow *)docWindow defaultString:(NSString *)defaultString delegate:(id)delegate selector:(SEL)selector ;
-(void)beginSheet ;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo ;

- (IBAction)close:(id)sender;
- (IBAction)open:(id)sender;
@end

//
//  THWebKitAdditions.h
//  Thousand
//
//  Created by R. Natori on 06/07/31.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

extern NSString *T2HTMLClassNameNoPreview; //@"noPreview"
extern NSString *T2HTMLClassNameNoPopUp; //@"noPopUp"
extern NSString *T2HTMLClassNameNoInline; //@"noInline"
extern NSString *T2HTMLClassNameDanger; //@"danger"

@interface WebView (T2WebKitAdditions)
-(void)setThousandDefaultAttributes ;
-(void)setThousandPostingWebViewDefaultAttributes ;
-(void)setAllDelegate:(id)delegate ;
@end

@interface DOMNode (T2DOMNodeAdditions)
-(unsigned)parentResNumber ;
-(DOMHTMLDivElement *)parentResDivElement;
-(DOMHTMLAnchorElement *)parentAnchorElement;
-(void)logAllParentNodes ;
@end

@interface DOMRange (T2DOMRangeAdditions)
-(NSString *)toStringContainsLineBreaks ;
@end

@interface DOMHTMLElement (T2DOMHTMLElementAdditions)
-(void)setClassNames:(NSArray *)classNames ;
-(NSArray *)classNames ;
-(void)addClassName:(NSString *)className ;
-(void)removeClassName:(NSString *)className ;
-(BOOL)hasClassName:(NSString *)className ;

-(NSString *)parentTagName ;
-(void)replaceWithHTML:(NSString *)html ;
-(void)removeNextWhiteAndBRElement ;
@end

@interface DOMHTMLAnchorElement (T2DOMHTMLAnchorElementAdditions)
-(BOOL)allowsPreviewWebContentInPopUp ;
-(BOOL)allowsPreviewWebContentInline ;
-(BOOL)allowsPreviewResInPopUp ;
-(BOOL)allowsPreviewResInline ;

-(NSString *)urlStringForPreviewInPopUp ;
-(NSString *)urlStringForPreviewInline ;
@end

@interface DOMMouseEvent (T2DOMMouseEventAdditions)
-(unsigned)modifierFlags ;
@end

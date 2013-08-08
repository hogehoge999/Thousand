//
//  THWebKitAdditions.m
//  Thousand
//
//  Created by R. Natori on 06/07/31.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2WebKitAdditions.h"
#import "T2NSStringAdditions.h"
#import "T2PluginManager.h"

static NSArray *__tagsNeedClosingOutside = nil;

NSString *T2HTMLClassNameNoPreview = @"noPreview";
NSString *T2HTMLClassNameNoPopUp = @"noPopUp";
NSString *T2HTMLClassNameNoInline = @"noInline";
NSString *T2HTMLClassNameDanger = @"danger";

@implementation WebView (T2WebKitAdditions)

-(void)setThousandDefaultAttributes {
	[self setPreferencesIdentifier:@"ThousandWebPreferences"];
	[self setMaintainsBackForwardList:NO];
	//[self setApplicationNameForUserAgent:@"Thousand"];
	[self setCustomUserAgent:@"Monazilla/1.00 (Thousand 1.0)"];
}
-(void)setThousandPostingWebViewDefaultAttributes {
	[self setPreferencesIdentifier:@"ThousandPostingWebPreferences"];
	[self setMaintainsBackForwardList:NO];
	//[self setApplicationNameForUserAgent:@"Thousand"];
	[self setCustomUserAgent:@"Monazilla/1.00 (Thousand 1.0)"];
}
-(void)setAllDelegate:(id)delegate  {
	[self setFrameLoadDelegate:delegate];
	[self setResourceLoadDelegate:delegate];
	[self setPolicyDelegate:delegate];
	[self setUIDelegate:delegate];
}
@end

@implementation DOMNode (T2DOMNodeAdditions)
-(unsigned)parentResNumber {
	DOMNode *node = self;
	while (node != nil) {
		if (node && [node isKindOfClass:[DOMHTMLDivElement class]]) {
			NSString *idName = [(DOMHTMLDivElement *)node idName];
			if ([idName hasPrefix:@"res"] && [idName length]>3) {
				NSString *subString = [idName substringFromIndex:3];
				return [subString intValue];
			}
		}
		node = [node parentNode];
	}
	return NSNotFound;
}



-(DOMHTMLDivElement *)parentResDivElement {
	DOMNode *node = self;
	while (node != nil) {
		if ([node isKindOfClass:[DOMHTMLDivElement class]]) {
			NSString *idName = [(DOMHTMLDivElement *)node idName];
			if ([idName hasPrefix:@"res"] && [idName length]>3) {
				return (DOMHTMLDivElement *)node;
			}
		}
		node = [node parentNode];
	}
	return nil;
}

-(DOMHTMLAnchorElement *)parentAnchorElement {
	DOMNode *node = self;
	while (node != nil) {
		if ([node isKindOfClass:[DOMHTMLAnchorElement class]]) {
			return (DOMHTMLAnchorElement *)node;
		}
		node = [node parentNode];
	}
	return nil;
}

-(void)logAllParentNodes {
	DOMNode *node = self;
	while (node != nil) {
		NSLog(@"%@", [node description]);
		node = [node parentNode];
	}
}
@end

@implementation DOMRange (T2DOMRangeAdditions)
-(NSString *)toStringContainsLineBreaks {
	NSString *string = [self markupString];
	if (string) {
		string = [[string stringFromHTML] stringByTrimmingInvalidWhiteCharactersBeforeLineBreaks];
	}
	return string;
}
@end

@implementation DOMHTMLElement (T2DOMHTMLElementAdditions)
-(void)setClassNames:(NSArray *)classNames {
	if (classNames && [classNames count] > 0) {
		[self setClassName:[classNames componentsJoinedByString:@" "]];
	} else {
		[self setClassName:@""];
	}
}
-(NSArray *)classNames {
	return [[self className] componentsSeparatedByString:@" "];
}
-(void)addClassName:(NSString *)className {
	if (!className) return;
	NSString *oldClassName = [self className];
	if (oldClassName) {
		if ([oldClassName rangeOfString:className].location == NSNotFound) {
			[self setClassName:[NSString stringWithFormat:@"%@ %@", oldClassName, className]];
		}
		return;
	}
	[self setClassName:className];
}
-(void)removeClassName:(NSString *)className {
	NSMutableArray *classNames = [[[self classNames] mutableCopy] autorelease];
	if (!classNames) return;
	[classNames removeObject:className];
	if ([classNames count] > 0) {
		[self setClassNames:classNames];
	} else {
		[self removeAttribute:@"class"];
	}
}
-(BOOL)hasClassName:(NSString *)className {
	if (!className) return NO;
	NSString *oldClassName = [self className];
	if (oldClassName) {
		if ([oldClassName rangeOfString:className].location != NSNotFound) {
			return YES;
		}
	}
	return NO;
}


-(NSString *)parentTagName {
	DOMNode *parentNode = [self parentNode];
	if ([parentNode isKindOfClass:[DOMElement class]])
		return [(DOMElement *)parentNode tagName];
	return nil;
}
-(void)replaceWithHTML:(NSString *)html {
	if (!__tagsNeedClosingOutside) {
		__tagsNeedClosingOutside = [[NSArray arrayWithObjects:
			@"<div", @"<p", @"<h", @"<ul", @"<ol", @"<dl",
			@"<blockquote", @"<table", @"<form", @"<iframe",
			nil] retain];
	}
	NSEnumerator *tagEnumerator = [__tagsNeedClosingOutside objectEnumerator];
	NSString *tag = [tagEnumerator nextObject];
	BOOL found = NO;
	while (tag = [tagEnumerator nextObject]) {
		if ([html rangeOfString:tag].location != NSNotFound) {
			found = YES;
			break;
		}
	}
	if (!found) {
		[self setOuterHTML:html];
		return;
	}
	
	NSString *resultHTML = nil;
	NSMutableString *tagCloser = [NSMutableString string];
	NSMutableString *tagOpener = [NSMutableString string];
	
	DOMHTMLElement *ancestor = nil;
	DOMNode *node = self;
	while (node = [node parentNode]) {
		if ([node isKindOfClass:[DOMHTMLDivElement class]] ||
			[node isKindOfClass:[DOMHTMLBodyElement class]]) {
			ancestor = (DOMHTMLElement *)node;
			break;
		}
		
		NSString *tagName = [(DOMElement *)node tagName];
		if (tagName) {
			[tagCloser appendString:[NSString stringWithFormat:@"</%@>", tagName]];
			[tagOpener appendString:[NSString stringWithFormat:@"<%@>", tagName]];
		}
	}
	
	if (ancestor) {
		NSString *target = [ancestor innerHTML];
		
		resultHTML = [tagCloser stringByAppendingString:html];
		resultHTML = [resultHTML stringByAppendingString:tagOpener];
		NSString *innerHTML = [target stringByReplacingFirstOccurrencesOfString:[self outerHTML]
																	 withString:resultHTML
																		options:NSLiteralSearch];
		[ancestor setInnerHTML:innerHTML];
		return;
	}
	[self setOuterHTML:html];
}
-(void)removeNextWhiteAndBRElement {
	DOMNode *nextSibling1 = [self nextSibling];
	DOMNode *nextSibling2 = [nextSibling1 nextSibling];
	
	if ([nextSibling1 isKindOfClass:[DOMHTMLBRElement class]]) {
		[[nextSibling1 parentNode] removeChild:nextSibling1];
	} else if ([nextSibling2 isKindOfClass:[DOMHTMLBRElement class]]) {
		if ([nextSibling1 isKindOfClass:[DOMText class]]) {
			NSString *string = [(DOMText *)nextSibling1 data];
			NSString *trimedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if (!trimedString || [trimedString length] == 0) {
				[[nextSibling1 parentNode] removeChild:nextSibling1];
				[[nextSibling2 parentNode] removeChild:nextSibling2];
			}
		}
	}
}
@end

@implementation DOMHTMLAnchorElement (T2DOMHTMLAnchorElementAdditions)

-(BOOL)allowsPreviewWebContentInPopUp {
	if ([self hasClassName:T2HTMLClassNameNoPreview] || [self hasClassName:T2HTMLClassNameNoPopUp])
		return NO;
	DOMHTMLDivElement *parentResDivElement = [self parentResDivElement];
	if (!parentResDivElement)
		return NO;
	if ([parentResDivElement hasClassName:T2HTMLClassNameDanger])
		return NO;
	return YES;
}
-(BOOL)allowsPreviewWebContentInline {
	if ([self hasClassName:T2HTMLClassNameNoPreview] || [self hasClassName:T2HTMLClassNameNoInline])
		return NO;
	DOMHTMLDivElement *parentResDivElement = [self parentResDivElement];
	if (!parentResDivElement)
		return NO;
	return YES;
}

-(BOOL)allowsPreviewResInPopUp {
	if ([self hasClassName:T2HTMLClassNameNoPreview] || [self hasClassName:T2HTMLClassNameNoPopUp])
		return NO;
	DOMHTMLDivElement *parentResDivElement = [self parentResDivElement];
	if (!parentResDivElement)
		return NO;
	return YES;
}
-(BOOL)allowsPreviewResInline {
	if ([self hasClassName:T2HTMLClassNameNoPreview] || [self hasClassName:T2HTMLClassNameNoInline])
		return NO;
	DOMHTMLDivElement *parentResDivElement = [self parentResDivElement];
	if (!parentResDivElement)
		return NO;
	return YES;
}

-(NSString *)urlStringForPreviewInPopUp {
	NSString *urlString = [self href];
	if ([urlString hasPrefix:@"internal://"]) {
		if ([self allowsPreviewResInPopUp]) {
			return urlString;
		}
	} else if ([[T2PluginManager sharedManager] isPreviewableURLString:urlString type:T2PreviewInPopUp]) {
		if ([self allowsPreviewWebContentInPopUp]) {
			return urlString;
		}
	}
	return nil;
}
-(NSString *)urlStringForPreviewInline {
	NSString *urlString = [self href];
	if ([urlString hasPrefix:@"internal://"]) {
		if ([self allowsPreviewResInline]) {
			return urlString;
		}
	} else if ([[T2PluginManager sharedManager] isPreviewableURLString:urlString type:T2PreviewInline]) {
		if ([self allowsPreviewWebContentInline]) {
			return urlString;
		}
	}
	return nil;
}
@end

@implementation DOMMouseEvent (T2DOMMouseEventAdditions)
-(unsigned)modifierFlags {
	unsigned modifierFlags = 0;
	if ([self shiftKey])
		modifierFlags |= NSShiftKeyMask;
	if ([self ctrlKey])
		modifierFlags |= NSControlKeyMask;
	if ([self altKey])
		modifierFlags |= NSAlternateKeyMask;
	if ([self metaKey])
		modifierFlags |= NSCommandKeyMask;
	return modifierFlags;
}
@end
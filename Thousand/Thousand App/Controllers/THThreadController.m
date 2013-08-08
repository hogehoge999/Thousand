//
//  THThreadController.m
//  Thousand
//
//  Created by R. Natori on 05/08/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "THThreadController.h"
#import "THBookmarkController.h"
#import "T2PluginManager.h"
#import "THDocument.h"
#import "THAppDelegate.h"
#import "THAddBookmarkWindowController.h"
#import "THPostingWindowController.h"
#import "T2PluginManager.h"
#import "THDownloadWindowController.h"
#import "THChooseNextThreadWindowController.h"

static NSString *__defaultResExtractPath = @"newPlus/100";
static unsigned	__newTabModifierMask = NSCommandKeyMask;
static THPreviewActionType __classPopUpResAnchorElementActionType = THPreviewInPopUp;
static THPreviewActionType __classPopUpOtherAnchorElementActionType = THPreviewInPopUp;

static THPreviewActionType __classClickResAnchorElementActionFirst = THPreviewInline;
static THPreviewActionType __classClickResAnchorElementActionSecond = THPreviewMove;
static THPreviewActionType __classClickResAnchorElementActionThird = THPreviewInNewTab;
static THPreviewActionType __classClickResAnchorElementActionFourth = THPreviewInPopUp;

static THPreviewActionType __classClickOtherAnchorElementActionFirst = THPreviewInline;
static THPreviewActionType __classClickOtherAnchorElementActionSecond = THPreviewDownload;
static THPreviewActionType __classClickOtherAnchorElementActionThird = THPreviewWebBrowser;
static THPreviewActionType __classClickOtherAnchorElementActionFourth = THPreviewInPopUp;

@implementation THThreadController

+(void)setClassPopUpResAnchorElementActionType:(THPreviewActionType)actionType { __classPopUpResAnchorElementActionType = actionType; }
+(THPreviewActionType)classPopUpResAnchorElementActionType { return __classPopUpResAnchorElementActionType; }
+(void)setClassPopUpOtherAnchorElementActionType:(THPreviewActionType)actionType { __classPopUpOtherAnchorElementActionType = actionType; }
+(THPreviewActionType)classPopUpOtherAnchorElementActionType { return __classPopUpOtherAnchorElementActionType; }

+(void)setClassClickResAnchorElementActionType:(THPreviewActionType)actionType { 
	__classClickResAnchorElementActionFirst = actionType;
	switch (__classClickResAnchorElementActionFirst) {
		case THPreviewInline: {
			__classClickResAnchorElementActionSecond = THPreviewMove;
			__classClickResAnchorElementActionThird = THPreviewInNewTab;
			__classClickResAnchorElementActionFourth = THPreviewInPopUp;
			break;
		}
		case THPreviewInPopUp: {
			__classClickResAnchorElementActionSecond = THPreviewMove;
			__classClickResAnchorElementActionThird = THPreviewInNewTab;
			__classClickResAnchorElementActionFourth = THPreviewInline;
			break;
		}
		case THPreviewInNewTab: {
			__classClickResAnchorElementActionSecond = THPreviewMove;
			__classClickResAnchorElementActionThird = THPreviewInline;
			__classClickResAnchorElementActionFourth = THPreviewInPopUp;
			break;
		}
		case THPreviewMove: {
			__classClickResAnchorElementActionSecond = THPreviewInline;
			__classClickResAnchorElementActionThird = THPreviewInNewTab;
			__classClickResAnchorElementActionFourth = THPreviewInPopUp;
			break;
		}
		case THPreviewNone: {
			__classClickResAnchorElementActionSecond = THPreviewInPopUp;
			__classClickResAnchorElementActionThird = THPreviewInline;
			__classClickResAnchorElementActionFourth = THPreviewMove;
			break;
		}
		default:
			break;
	}
}
+(THPreviewActionType)classResClickAnchorElementActionType { return __classClickResAnchorElementActionFirst; }

+(void)setClassClickOtherAnchorElementActionType:(THPreviewActionType)actionType {
	__classClickOtherAnchorElementActionFirst = actionType; 
	switch (__classClickResAnchorElementActionFirst) {
		case THPreviewInline: {
			__classClickOtherAnchorElementActionSecond = THPreviewDownload;
			__classClickOtherAnchorElementActionThird = THPreviewWebBrowser;
			__classClickOtherAnchorElementActionFourth = THPreviewInPopUp;
			break;
		}
		case THPreviewInPopUp: {
			__classClickOtherAnchorElementActionSecond = THPreviewDownload;
			__classClickOtherAnchorElementActionThird = THPreviewInline;
			__classClickOtherAnchorElementActionFourth = THPreviewWebBrowser;
			break;
		}
		case THPreviewWebBrowser: {
			__classClickOtherAnchorElementActionSecond = THPreviewDownload;
			__classClickOtherAnchorElementActionThird = THPreviewInline;
			__classClickOtherAnchorElementActionFourth = THPreviewInPopUp;
			break;
		}
		case THPreviewNone: {
			__classClickOtherAnchorElementActionSecond = THPreviewDownload;
			__classClickOtherAnchorElementActionThird = THPreviewInline;
			__classClickOtherAnchorElementActionFourth = THPreviewInPopUp;
			break;
		}
		default:
			break;
	}
}
+(THPreviewActionType)classOtherClickAnchorElementActionType { return __classClickOtherAnchorElementActionFirst; }

+(void)setClassDefaultResExtractPath:(NSString *)path {
	setObjectWithRetain(__defaultResExtractPath, path);
}
+(NSString *)classDefaultResExtractPath { return __defaultResExtractPath; }


+(id)threadControllerWithThreadView:(T2ThreadView *)threadView thread:(T2Thread *)thread document:(THDocument *)document {
	return [[[self alloc] initWithThreadView:threadView thread:thread document:document] autorelease];
}

-(id)initWithThreadView:(T2ThreadView *)threadView thread:(T2Thread *)thread document:(THDocument *)document {
	self = [super init];
	[self setThreadView:threadView];
	[self setThread:thread];
	_document = document;
	return self;
}

-(void)dealloc {
	NSString *resExtractPath = [_threadView resExtractPath];
	if ([resExtractPath isEqualToString:@"automatic"]) {
		[_threadView saveScrollToThread];
	}
	
	[_threadView setAllDelegate:nil];
	[_threadView setThread:nil];
	[_threadView release];
	
	[_webDataURLString release];
	[_pressedURLString release];
	[_pressedResExtractPath release];
	//[_popUpDictionary release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(void)setThread:(T2Thread *)thread {
	[self setContent:thread];
	
	[_threadView setThread:thread];
	[_threadView setResExtractPath:__defaultResExtractPath];
}
-(T2Thread *)thread { return [self content]; }

-(void)setThreadView:(T2ThreadView *)threadView {
	if (_threadView == threadView) return;
	[_threadView setDelegate:nil];
	[_threadView release];
	_threadView = [threadView retain];
	[_threadView setThousandDefaultAttributes];
	[_threadView setDelegate:self];
}
-(T2ThreadView *)threadView  { return _threadView; }

-(void)setPressedResExtractPath:(NSString *)resExtractPath {
	setObjectWithRetain(_pressedResExtractPath, resExtractPath);
}
-(NSString *)pressedResExtractPath { return _pressedResExtractPath; }

-(void)setDocument:(THDocument *)document {
	_document = document;
}
-(THDocument *)document { return _document; }

-(NSString *)filterSearchString {
	NSString *resExtractPath = [_threadView resExtractPath];
	if ([resExtractPath hasPrefix:@"internal"]) {
		resExtractPath = [resExtractPath stringByDeletingfirstPathComponent];
	}
	if ([[resExtractPath firstPathComponent] isEqualToString:@"word"]) {
		return [[resExtractPath lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	return nil;
}

/*
 -(void)setResIndexes:(NSIndexSet *)indexSet { setObjectWithRetain(_resIndexes,indexSet); }
 -(NSIndexSet *)resIndexes { return _resIndexes; }
 
 -(void)setResExtractPath:(NSString *)extractPath {
 setObjectWithRetain(_resExtractPath,extractPath);
 }
 -(NSString *)resExtractPath { return _resExtractPath; }
 
 -(void)setSelectedResIndexes:(NSIndexSet *)indexSet { setObjectWithRetain(_selectedResIndexes,indexSet); }
 -(NSIndexSet *)selectedResIndexes { return _selectedResIndexes; }
 
 -(void)setSelectedResExtractPath:(NSString *)extractPath {
 setObjectWithRetain(_selectedResExtractPath,extractPath);
 [self setSelectedResIndexes:[[_threadView thread] resIndexesWithExtractPath:_selectedResExtractPath]];
 }
 -(NSString *)selectedResExtractPath { return _selectedResExtractPath; }
 
 #pragma mark -
 #pragma mark Observing
 - (void)observeValueForKeyPath:(NSString *)keyPath
 ofObject:(id)object
 change:(NSDictionary *)change
 context:(void *)context {
 if ([keyPath isEqualToString:@"loadedResIndexes"]) {
 [self displayThread];
 } else if ([keyPath isEqualToString:@"styleUpdatedResIndexes"]) {
 [self thread:[_threadView thread] didUpdateStyleOfResIndexes:[[_threadView thread] styleUpdatedResIndexes]];
 }
 }
 
 
 -(void)displayThread {
 NSURL *baseURL = nil;
 [self setResIndexes:[[_threadView thread] resIndexesWithExtractPath:_resExtractPath]];
 //[self updateThreadMenu];
 NSString *resultHTML = [[_threadView thread] HTMLForResIndexes:_resIndexes
 baseURL:&baseURL
 forPopUp:NO];
 if (resultHTML) [[_threadView mainFrame] loadHTMLString:resultHTML baseURL:baseURL];
 }
 
 */

#pragma mark -
#pragma mark Internal Methods
-(void)updateLabelButton {
	[_document setLabel:[[[self thread] threadFace] label]];
}
-(void)updateThreadMenu {
	THAppDelegate *appDelegate = [THAppDelegate sharedInstance];
	NSString *localizedDescriptionOfExtractPath = [[T2PluginManager sharedManager] localizedDescriptionOfExtractPath:[_threadView resExtractPath]];
	//NSLog(@"%@", localizedDescriptionOfExtractPath);
	[appDelegate setThreadResStyleMenuTitle:
	 [NSString stringWithFormat:NSLocalizedString(@"Style of %@", @"app")
	  ,localizedDescriptionOfExtractPath]
									enabled:YES];
	[appDelegate setThreadResTraceMenuTitle:
	 [NSString stringWithFormat:NSLocalizedString(@"Responses To %@", @"app")
	  ,localizedDescriptionOfExtractPath]
									enabled:YES];
}

THPreviewActionType previewActionTypeWithPriorityAndModifierFlags(
																   THPreviewActionType first,
																   THPreviewActionType second,
																   THPreviewActionType third,
																   THPreviewActionType fourth,
																   unsigned modifierFlags) {
	switch (modifierFlags & (NSAlternateKeyMask | NSCommandKeyMask)) {
		case 0: {
			return first;
		}
		case NSAlternateKeyMask: {
			return second;
		}
		case NSCommandKeyMask: {
			return third;
		}
		default:
			break;
	}
	return fourth;
}



#pragma mark -

-(NSArray *)menusForThread {
	NSMenuItem *copyTitleAndURLMenuItem = [NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Copy Title and URL",@"app")
																		 action:@selector(copyTitleAndURL:) keyEquivalent:@""];
	[copyTitleAndURLMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[copyTitleAndURLMenuItem setAlternate:YES];
	return [NSArray arrayWithObjects:
			[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Thread",@"app")
								   action:NULL keyEquivalent:@""],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Add Bookmark",@"app")
										   action:@selector(addToBookmark:) keyEquivalent:@""],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Delete Thread...",@"app")
										   action:@selector(removeSelectedThreads:) keyEquivalent:@""],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Reload",@"app")
										   action:@selector(reloadView:) keyEquivalent:@""],
			
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Open Board",@"app")
										   action:@selector(openParentThreadList:) keyEquivalent:@""],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Find Next Thread...",@"app")
										   action:@selector(findNextThread:) keyEquivalent:@""],
			
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Open Using Web Browser",@"app")
										   action:@selector(openUsingWebBrowser:) keyEquivalent:@""],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Copy URL",@"app")
										   action:@selector(copyURL:) keyEquivalent:@""],
			copyTitleAndURLMenuItem,
			[NSMenuItem separatorItem],
			[self labelMenuItem],
			nil];
}
-(NSMenuItem *)labelMenuItem {
	NSMenuItem *labelMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Label",@"app")
															action:NULL keyEquivalent:@""] autorelease];
	NSMenu *labelMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Label",@"app")] autorelease];
	NSArray *labelMenuItems = [[T2LabeledCellManager sharedManager] menuItems];
	NSEnumerator *menuItemEnumerator = [labelMenuItems objectEnumerator];
	NSMenuItem *menuItem;
	while (menuItem = [menuItemEnumerator nextObject]) {
		[labelMenu addItem:menuItem];
	}
	[labelMenuItem setSubmenu:labelMenu];
	[labelMenuItem setIndentationLevel:1];
	return labelMenuItem;
}

-(NSArray *)restrictedStyleMenuItemsForTarget:(id)target action:(SEL)action {
	NSArray *topLevelStyles = [NSArray arrayWithObjects:
							   @"invisible",
							   @"aa",
							   @"danger",
							   nil];
	
	NSArray *styleMenuItems = [[T2ResourceManager sharedManager] styleMenuItemsForTarget:target action:action];
	NSEnumerator *styleMenuItemEnumerator = [styleMenuItems objectEnumerator];
	
	NSMutableArray *topLevelMenuItems = [NSMutableArray array];
	NSMenu *subMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Other Styles",@"app")] autorelease];
	
	NSMenuItem *styleMenuItem;
	while (styleMenuItem = [styleMenuItemEnumerator nextObject]) {
		NSString *style = [styleMenuItem representedObject];
		if ([topLevelStyles containsObject:style]) {
			[styleMenuItem setIndentationLevel:1];
			[topLevelMenuItems addObject:styleMenuItem];
		} else {
			[subMenu addItem:styleMenuItem];
		}
	}
	NSMenuItem *otherStyleMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Other Styles",@"app")
																 action:NULL
														  keyEquivalent:@""] autorelease];
	[otherStyleMenuItem setSubmenu:subMenu];
	[otherStyleMenuItem setIndentationLevel:1];
	[topLevelMenuItems addObject:otherStyleMenuItem];
	
	return topLevelMenuItems;
}


/*
 #pragma mark -
 #pragma mark T2Thread Delegate
 
 -(void)thread:(T2Thread *)thread didLoadResIndexes:(NSIndexSet *)indexSet
 location:(unsigned)location {
 
 [self displayThread];
 }
 -(void)thread:(T2Thread *)thread didUpdateStyleOfResIndexes:(NSIndexSet *)resIndexes {
 NSArray *resArray = [[_threadView thread] originalResArray];
 DOMDocument *document = [[_threadView mainFrame] DOMDocument];
 if (resIndexes && document) {
 [_threadView setSelectedDOMRange:nil affinity:0];
 unsigned resIndex = [resIndexes firstIndex];
 while (resIndex != NSNotFound) {
 NSString *elementID = [NSString stringWithFormat:@"res%d",resIndex+1];
 DOMElement *element = [document getElementById:elementID];
 if (element) {
 T2Res *res = [resArray objectAtIndex:resIndex];
 //NSString *newClass = [NSString stringWithFormat:@"%@ %@", class, style];
 [element setAttribute:@"class" :[res HTMLClassesString]];
 }
 resIndex = [resIndexes indexGreaterThanIndex:resIndex];
 }
 [_threadView setNeedsDisplay:YES];
 }
 }
 */

#pragma mark -
#pragma mark T2ThreadView Delegate (Load)

-(void)threadView:(T2ThreadView *)sender didFinishLoadingThread:(T2Thread *)thread {
	
	if (sender != _threadView) return;
	if (![[_threadView resExtractPath] isEqualToString:@"automatic"]) {
	if ([[_threadView thread] newResIndex])
		[self moveToNewRes:nil];
	}
	
	T2ThreadFace *newThreadFace = [thread threadFace];
	[[thread threadFace] setValue:[NSDate date] forKey:@"lastLoadingDate"];
	
	[_document displayTabTitleOfThreadController:self];
	
	T2ThreadFace *oldThreadFace = [_document tempThreadFace];
	if (oldThreadFace) {
		NSString *oldTitle = [oldThreadFace title];
		NSString *newTitle = [newThreadFace title];
		NSDate *oldDate = [oldThreadFace createdDate];
		NSDate *newDate = [newThreadFace createdDate];
		if ([newDate timeIntervalSinceDate:oldDate] > 0) {
			if ([newTitle distanceFromString:oldTitle] < ([newTitle length]/2)) {
				if ([oldThreadFace label] != 0
					|| [[T2SourceList sharedSourceList] hasBookmarkedThreadFace:oldThreadFace]) {
					[THChooseNextThreadWindowController beginSheetModalForWindow:[_threadView window]
															   withOldThreadFace:oldThreadFace
																   newThreadFace:newThreadFace
																		delegate:nil
																  didEndSelector:NULL];
				}
			}
		}
		[_document setTempThreadFace:nil];
	}
	//[[_threadView window] makeFirstResponder:_threadView];
	/*
	unsigned resCount = [thread resCount];
	DOMHTMLElement *resElement = [_threadView resElementForNumber:resCount];
	if (!resElement) {
		unsigned i;
		for (i=resCount-1; i>0; i--) {
			DOMHTMLElement *lastElement = [_threadView resElementForNumber:i];
		}
		NSLog(@"Failed to display thread:%@, %d/%d", [thread title], i, resCount);
	}
	 */
	
}
-(void)threadView:(T2ThreadView *)sender didDisplayThread:(T2Thread *)thread {
	[[_threadView window] makeFirstResponder:_threadView];
	[self updateThreadMenu];
}
#pragma mark -
#pragma mark T2ThreadView Delegate (PopUp and Preview)
-(BOOL)threadView:(T2ThreadView *)sender shouldHandlePopUpAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags {
	THPreviewActionType actionType;
	NSString *href = [anchorElement href];
	if ([href hasPrefix:@"internal://"]) {
		actionType = __classPopUpResAnchorElementActionType;
	} else {
		actionType = __classPopUpOtherAnchorElementActionType;
	}
	
	if (actionType == THPreviewNone || (modifierFlags & (NSAlternateKeyMask | NSCommandKeyMask))) {
		return NO;
	}
	return YES;
}

-(BOOL)threadView:(T2ThreadView *)sender shouldHandleClickAnchorElement:(DOMHTMLAnchorElement *)anchorElement modifierFlags:(unsigned)modifierFlags {
	NSString *href = [anchorElement href];
	if ([href hasPrefix:@"internal://"]) {
		switch (previewActionTypeWithPriorityAndModifierFlags(__classClickResAnchorElementActionFirst,
															  __classClickResAnchorElementActionSecond,
															  __classClickResAnchorElementActionThird,
															  __classClickResAnchorElementActionFourth,
															  modifierFlags
		)) {
			case THPreviewNone: {
				return NO;
			}
			case THPreviewInPopUp: {
				if ([anchorElement allowsPreviewResInPopUp]) {
					[sender previewAnchorElement:anchorElement withType:T2PreviewInPopUp];
					return NO;
				}
				break;
			}
			case THPreviewInline: {
				if ([anchorElement allowsPreviewResInline]) {
					if (![sender isPopup])
						[sender previewAnchorElement:anchorElement withType:T2PreviewInline];
					else
						[_threadView moveToResExtractPath:href];
					return NO;
				}
				break;
			}
			case THPreviewMove: {
				if ([anchorElement allowsPreviewResInline]) {
					[_threadView moveToResExtractPath:href];
					return NO;
				}
				break;
			}
			case THPreviewInNewTab: {
				if ([anchorElement allowsPreviewResInline]) {
					[_document loadThread:[_threadView thread] resExtractedPath:href];
					return NO;
				}
				break;
			}
		}
		return YES;
		
	} else {
		if ([[T2PluginManager sharedManager] isPreviewableURLString:href type:T2PreviewInline]) {
			switch (previewActionTypeWithPriorityAndModifierFlags(__classClickOtherAnchorElementActionFirst,
																  __classClickOtherAnchorElementActionSecond,
																  __classClickOtherAnchorElementActionThird,
																  __classClickOtherAnchorElementActionFourth,
																  modifierFlags
																  )) {
				case THPreviewNone: {
					return NO;
				}
				case THPreviewInPopUp: {
					if ([anchorElement allowsPreviewWebContentInPopUp]) {
						[sender previewAnchorElement:anchorElement withType:T2PreviewInPopUp];
						return NO;
					}
					break;
				}
				case THPreviewInline: {
					if ([anchorElement allowsPreviewWebContentInline]) {
						if (![sender isPopup])
							[sender previewAnchorElement:anchorElement withType:T2PreviewInline];
						else
							[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:href]];
						return NO;
					}
					break;
				}
				case THPreviewWebBrowser: {
					[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:href]];
					return NO;
				}
				case THPreviewDownload: {
					[[THDownloadWindowController downloadWindowController] addDownloadOfURLString:href
																						 inThread:[_threadView thread]];
					return NO;
				}
			}
		} else {
			NSString *internalPath = [[T2PluginManager sharedManager] threadInternalPathForProposedURLString:href];
			if (internalPath) {
				// Thread
				[_document setTempThreadFace:[[_threadView thread] threadFace]];
				if (modifierFlags & NSAlternateKeyMask) {
					[_document loadThreadForThreadFace:[T2ThreadFace threadFaceWithInternalPath:internalPath]
										   activateTab:NO];
				} else {
					[_document loadThreadForURLString:href];
				}
			} else {
				internalPath = [[T2PluginManager sharedManager] listInternalPathForProposedURLString:href];
				if (internalPath) {
					// Board
					T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:internalPath
																		  title:nil image:nil];
					if (listFace) {
						[_document openListWithListFace:listFace];
					}
				} else {
					// Other URL
					if (modifierFlags & NSAlternateKeyMask) {
						[[THDownloadWindowController downloadWindowController] addDownloadOfURLString:href
																							 inThread:[_threadView thread]];
					} else {
						[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:href]];
					}
				}
			}
			return NO;
			
		}
		return YES;
	}
}


#pragma mark -
#pragma mark T2ThreadView Delegate (Click)
-(void)threadView:(T2ThreadView *)sender clickedThreadPath:(NSString *)internalPath {
	//[_document selectTabForThread:[_threadView thread]];
	[_document loadThreadForThreadFace:[T2ThreadFace threadFaceWithInternalPath:internalPath]
						   activateTab:YES];
}
-(void)threadView:(T2ThreadView *)sender clickedResPath:(NSString *)extractPath {
	if (!([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask)) {
		if ([extractPath hasPrefix:@"resNumber"]) {
			[_threadView moveToResExtractPath:extractPath];
		} else {
			[_threadView setResExtractPath:extractPath];
		}
	} else {
		[_document loadThread:[_threadView thread] resExtractedPath:extractPath];
	}
}
-(void)threadView:(T2ThreadView *)sender clickedOtherURL:(NSString *)URLString {
	if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
		[[THDownloadWindowController downloadWindowController] addDownloadOfURLString:URLString
																			 inThread:[_threadView thread]];
		return;
	}
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URLString]];
}

#pragma mark T2ThreadView Delegate (Menu)
-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForResPath:(NSString *)extractPath defaultMenuItems:(NSArray *)defaultMenuItems {
	[self setPressedResExtractPath:[sender selectedResExtractPath]];
	
	NSMutableArray *menuItems = [NSMutableArray array];
	NSString *localizedDescriptionOfExtractPath = [[T2PluginManager sharedManager] localizedDescriptionOfExtractPath:extractPath];
	[menuItems addObject:[NSMenuItem menuItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Reply to %@...",@"app"), localizedDescriptionOfExtractPath]
												action:@selector(reply:)
												target:self]];
	
	NSMenuItem *moveToResItem = [NSMenuItem menuItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Move to %@",@"app"), localizedDescriptionOfExtractPath]
													   action:@selector(moveToRes:)
													   target:self];
	NSMenuItem *openResInNewTabItem = [NSMenuItem menuItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Open %@ in New Tab",@"app"), localizedDescriptionOfExtractPath]
													   action:@selector(openResInNewTab:)
													   target:self];
	if (_pressedResExtractPath && [_pressedResExtractPath hasPrefix:@"resNumber"]) {
		[openResInNewTabItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		[openResInNewTabItem setAlternate:YES];
		[menuItems addObject:moveToResItem];
		[menuItems addObject:openResInNewTabItem];
	} else {
		[moveToResItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		[moveToResItem setAlternate:YES];
		[menuItems addObject:openResInNewTabItem];
		[menuItems addObject:moveToResItem];
	}
	
	[menuItems addObject:[NSMenuItem separatorItem]];
	
	if (![sender isPopup]) {
		[menuItems addObjectsFromArray:[self menusForThread]];
		[menuItems addObject:[NSMenuItem separatorItem]];
	}
	
	
	[menuItems addObject:[NSMenuItem menuItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Style of %@",@"app"), localizedDescriptionOfExtractPath]
												action:NULL
										 keyEquivalent:@""]];
	[menuItems addObjectsFromArray:[self restrictedStyleMenuItemsForTarget:sender
																	action:@selector(setSelectedResStyleAction:)]];
	[menuItems addObject:[NSMenuItem separatorItem]];
	
	NSMenuItem *menuItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Remove Styles",@"app")
												  action:@selector(removeSelectedResStyleAction:)
												  target:sender];
	[menuItem setIndentationLevel:1];
	[menuItems addObject:menuItem];
	
	[menuItems addObject:[NSMenuItem separatorItem]];
	[menuItems addObject:[NSMenuItem menuItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Preview URLs in %@",@"app"), localizedDescriptionOfExtractPath]
												action:@selector(previewInlineInRes:)
												target:self]];
	NSMenuItem *downloadLinkInResMenuItem = [NSMenuItem menuItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Download URLs in %@",@"app"), localizedDescriptionOfExtractPath]
																   action:@selector(downloadLinkInRes:)
																   target:self];
	[downloadLinkInResMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[downloadLinkInResMenuItem setAlternate:YES];
	[menuItems addObject:downloadLinkInResMenuItem];
	
	return menuItems;
}
-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForSelectedString:(NSString *)string defaultMenuItems:(NSArray *)defaultMenuItems {
	[self setPressedResExtractPath:[sender selectedResExtractPath]];
	
	return [NSArray arrayWithObjects:
			[NSMenuItem menuItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Text \"%@\"",@"app"), string]
								   action:NULL
								   target:nil],
			
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Copy",@"app")
										   action:@selector(copy:)
										   target:nil],
			//[NSMenuItem separatorItem],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Extract and Reply",@"app")
										   action:@selector(extractAndreply:)
										   target:self
								representedObject:string],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Search in Thread",@"app")
										   action:@selector(searchSelectionInThread:)
										   target:self
								representedObject:string],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Search Web",@"app")
										   action:@selector(searchSelectionUsingWebBrowser:)
										   target:self
								representedObject:string],
			//[NSMenuItem separatorItem],
			[NSMenuItem indentedMenuItemWithTitle:NSLocalizedString(@"Set NG Word",@"app")
										   action:@selector(setSelectionToNGWord:)
										   target:self
								representedObject:string],
			nil];
}
-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForOtherURL:(NSString *)URLString defaultMenuItems:(NSArray *)defaultMenuItems {
	NSMutableArray *menuItems = [NSMutableArray array];
	
	setObjectWithRetain(_pressedURLString, URLString);
	[menuItems addObject:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Copy Link URL",@"doc")
												action:@selector(copyLinkURL:)
												target:self]];
	[menuItems addObject:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Open Link Using Web Browser",@"doc")
												action:@selector(openLinkUsingWebBrowser:)
												target:self]];
	[menuItems addObject:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Download Linked File",@"doc")
												action:@selector(downloadLink:)
												target:self]];
	return menuItems;
}
-(NSArray *)threadView:(T2ThreadView *)sender contextMenuItemsForOtherElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
	return [self menusForThread];
}

#pragma mark -
#pragma mark Menu And Toolbar item Validation
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	return [self validateUIOfAction:[(NSMenuItem *)menuItem action]];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	return [self validateUIOfAction:[theItem action]];
}

-(BOOL)validateUIOfAction:(SEL)action {
	if (action == @selector(reloadView:)) {
		return ![[_threadView thread] isLoading];
		
	} else if (action == @selector(cancelLoading:)) {
		return [[_threadView thread] isLoading];
		
	} else if (action == @selector(removeSelectedThreads:)) {
		if (![[[_threadView thread] threadFace] logFilePath]) return NO;
		return YES;
		
	} else if (action == @selector(removeAllResStyleAction:)) {
		return [[_threadView thread] hasStyles];
		
	}
	else if (action == @selector(postRes:) || action == @selector(reply:) || action == @selector(extractAndreply:)) {
		return [[T2PluginManager sharedManager] canPostResToThread:[_threadView thread]];
		
	} else if (action == @selector(openUsingWebBrowser:) ||
			   action == @selector(copyURL:) || 
			   action == @selector(copyTitleAndURL:)) {
		if (![[_threadView thread] webBrowserURLString]) return NO;
		return YES;
	} else if (action == @selector(openUsingOreyon:)) {
		if (![THDocument oreyonPath] || ![[[_threadView thread] threadFace] logFilePath]) return NO;
		return YES;
	}
	return YES;
}

#pragma mark -
-(void)searchString:(NSString *)aString {
	if (!aString || [aString length]==0) return;
	
	if ([aString hasPrefix:@"internal://"]) {
		[_threadView setResExtractPath:aString];
		return;
	}
	[_document loadThread:[_threadView thread] resExtractedPath:[NSString stringWithFormat:@"word/%@",[aString stringByAddingUTF8PercentEscapesForce]]];
}

#pragma mark -
#pragma mark Actions

-(IBAction)reloadView:(id)sender {
	if ([_threadView thread]) {
		[[_threadView thread] load];
	}
}
-(IBAction)cancelLoading:(id)sender {
	if ([_threadView thread]) {
		[[_threadView thread] cancelLoading];
	}
}
-(IBAction)showFirst100Res:(id)sender {
	if ([[_threadView resExtractPath] isEqualToString:@"automatic"]) {
		[_threadView displayResForNumber:1];
	} else {
		if ([__defaultResExtractPath isEqualToString:@"automatic"]) {
			[_threadView setResExtractPath:@"automatic"];
			[_threadView registerDisplayResForNumber:1];
		} else {
			[_threadView setResExtractPath:@"resNumber/1-100"];
		}
	}
}
-(IBAction)showNext100Res:(id)sender {
	if ([[_threadView resExtractPath] isEqualToString:@"automatic"]) {
		unsigned index = [_threadView resIndexDisplayedOnTop];
		index += 100;
		unsigned resCount = [[_threadView thread] resCount];
		if (index >= resCount) {
			index = resCount -1;
		}
		[_threadView displayResForNumber:index+1];
	} else {
		if ([__defaultResExtractPath isEqualToString:@"automatic"]) {
			[_threadView setResExtractPath:@"automatic"];
			unsigned index = [_threadView resIndexDisplayedOnTop];
			index += 100;
			unsigned resCount = [[_threadView thread] resCount];
			if (index >= resCount) {
				index = resCount -1;
			}
			[_threadView registerDisplayResForNumber:index+1];

		} else {
			NSIndexSet *resIndexes = [_threadView resIndexes];
			if (!resIndexes) return;
			unsigned lastIndex = [resIndexes lastIndex];
			unsigned count = [[_threadView thread] resCount];
			if (lastIndex+100 < count) {
				[_threadView setResExtractPath:[NSString stringWithFormat:@"resNumber/%d-%d",lastIndex+2, lastIndex+101]];
			} else if (lastIndex+1 < count) {
				[_threadView setResExtractPath:[NSString stringWithFormat:@"resNumber/%d-%d",lastIndex+2, count]];
			}
		}
	}
}
-(IBAction)showLast100Res:(id)sender {
	if ([[_threadView resExtractPath] isEqualToString:@"automatic"]) {
		unsigned resCount = [[_threadView thread] resCount];
		if (resCount <= 100) {
			resCount = 1;
		}
		[_threadView displayResForNumber:resCount];
	} else {
		if ([__defaultResExtractPath isEqualToString:@"automatic"]) {
			[_threadView setResExtractPath:@"automatic"];
			unsigned resCount = [[_threadView thread] resCount];
			if (resCount <= 100) {
				resCount = 1;
			}
			[_threadView registerDisplayResForNumber:resCount];
		} else {
			[_threadView setResExtractPath:@"last/100"];
		}
	}
}
-(IBAction)showAllRes:(id)sender {
	if ([[_threadView resExtractPath] isEqualToString:@"automatic"]) {
		[_threadView displayResForNumber:1];
	} else {
		if ([__defaultResExtractPath isEqualToString:@"automatic"]) {
			[_threadView setResExtractPath:@"automatic"];
		} else {
			[_threadView setResExtractPath:@"allRes"];
		}
	}
}
-(IBAction)trace:(id)sender {
	NSString *resExtractPath = [_threadView resExtractPath];
	if ([[resExtractPath firstPathComponent] hasPrefix:@"internal"])
		resExtractPath = [resExtractPath stringByDeletingfirstPathComponent];
	
	
	if ([[resExtractPath firstPathComponent] isEqualToString:@"trace"]) {
		NSArray *components = [resExtractPath pathComponents];
		if ([components count] > 2) {
			int traceLevel = [(NSString *)[components objectAtIndex:1] intValue];
			if (traceLevel > 0 && traceLevel < 1000) {
				NSMutableArray *mutableComponents = [[components mutableCopy] autorelease];
				[mutableComponents replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%d", traceLevel+1]];
				[_threadView setResExtractPath:[mutableComponents componentsJoinedByString:@"/"]];
				return;
			}
		}
	} else {
		[_threadView setResExtractPath:[NSString stringWithFormat:@"trace/1/%@", resExtractPath]];
		return;
	}
}

-(IBAction)selectResExtractPathAction:(id)sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		NSString *extractPath = [(NSMenuItem *)sender representedObject];
		if (extractPath && [extractPath isKindOfClass:[NSString class]]) {
			[_threadView setResExtractPath:extractPath];
		}
	}
}

-(IBAction)selectHTMLExporterAction:(id)sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		NSString *uniqueName = [(NSMenuItem *)sender representedObject];
		if (!uniqueName) return;
		id plugin = [[T2PluginManager sharedManager] pluginForUniqueName:uniqueName];
		if (!plugin) return;
		
		[_threadView setHTMLExporter:(id <T2ThreadHTMLExporting_v100>)plugin];
	}
}

-(IBAction)showSource:(id)sender {
	NSString *oldSource =  [[[[_threadView mainFrame] dataSource] representation] documentSource];
	DOMDocument *domDocument = [[_threadView mainFrame] DOMDocument];
	if ([domDocument isKindOfClass:[DOMHTMLDocument class]]) {
		
		NSRange htmlStart = [oldSource rangeOfString:@"<html>"];
		NSRange htmlEnd = [oldSource rangeOfString:@"</html>"];
		if (htmlStart.location != NSNotFound && htmlEnd.location != NSNotFound) {
			NSString *preHtml = [oldSource substringToIndex:htmlStart.location];
			NSString *postHtml = [oldSource substringFromIndex:htmlEnd.location+htmlEnd.length];
			NSString *htmlSource = [(DOMHTMLElement *)[(DOMHTMLDocument *)domDocument documentElement] outerHTML];
			
			oldSource = [[preHtml stringByAppendingString:htmlSource] stringByAppendingString:postHtml];
		}
	}
	
	[(THAppDelegate *)[NSApp delegate] showSourceWindowWithString:oldSource];
}
-(IBAction)removeSelectedThreads:(id)sender {
	NSAlert *alertPanel = [[NSAlert alertWithMessageText:THBookmarkLocalize(@"Move Log Files to Trash")
										   defaultButton:THBookmarkLocalize(@"OK")
										 alternateButton:THBookmarkLocalize(@"Cancel")
											 otherButton:nil
							   informativeTextWithFormat:THBookmarkLocalize(@"Are you sure to move log files to Trash?")] retain];
	
	[alertPanel beginSheetModalForWindow:[_threadView window]
						   modalDelegate:self
						  didEndSelector:@selector(deleteLogAlertDidEnd:returnCode:contextInfo:)
							 contextInfo:NULL];
	
}
- (void)deleteLogAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	if (returnCode != NSOKButton) {
		[alert release];
		return;
	}
	
	NSArray *selectedThreadFaces = [NSArray arrayWithObject:[[_threadView thread] threadFace]];
	[_document deleteLogFilesWithThreadFaces:selectedThreadFaces];
	
	[alert release];
}
-(IBAction)removeSelectedThreadsImmediately:(id)sender {
	NSArray *selectedThreadFaces = [NSArray arrayWithObject:[[_threadView thread] threadFace]];
	[_document deleteLogFilesWithThreadFaces:selectedThreadFaces];
}

-(IBAction)revealLogFileInFinder:(id)sender {
	NSString *path = [[[_threadView thread] threadFace] logFilePath];
	if (!path) return;
	NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
	[sharedWorkspace selectFile:path
	   inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
}

-(IBAction)addToBookmark:(id)sender {
	[THAddBookmarkWindowController beginSheetModalForWindow:[_threadView window]
												threadFaces:[NSArray arrayWithObject:[[_threadView thread] threadFace]]];
}
-(IBAction)selectLabelAction:(id)sender {
	if (![sender isKindOfClass:[NSMenuItem class]]) return;
	NSNumber *number = [(NSMenuItem *)sender representedObject];
	unsigned label = [number unsignedIntValue];
	
	T2ThreadFace *threadFace = [[_threadView thread] threadFace];
	[threadFace setLabel:label];
	[self updateLabelButton];
}

-(IBAction)moveToNewRes:(id)sender {
	unsigned index = [[_threadView thread] newResIndex];
	NSIndexSet *resIndexes = [_threadView resIndexes];
	if (!resIndexes) return;
	if ([resIndexes lastIndex]+1 == index) {
		[_threadView displayElementByID:@"last"];
		//[_threadView displayElementByID:[NSString stringWithFormat:@"res%d",[resIndexes lastIndex]+1]];
	}
	else {
		if (![_threadView displayElementByID:@"new"]) {
			[_threadView displayElementByID:@"last"];
		}
	}
}

-(IBAction)openUsingWebBrowser:(id)sender {
	NSString *urlString = [[_threadView thread] webBrowserURLString];
	if (urlString) [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}
-(IBAction)openUsingOreyon:(id)sender {
	T2ThreadFace *threadFace = [[_threadView thread] threadFace];
	NSString *filePath = [threadFace logFilePath];
	if (filePath) {
		[[NSWorkspace sharedWorkspace] openFile:filePath
								withApplication:@"Oreyon"];
	}
}

-(IBAction)findNextThread:(id)sender {
	[[THChooseNextThreadWindowController beginSheetModalForWindow:[_threadView window]
											   withOldThreadFace:[[_threadView thread] threadFace]
												   newThreadFace:nil
														delegate:self
												  didEndSelector:@selector(nextThreadFound:)] retain];
}
-(void)nextThreadFound:(T2ThreadFace *)threadFace {
	if (!threadFace) return;
	[_document loadThreadForThreadFace:threadFace activateTab:YES];
}

-(IBAction)openParentThreadList:(id)sender {
	T2ListFace *listFace = [[_threadView thread] threadListFace];
	if (listFace) {
		[_document openListWithListFace:listFace];
	}
}


-(IBAction)copyURL:(id)sender {
	NSString *urlString = [[_threadView thread] webBrowserURLString];
	if (!urlString) return;
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, nil]
					   owner:nil];
	[pasteBoard setString:urlString forType:NSStringPboardType];
	[url writeToPasteboard:pasteBoard];
}
-(IBAction)copyTitleAndURL:(id)sender {
	NSString *urlString = [[_threadView thread] webBrowserURLString];
	if (!urlString) return;
	NSURL *url = [NSURL URLWithString:urlString];
	urlString = [NSString stringWithFormat:@"%@\n%@", [[_threadView thread] title], urlString];
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, nil]
					   owner:nil];
	[pasteBoard setString:urlString forType:NSStringPboardType];
	[url writeToPasteboard:pasteBoard];
}

-(IBAction)postRes:(id)sender {
	[[THPostingWindowController resPostingWindowForThread:[_threadView thread] content:nil] retain];
}
- (IBAction)printTab:(id)sender {
	
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:[[[_threadView mainFrame] frameView] documentView]];
    //NSView *accView = [self printAccessoryView];
    //[op setAccessoryView:accView];
	[op runOperationModalForWindow:[_threadView window]
						  delegate:nil didRunSelector:NULL contextInfo:NULL];}

#pragma mark Res Actions
-(IBAction)reply:(id)sender {
	NSMutableString *content = [NSMutableString string];
	NSString *selectedResExtractPath = [self pressedResExtractPath];
	if (selectedResExtractPath) {
		[content appendFormat:@">>%@\n",
		 [[T2PluginManager sharedManager] localizedDescriptionOfExtractPath:selectedResExtractPath]];
	}
	[[THPostingWindowController resPostingWindowForThread:[_threadView thread] content:content] retain];
}
-(IBAction)extractAndreply:(id)sender {
	NSMutableString *content = [NSMutableString string];
	
	NSString *selectedResExtractPath = [self pressedResExtractPath];
	NSString *searchString = [(NSMenuItem *)sender representedObject];
	
	if (selectedResExtractPath) {
		[content appendFormat:@">>%@\n",
		 [[T2PluginManager sharedManager] localizedDescriptionOfExtractPath:selectedResExtractPath]];
	}
	//NSString *searchString = [[sender selectedDOMRange] toStringContainsLineBreaks];
	if (searchString && [searchString length]>0) {
		NSArray *lines = [searchString componentsSeparatedByString:@"\n"];
		NSEnumerator *lineEnumerator = [lines objectEnumerator];
		NSString *line;
		while (line = [lineEnumerator nextObject]) {
			[content appendFormat:@"> %@\n", line];
		}
	}
	[[THPostingWindowController resPostingWindowForThread:[_threadView thread] content:content] retain];
}

-(IBAction)moveToRes:(id)sender {
	[_threadView moveToResExtractPath:[self pressedResExtractPath]];
}
-(IBAction)openResInNewTab:(id)sender {
	NSString *selectedResExtractPath = [self pressedResExtractPath];
	[_document loadThread:[_threadView thread] resExtractedPath:selectedResExtractPath];
}

-(IBAction)showPreviewableRes:(id)sender {
	[_threadView setResExtractPath:@"previewable"];
}

-(IBAction)previewInlineInRes:(id)sender {
	NSString *selectedResExtractPath = [self pressedResExtractPath];
	[_threadView replacePreviewableAnchorElementsInResExtractPath:selectedResExtractPath];
}
-(IBAction)previewInlineAll:(id)sender {
	[_threadView replaceAllPreviewableAnchorElements];
}


#pragma mark Text and URL Actions

-(IBAction)searchSelectionInThread:(id)sender {
	NSString *searchString = [(NSMenuItem *)sender representedObject];
	[self searchString:searchString];
}
-(IBAction)searchSelectionUsingWebBrowser:(id)sender {
	NSString *selection = [(NSMenuItem *)sender representedObject];
	if (!selection || [selection length]==0) return;
	
	NSString *urlString = [NSString stringWithFormat:NSLocalizedString(@"URL_FOR_SEARCH(%@)",nil),[selection stringByAddingUTF8PercentEscapesForce]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}
-(IBAction)setSelectionToNGWord:(id)sender {
	NSString *selection = [(NSMenuItem *)sender representedObject];
	selection = [selection stringByAddingUTF8PercentEscapesForce];
	if (selection) {
		
		DOMDocument *document = [[_threadView mainFrame] DOMDocument];
		DOMRange *range = [document createRange];
		[_threadView setSelectedDOMRange:range affinity:NSSelectionAffinityDownstream];
		
		[[_threadView thread] addStyle:@"invisible" ofResWithExtractPath:[NSString stringWithFormat:@"word/%@", selection]];
	}
}

-(IBAction)copyLinkURL:(id)sender {
	if (!_pressedURLString) return;
	NSString *urlString = _pressedURLString;
	if (!urlString) return;
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects:
					  NSStringPboardType,
					  NSURLPboardType,
					  nil];
	[pasteBoard declareTypes:types owner:nil];
	[pasteBoard setString:urlString forType:NSStringPboardType];
	[[NSURL URLWithString:urlString] writeToPasteboard:pasteBoard];
}
-(IBAction)openLinkUsingWebBrowser:(id)sender {
	if (!_pressedURLString) return;
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_pressedURLString]];
}
-(IBAction)downloadLink:(id)sender {
	if (!_pressedURLString) return;
	[[THDownloadWindowController downloadWindowController] addDownloadOfURLString:_pressedURLString
																		 inThread:[_threadView thread]];
}
-(IBAction)downloadLinkInRes:(id)sender {
	NSString *selectedResExtractPath = [self pressedResExtractPath];
	NSArray *urlStrings = [_threadView urlStringsOfAnchorElementsInResExtractPath:selectedResExtractPath];
	NSEnumerator *urlStringEnumerator = [urlStrings objectEnumerator];
	NSString *urlString;
	while (urlString = [urlStringEnumerator nextObject]) {
		[[THDownloadWindowController downloadWindowController] addDownloadOfURLString:urlString
																			 inThread:[_threadView thread]];
	}
}
@end
/*
 * Copyright (c) 2005-2006 KATO Kazuyoshi
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

#import "TEC.h"

@implementation TECConverter

- (id) initWithEncoding: (NSStringEncoding) from
                     to: (NSStringEncoding) to
{
    self = [super init];
    
    from_ = CFStringConvertNSStringEncodingToEncoding(from);
    to_   = CFStringConvertNSStringEncodingToEncoding(to);
	
	OSStatus status;
	
	status = TECCreateConverter(&converter_, from_, to_);
	if (status != noErr) {
		return nil;
	}
    
    return self;
}

- (id) initWithEncoding: (NSStringEncoding) from
{
	self = [self initWithEncoding: from
							   to: NSUnicodeStringEncoding];
	return self;
}

- (NSData*) convert: (NSData*) source
{    
    OSStatus status;
    NSMutableData* result;
    const unsigned char* input;
    ByteCount inputLength;
    ByteCount actualInputLength, actualOutputLength;
    unsigned char buffer[256];
    
    result = [NSMutableData data];
	if (to_ == kCFStringEncodingUnicode) {
		UInt16 bom = 0xfeff;
		[result appendBytes: &bom length: sizeof(bom)];
	}
	
    input = [source bytes];
    inputLength = [source length];
    for (;;) {
        status = TECConvertText(converter_,
                                input, inputLength,
                                &actualInputLength, 
                                buffer, sizeof(buffer), 
                                &actualOutputLength);
        
        input += actualInputLength;
        inputLength -= actualInputLength;
        
        [result appendBytes: buffer
                     length: actualOutputLength];
        if (actualInputLength == 0) {
            break;
        }
    }
    status = TECFlushText(converter_,
                          buffer, sizeof(buffer), 
                          &actualOutputLength);
    [result appendBytes: buffer
                 length: actualOutputLength];
    
    return result;
}

- (NSString*) convertToString: (NSData*) source
{
    NSString* s;
    
    s = [[NSString alloc] initWithData: [self convert: source]
                              encoding: NSUnicodeStringEncoding];
    return [s autorelease];
}

#pragma mark Override

- (void) dealloc
{
    TECDisposeConverter(converter_);
	[super dealloc];
}

@end

@implementation TECSniffer

- (NSArray*) sniff: (NSData*) data
{    
    OSStatus status;
    
    ItemCount* encodings;
    ItemCount* errors;
    ItemCount* features;
    ItemCount numErrors, numFeatures;
    
    numErrors = numFeatures = numEncodings_;
    
    encodings = malloc(sizeof(TextEncoding) * numEncodings_);
    memcpy(encodings, encodings_, sizeof(TextEncoding) * numEncodings_);
    
    errors = malloc(sizeof(ItemCount) * numErrors);
    features = malloc(sizeof(ItemCount) * numFeatures);
    
    status = TECSniffTextEncoding(sniffer_,
                                  [data bytes],
                                  [data length],
                                  encodings,
                                  numEncodings_,
                                  errors,
                                  numErrors,
                                  features,
                                  numFeatures);
    
    if (status != noErr) {
        NSLog(@"TECSniffer - sniff: / Failed to sniff text encoding.");
    }
    
	NSMutableArray* result = [NSMutableArray array];
	int i;
	for (i = 0; i < numEncodings_; i++) {
		NSStringEncoding e = CFStringConvertEncodingToNSStringEncoding(encodings[i]);
		[result addObject: [NSNumber numberWithUnsignedInt: e]];
	}
    
    free(encodings);
    free(errors);
    free(features);
	
    return result;
}

- (void) clear
{
    TECClearSnifferContextInfo(sniffer_);
}

- (id) initWithWebTextEncodings
{
    self = [super init];
    
	RegionCode regionCode;
	CFLocaleRef currentLocale = CFLocaleCopyCurrent();
	const char* str = [(NSString *)(CFLocaleGetIdentifier(currentLocale)) UTF8String];
	CFRelease(currentLocale);
	// NSLog(@"locale = %s", str);
	LocaleStringToLangAndRegionCodes(str, NULL, &regionCode);
	
    OSStatus status;
    ItemCount actualCount;
    
    status = TECCountWebTextEncodings(regionCode, &numEncodings_);
    if (status != noErr)
        return nil;
    
    encodings_ = (TextEncoding*) malloc(sizeof(TextEncoding) * numEncodings_);
    
    status = TECGetWebTextEncodings(regionCode,
									encodings_,
									numEncodings_,
									&actualCount);
    if (status != noErr)
        return nil;
    
    numEncodings_ = actualCount;
    
    status = TECCreateSniffer(&sniffer_, encodings_, numEncodings_);
    if (status != noErr)
        return nil;
    
    return self;
}

#pragma mark Override
- (id) init
{
    self = [super init];
    if (! self) {
        return nil;
    }
    
    OSStatus status;
    ItemCount actualCount;
    
    status = TECCountAvailableTextEncodings(&numEncodings_);
    if (status != noErr)
        return nil;
    
    encodings_ = (TextEncoding*) malloc(sizeof(TextEncoding) * numEncodings_);
    
    status = TECGetAvailableTextEncodings(encodings_,
                                          numEncodings_,
                                          &actualCount);
    if (status != noErr)
        return nil;
    
    numEncodings_ = actualCount;
    
    status = TECCreateSniffer(&sniffer_, encodings_, numEncodings_);
    if (status != noErr)
        return nil;
    
    return self;
}

- (void) dealloc
{
    free(encodings_);
    TECDisposeSniffer(sniffer_);
	
	[super dealloc];
}

@end

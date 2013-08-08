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

#import <Cocoa/Cocoa.h>

@interface TECConverter : NSObject {
    TextEncoding from_;
    TextEncoding to_;
    TECObjectRef converter_;
}

- (id) initWithEncoding: (NSStringEncoding) from
                     to: (NSStringEncoding) to;
- (id) initWithEncoding: (NSStringEncoding) from;

- (NSData*) convert: (NSData*) source;
- (NSString*) convertToString: (NSData*) source;
@end


@interface TECSniffer : NSObject {
    TextEncoding* encodings_;
    ItemCount numEncodings_;
    TECSnifferObjectRef sniffer_;
}

- (id) init;
- (id) initWithWebTextEncodings;

- (NSArray*) sniff: (NSData*) data;
- (void) clear;
@end

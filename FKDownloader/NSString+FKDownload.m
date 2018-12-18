//
//  NSString+FKDownload.m
//  FKDownloaderDemo
//
//  Created by Norld on 2018/11/2.
//  Copyright © 2018 Norld. All rights reserved.
//

#import "NSString+FKDownload.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (FKDownload)

- (NSString *)MD5 {
    unsigned int outputLength = CC_MD5_DIGEST_LENGTH;
    unsigned char output[outputLength];
    
    CC_MD5(self.UTF8String, [self UTF8Length], output);
    return [self toHexString:output length:outputLength];
}

- (NSString *)SHA1 {
    unsigned int outputLength = CC_SHA1_DIGEST_LENGTH;
    unsigned char output[outputLength];
    
    CC_SHA1(self.UTF8String, [self UTF8Length], output);
    return [self toHexString:output length:outputLength];
}

- (NSString *)SHA256 {
    unsigned int outputLength = CC_SHA256_DIGEST_LENGTH;
    unsigned char output[outputLength];
    
    CC_SHA256(self.UTF8String, [self UTF8Length], output);
    return [self toHexString:output length:outputLength];
}

- (NSString *)SHA512 {
    unsigned int outputLength = CC_SHA512_DIGEST_LENGTH;
    unsigned char output[outputLength];
    
    CC_SHA512(self.UTF8String, [self UTF8Length], output);
    return [self toHexString:output length:outputLength];
}

- (unsigned int)UTF8Length {
    return (unsigned int)[self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)identifier {
    return [self SHA256];
}

- (NSString *)toHexString:(unsigned char*)data length:(unsigned int)length {
    NSMutableString *hash = [NSMutableString stringWithCapacity:length * 2];
    for (unsigned int i = 0; i < length; i++) {
        [hash appendFormat:@"%02x", data[i]];
        data[i] = 0;
    }
    return [hash copy];
}

/**
 Returns a percent-escaped string following RFC 3986 for a query string key or value.
 RFC 3986 states that the following characters are "reserved" characters.
 - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
 - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
 
 In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
 query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
 should be percent-escaped in the query string.
 - parameter string: The string to be percent-escaped.
 - returns: The percent-escaped string.
 */
- (NSString *)percentEscapedString {
    NSArray<NSString *> *splitURL = [self componentsSeparatedByString:@"://"];
    NSString *scheme = splitURL[0];
    NSString *path = splitURL[1];
    
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
    
    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < path.length) {
        NSUInteger length = MIN(path.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [path rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [path substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return [NSString stringWithFormat:@"%@://%@", scheme, escaped];
}

- (NSString *)encodeEscapedString {
    // !!!: 识别 URL 是否已经过 URL Encode
    if ([[self stringByRemovingPercentEncoding] isEqualToString:self]) {
        return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    } else {
        return self;
    }
}

- (NSString *)decodeEscapedString {
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end

//
//  aes.h
//  ObjcJXARunner
//
//  Created by david on 2/2/23.
//
#import <CommonCrypto/CommonCryptor.h>
#import <Foundation/Foundation.h>


#ifndef aes_h
#define aes_h


@interface AES : NSObject

@property (nonatomic, strong) NSData *key;
@property (nonatomic, strong) NSData *iv;

- (instancetype)initWithKey:(NSData *)key iv:(NSData *)iv;
- (NSData *)encryptData:(NSData *)data;
- (NSData *)decryptData:(NSData *)data;

@end

@implementation AES

- (instancetype)initWithKey:(NSData *)key iv:(NSData *)iv
{
    self = [super init];
    if (self) {
        if (key.length != kCCKeySizeAES128 && key.length != kCCKeySizeAES256) {
            NSLog(@"Error: Failed to set a key.");
            return nil;
        }

        if (iv.length != kCCBlockSizeAES128) {
            NSLog(@"Error: Failed to set an initial vector.");
            return nil;
        }

        _key = key;
        _iv = iv;
    }
    return self;
}

- (NSData *)encryptData:(NSData *)data
{
    return [self cryptData:data option:kCCEncrypt];
}

- (NSData *)decryptData:(NSData *)data
{
    return [self cryptData:data option:kCCDecrypt];
}

- (NSData *)cryptData:(NSData *)data option:(CCOperation)option
{
    if (!data) {
        return nil;
    }

    size_t cryptLength = data.length + kCCBlockSizeAES128;
    NSMutableData *cryptData = [NSMutableData dataWithLength:cryptLength];

    size_t keyLength = self.key.length;
    uint32_t options = kCCOptionPKCS7Padding;

    size_t bytesLength = 0;

    CCCryptorStatus status = CCCrypt(option, kCCAlgorithmAES, options, self.key.bytes, keyLength, self.iv.bytes, data.bytes, data.length, cryptData.mutableBytes, cryptLength, &bytesLength);

    if (status != kCCSuccess) {
        NSLog(@"Error: Failed to crypt data. Status %d", status);
        return nil;
    }

    [cryptData setLength:bytesLength];
    return [cryptData copy];
}

@end

#endif /* aes_h */

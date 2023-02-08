//
//  http.m
//  ObjcJXARunner
//
//  Created by david on 2/2/23.
//

#import <Foundation/Foundation.h>

NSData *makeHTTPRequestAsBytes(NSString *urlString) {
  NSURL *url = [NSURL URLWithString:urlString];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];

  NSError *error = nil;
  NSHTTPURLResponse *response = nil;
  NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

  if (error) {
    NSLog(@"Error making HTTP request: %@", error);
    return nil;
  }

  return data;
}

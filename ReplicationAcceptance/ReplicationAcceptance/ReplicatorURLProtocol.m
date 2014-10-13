//
//  ReplicatorURLProtocol.m
//  ReplicationAcceptance
//
//  Created by Adam Cox on 10/16/14.
//
//

#import "ReplicatorURLProtocol.h"
#import "ReplicatorURLProtocolTester.h"

static ReplicatorURLProtocolTester* gReplicatorTester = nil;

@implementation ReplicatorURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // Capture all of the GET, PUT and POST calls
    // Can we assume that during tests, all of these calls are for replication?
    // I think this is okay if this protocol is registered after the remote DB is
    // created (with PUT /db) and we unregister this class at the end of the test.
    NSString *httpmethod = [request HTTPMethod];
    
    if ( ([httpmethod isEqualToString:@"GET"] || [httpmethod isEqualToString:@"PUT"] ||
        [httpmethod isEqualToString:@"POST"]) &&  gReplicatorTester) {
        
        [gReplicatorTester runTestForRequest:request];

    }
    return NO;
}

+(void)setTestDelegate:(ReplicatorURLProtocolTester*) delegate
{
    gReplicatorTester = delegate;
}

@end

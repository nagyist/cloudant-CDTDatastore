//
// Created by Rhys Short on 02/09/2016.
// Copyright © 2016 IBM Corporation. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.


#import "CDTDatastore+Replication.h"
#import "CDTPushReplication.h"
#import "CDTPullReplication.h"
#import "CDTReplicator.h"

@interface CDTDatastoreReplicationDelegate: NSObject<CDTReplicatorDelegate>

@property (nonatomic, nullable, strong) NSError *error;
@property (nonatomic, nonnull, strong) void (^completionHandler)(NSError* __nullable) ;
@property (nonatomic, nullable, strong) CDTDatastoreReplicationDelegate* instance;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithCompletionHandler:(void (^ __nonnull)(NSError* __nullable)) compeltionHandler NS_DESIGNATED_INITIALIZER;



@end

@implementation CDTDatastoreReplicationDelegate

- (instancetype)initWithCompletionHandler:(void (^)(NSError *))completionHandler {
    self = [super init];
    if (self) {
        _completionHandler = completionHandler;
        // Since the replicator doesn't retain it's delegate, we need to retain ourselves so we can complete.
        _instance = self;
    }

    return self;
}

- (void)replicatorDidComplete:(CDTReplicator *)replicator {
    self.completionHandler(self.error);
    self.instance = nil;
}

- (void)replicatorDidError:(CDTReplicator *)replicator info:(NSError *)info {
    self.error = info;
}

@end


@interface CDTDatastore ()

@property(readonly) CDTDatastoreManager *manager; // this exists in the CDTDatastoreManager
@end

@implementation CDTDatastore (Replication)

- (CDTReplicator *)pushReplicationTarget:(NSURL *)target
                            withDelegate:(NSObject <CDTReplicatorDelegate> *)delegate
                                   error:(NSError *__autoreleasing *)error {
    CDTPushReplication *push = [CDTPushReplication replicationWithSource:self target:target];
    return [self replicatorWithReplication:push delegate:delegate error:error];
}

- (CDTReplicator *)pullReplicationSource:(NSURL *)source
                            withDelegate:(NSObject <CDTReplicatorDelegate> *)delegate
                                   error:(NSError *__autoreleasing *)error {

    CDTPullReplication *pull = [CDTPullReplication replicationWithSource:source target:self];
    return [self replicatorWithReplication:pull delegate:delegate error:error];
}

- (CDTReplicator *)replicatorWithReplication:(CDTAbstractReplication *)replication
                                    delegate:(NSObject <CDTReplicatorDelegate> *)delegate
                                       error:(NSError *__autoreleasing *)error {
    CDTReplicator *replicator = [[CDTReplicator alloc] initWithTDDatabaseManager:self.manager.manager
                                                                     replication:replication
                                                           sessionConfigDelegate:nil
                                                                           error:error];
    replicator.delegate = delegate;
    return replicator;
}

- (void) pushReplicationWithTarget:(NSURL*) target
                 completionHandler:(void (^ __nonnull)(NSError* __nullable)) completionHandler
{
    NSError* error = nil;
    CDTDatastoreReplicationDelegate* delegate = [[CDTDatastoreReplicationDelegate alloc] initWithCompletionHandler:completionHandler];
    CDTReplicator* replicator = [self pushReplicationTarget:target withDelegate:delegate error:&error];
    if (!error){
        [replicator startWithError:&error];
    }

    if (error) {
        completionHandler(error);
    }

}

- (void) pullReplicationWithSource:(NSURL*) source
                 completionHandler:(void (^ __nonnull)(NSError* __nullable)) completionHandler
{
    NSError* error = nil;
    CDTDatastoreReplicationDelegate* delegate = [[CDTDatastoreReplicationDelegate alloc] initWithCompletionHandler:completionHandler];
    CDTReplicator* replicator = [self pullReplicationSource:source withDelegate:delegate error:&error];
    if (!error){
        [replicator startWithError:&error];
    }
    
    if (error) {
        completionHandler(error);
    }
}




@end

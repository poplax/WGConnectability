#import "WGConnectability.h"

@interface WGConnectability ()

//@property(nonatomic,assign) NSError *pingError;
@property(nonatomic,strong) NSInputStream *inputStream;
@property(nonatomic,strong) NSOutputStream *outputStream;
@property(nonatomic, strong) dispatch_semaphore_t semaphore;
@property(nonatomic, assign) BOOL success;

@end


@implementation WGConnectability

// Blocking call. Opens and closes a tcp connection to the address on port 80.
// returns success bool
// DO NOT CALL FROM MAIN THREAD. It will deadlock and time out.
- (BOOL)connectToAddressSync:(NSString*)address
{
    if (self.outputStream)
    {
        // still busy with another request. Fail immediately
        return NO;
    }
    // Create socket pair:
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)address, 80, &readStream, &writeStream);

    self.success = NO;
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    self.inputStream = (__bridge NSInputStream *)readStream;
    self.semaphore = dispatch_semaphore_create(0);
    [self.outputStream setDelegate:self];
    [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];

    // 2 second timeout
    dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 2));

    [self.outputStream close];
    [self.outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream setDelegate:nil];
    self.outputStream = nil;
    self.inputStream = nil;

    return self.success;
}

// Non-blocking call. Opens and closes a tcp connection to the address on port 80.
//
- (void)connectToAddressAsync:(NSString*)address
        onSuccess:(void (^)())successBlock
        onFail:(void (^)())failBlock
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if ([self connectToAddressSync:address])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failBlock();
            });
        }
    });
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)StreamEvent
{
    switch (StreamEvent)
    {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventErrorOccurred:
            self.success = NO;
            dispatch_semaphore_signal(self.semaphore);
            break;
        case NSStreamEventHasSpaceAvailable:
            // means the tcp connection is open and ready for requests
            self.success = YES;
            dispatch_semaphore_signal(self.semaphore);
            break;
        default:
            // don't care about any other events
            ;
    }

}

@end

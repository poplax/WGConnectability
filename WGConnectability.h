#import <Foundation/Foundation.h>

@interface WGConnectability : NSObject<NSStreamDelegate>

- (BOOL)connectToAddressSync:(NSString*)address;

- (void)connectToAddressAsync:(NSString*)address
                    onSuccess:(void (^)())successBlock
                       onFail:(void (^)())failBlock;
@end

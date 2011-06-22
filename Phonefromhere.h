//
//
//  Created by Tim Panton on 28/02/2010.
//

#import <Foundation/Foundation.h>
#import "IAXCall.h"
#import "IAXFrameOut.h"

@interface Phonefromhere : NSObject {
	NSString *host;
    uint16_t port;
    uint16_t localport;
    int ipv4Soc;
    NSThread *netThread;
    NSMutableDictionary *calls;
    NSMutableDictionary *audios;
    NSThread *rcvThread;
    NSString *version;
}
@property (nonatomic, assign) NSString *host;
@property (nonatomic, assign) uint16_t port;
@property (nonatomic, readonly) NSString *version;


- (void) startIAX;
- (IAXCall *) newCall:(NSString *)user pass:(NSString *)pass exten:(NSString *)exten statusListener:(id <callStatusListener>)statusListener ;
-(BOOL) sendFrame : (IAXFrameOut *) frame;
- (void)hungupCall: (IAXCall *)call cause:(NSString *)reason code:(NSNumber *)code ;
@end

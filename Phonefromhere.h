//
//
//  Created by Tim Panton on 28/02/2010.
//
/* Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
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
- (IAXCall *) newCall:(NSString *)user pass:(NSString *)pass exten:(NSString *)exten forceCodec:(NSString *)codec statusListener:(id <callStatusListener>)statusListener ;
-(BOOL) sendFrame : (IAXFrameOut *) frame;
- (void)hungupCall: (IAXCall *)call cause:(NSString *)reason code:(NSNumber *)code ;
@end

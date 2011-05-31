//
//  PfhAudio.h
//  objiax
//
//  Created by Tim Panton on 14/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "AudioDataConsumer.h"
#import "CodecProtocol.h"


@interface PfhAudio : NSObject {
    NSMutableDictionary * codecs;
    id <CodecProtocol> codec;
    id <AudioDataConsumer> wire;
    NSInteger nextDue;
    NSInteger aframeLen;
    AudioQueueRef playQ;
	AudioQueueRef recQ;
/*    NSMutableArray *buffers;
    NSLock *bufflock; */
    BOOL playing;
    NSMutableDictionary *rcvdAudio;
    NSLock *rcvdLock;
    NSThread *audioThread;
    BOOL firstWired;
    NSInteger sent;
    NSMutableData *audioIn;
    NSLock *ainLock;
    NSMutableData *wout;
}
- (void) consumeWireData:(NSData*)data time:(NSInteger) stamp;
- (NSArray *) listCodecs;
- (BOOL) isCodecSupported:(NSString *) codecname;
- (NSInteger) getSampleRateForCodec:(NSString *) codecname;
- (BOOL) setCodec:(NSString *) codecname;
- (void) start;
- (void) stop;
- (void) setWireConsumer:(id<AudioDataConsumer>)a;
- (void) consumeWireData:(NSData*)data time:(NSInteger)stamp;

@end

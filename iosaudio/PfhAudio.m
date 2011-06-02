//
//  PfhAudio.m
//  objiax
//
//  Created by Tim Panton on 14/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import "PfhAudio.h"
#import "UlawCodec.h"
#import "GSM610Codec.h"
#import "G722Codec.h"
#import "SpeexCodec.h"

#import <AudioToolbox/AudioToolbox.h>
static int frameIntervalMS = 20; 
static int MAXPBUFF = 10;
static int MAXRBUFF = 5;

@implementation PfhAudio

// released audio buffer - put in free stack.
/*
-(void) putAudioInThis:(AudioQueueBufferRef)bref;{
    NSValue * bufValP = (NSValue *) bref->mUserData;   
    NSLog(@"AudioQueue returned a play buffer");

	[bufflock lock];
	[buffers addObject:bufValP]; 
	[bufflock unlock];
} */
-(void) fillAudioBuff:(AudioQueueBufferRef)bref withData:(NSData *)data{
    NSMutableData *din = [NSMutableData dataWithLength:aframeLen];
    if (data != nil){
        if (codec != nil) {
            [codec decode:data audioData:din];
        }
    } else {
        //NSLog(@"Padding AudioQueue play buffer with empty buffer");
        memset([din mutableBytes],0,aframeLen);
    }
    void *bytes = (void *)[din bytes];
    bref->mAudioDataByteSize = [din length];
    memcpy(bref->mAudioData, bytes, bref->mAudioDataByteSize);
}

-(void) putAudioInThis:(AudioQueueBufferRef)bref;{
    NSValue * bufValP = (NSValue *) bref->mUserData;   
    // and recycle it
    [rcvdLock lock];
    NSNumber *nd = [NSNumber numberWithInteger:nextDue];
    NSData * buff = [rcvdAudio objectForKey:nd];
    if (buff == nil){
        int cnt = [rcvdAudio count];
        if (cnt > 5){
            // time for drastic action.....
            NSLog(@"got %d entries but not %d",cnt,nextDue);
            NSArray *stamps = [[rcvdAudio allKeys] sortedArrayUsingSelector:@selector(compare:)];
            NSInteger i =0;
            for (i =0; i< cnt -3;i++){
                NSNumber *strm = [stamps objectAtIndex:i]; 
                NSLog(@"removing %d",[strm integerValue]);
                [rcvdAudio removeObjectForKey:strm];
            }
            nd = [stamps objectAtIndex:i];
            nextDue = [nd integerValue];
            NSLog(@"skipping to %d",nextDue);
            buff = [rcvdAudio objectForKey:nd];
        }
    }
    if (buff != nil){
        [rcvdAudio removeObjectForKey:nd];
    }

    nextDue = frameIntervalMS +nextDue;
    //NSLog(@"AudioQueue returned a play buffer nextDue is now %d",nextDue);

    [rcvdLock unlock];

    [self fillAudioBuff:bref withData:buff];
    AudioQueueEnqueueBuffer (playQ,bref,0,NULL);

}
/*
-(void) encodeAndSend:(AudioQueueBufferRef)bref{
    int over = [audioIn length];
    int reqd = aframeLen - over;
    int avail = bref->mAudioDataByteSize;
    if (avail >= reqd) {
        // got enough to send a packet
        [audioIn appendBytes:bref->mAudioData length: reqd];
        [codec encode:audioIn  wireData:wout];
        [wire consumeAudioData:wout time:(sent*frameIntervalMS)];
        sent++;
        [audioIn setLength:0];
        int remain = avail - reqd ;
        [audioIn appendBytes: (bref->mAudioData+reqd) length:remain];
    } else{
        NSLog(@"too short to make a frame %d needed %d",avail,reqd);
        [audioIn appendBytes:bref->mAudioData length:avail];
    }
    AudioQueueEnqueueBuffer (recQ,bref,0,NULL);

}
*/
-(void) encodeAndSend{
    [ainLock lock];
    int avail = [audioIn length];
    if (avail >= aframeLen) {
        // got enough to send a packet
        NSData * dts = [NSData dataWithBytes:[audioIn bytes] length:aframeLen];
        [codec encode:dts  wireData:wout];
        [wire consumeAudioData:wout time:(sent*frameIntervalMS)];
        sent++;
        uint8_t *md = [audioIn mutableBytes];
        int remain = avail-aframeLen;
        memcpy(md,md+aframeLen,avail-aframeLen);
        [audioIn setLength:remain];
    }
    [ainLock unlock];
}

-(void) enQueue:(AudioQueueBufferRef)bref{
    [ainLock lock];
    [audioIn appendBytes: bref->mAudioData length:bref->mAudioDataByteSize];
    [ainLock unlock];
    AudioQueueEnqueueBuffer (recQ,bref,0,NULL);

}
static void handleInputBuffer (
							   void                                 *aqData,
							   AudioQueueRef                        inAQ,
							   AudioQueueBufferRef                  inBuffer,
							   const AudioTimeStamp                 *inStartTime,
							   UInt32                               inNumPackets,
							   const AudioStreamPacketDescription   *inPacketDesc
                               ) {
	PfhAudio * me;
	me = (PfhAudio *) aqData;
	[me enQueue:inBuffer];
}

static void handleOutputBuffer( 
							   void *aqDatav, //1 
							   AudioQueueRef inAQ, //2 
							   AudioQueueBufferRef inBuffer //3 
                               ) {
	PfhAudio * me;
    //NSLog(@"handleOutputBuffer");

	me = (PfhAudio *) aqDatav;
	[me putAudioInThis:inBuffer];

}

void audioRootChanged (
                       void                      *inClientData,
                       AudioSessionPropertyID    inID,
                       UInt32                    inDataSize,
                       const void                *inData
                       ){
    NSLog(@"audioRootChanged");
    
}
void interruptionListenerCallback (void *inUserData, UInt32  interruptionState) {
	NSLog(@"interruptionListenerCallback");
}

- (void) audioSessionStuff{
	
	OSStatus result = AudioSessionInitialize (CFRunLoopGetCurrent (), kCFRunLoopCommonModes,interruptionListenerCallback,self);
	if (result) printf("ERROR AudioSessionInitialize!\n");
        
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRootChanged, self);
    
	UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord; 
	
    result = AudioSessionSetProperty (kAudioSessionProperty_AudioCategory, sizeof (sessionCategory),&sessionCategory);
	if (result) printf("ERROR AudioSessionSetProperty!\n");
    

    
    Float64 preferredSampleRate = [codec getRate]; // try and get the hardware to resample
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, sizeof(preferredSampleRate), &preferredSampleRate);
    
    Float32 preferredBufferSize = .020; // I'd like a 20ms buffer duration
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
    
    // *** Activate the Audio Session before asking for the "Current" properties ***
    AudioSessionSetActive(true);
    

    
    
    result =	AudioSessionSetActive (true); 
	if (result) printf("ERROR AudioSessionSetActive!\n");
    
    Float64 mHWSampleRate = 0.0;
    UInt32 size = sizeof(mHWSampleRate);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &mHWSampleRate);
    
    Float32 mHWBufferDuration = 0.0;

    size = sizeof(mHWBufferDuration);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &size, &mHWBufferDuration);
    
    NSLog(@" actual HW sample rate is %f and buffer duration is %f",(float)mHWSampleRate,mHWBufferDuration);
	/*UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker; 
	
    result =	 AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,                         
                                          sizeof (audioRouteOverride),
                                          &audioRouteOverride);
	if (result) printf("ERROR AudioSessionSetProperty!\n"); */
    
    
    
}

- (id) init {
    [super init];

    codecs = [[NSMutableDictionary alloc] init];
    id <CodecProtocol> ulaw = [[UlawCodec alloc] init];
    [codecs setObject:ulaw forKey:[ulaw getName]];
    id <CodecProtocol> gsm = [[GSM610Codec alloc] init];
    [codecs setObject:gsm forKey:[gsm getName]];
    id <CodecProtocol> g722 = [[G722Codec alloc] init];
    [codecs setObject:g722 forKey:[g722 getName]];
    id <CodecProtocol> speex8 = [[SpeexCodec alloc] init];
    [codecs setObject:speex8 forKey:[speex8 getName]];
    playing = NO;
    // add more codecs here....
    
    nextDue = 0;

    rcvdAudio = [[NSMutableDictionary alloc] init];
    rcvdLock = [[NSLock alloc ] init];
    sent = 0;
    return self;
}

- (NSArray *) listCodecs{
    return [codecs allKeys];
}

- (void) consumeWireData:(NSData*)data time:(NSInteger) stamp{
    [rcvdLock lock];
    NSNumber * so = [NSNumber numberWithInteger:stamp];
    if (firstWired == YES) {
        nextDue = stamp; // first ever
        NSLog(@"setting first due time of %d",stamp);
        firstWired = NO;
    }
    int cnt = [rcvdAudio count];
    if (cnt < 10) {
        [rcvdAudio setObject:data forKey:so];
    } else {
        NSLog(@"skipping rcvd data for %d",stamp);
    }
    //NSLog(@" adding rcv data for  %d",stamp);
    [rcvdLock unlock];
}

- (BOOL) isCodecSupported:(NSString *) codecname{
    id k = [codecs objectForKey:codecname];
    return (k != nil);
}
- (NSInteger) getSampleRateForCodec:(NSString *) codecname{
    NSInteger ret = -1;
    id  <CodecProtocol> k = [codecs objectForKey:codecname];
    if (k != nil){
        ret = [k getRate];
    }
    return ret;
}

- (id)mkBuffer:(BOOL) forPlay {
	AudioQueueBufferRef aqbr = NULL;
	AudioQueueBufferRef *aqbrp;
	aqbrp = &aqbr;
	NSValue * ret = nil;
	AudioQueueRef q = (forPlay == YES) ? playQ:recQ;
	int sz = aframeLen;
	OSStatus res = AudioQueueAllocateBuffer(q,sz,aqbrp);
	if (aqbr != NULL) {
		ret = [[NSValue alloc] initWithBytes:aqbrp objCType:@encode(void *) ];
	}
	aqbr->mUserData = (void *) ret;
	if (forPlay == NO){
		AudioQueueEnqueueBuffer (recQ,aqbr,0,NULL);
	} else {
//        [buffers addObject:ret];
        [self fillAudioBuff:aqbr withData:nil];
        AudioQueueEnqueueBuffer (playQ,aqbr,0,NULL);
    }
	return ret;
}

- (void) setUpPlay{
    AudioStreamBasicDescription asbd;
    
    asbd.mSampleRate = [codec getRate];
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    asbd.mFramesPerPacket =1;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel = 16;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame = asbd.mChannelsPerFrame * sizeof (SInt16);
    
    
    // output
    OSStatus res = AudioQueueNewOutput (&asbd,
                                        handleOutputBuffer,self,
                                        CFRunLoopGetCurrent (),
                                        kCFRunLoopCommonModes,
                                        0,&playQ);
    NSLog(@"Output AudioQueue =  %x" , (int) res);
    
    Float32 gain = 1.0;                                       
    // Optionally, allow user to override gain setting here
    res = AudioQueueSetParameter (playQ,kAudioQueueParam_Volume,gain);
    for (int i=0;i< MAXPBUFF;i++){
        [self mkBuffer:YES];
    }
}

- (void) setUpRec{
    AudioStreamBasicDescription asbd;

    asbd.mFormatID = kAudioFormatLinearPCM;
	asbd.mSampleRate = [codec getRate];
	asbd.mChannelsPerFrame = 1;
	asbd.mBitsPerChannel = 16; 
	asbd.mBytesPerPacket = asbd.mBytesPerFrame = asbd.mChannelsPerFrame * sizeof (SInt16);
	asbd.mFramesPerPacket = 1;
	asbd.mFormatFlags =kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
	OSStatus res = AudioQueueNewInput(&asbd, handleInputBuffer, self, CFRunLoopGetCurrent (), kCFRunLoopCommonModes, 0, &recQ);
	NSLog(@"Input AudioQueue =  %d" , (int)res);

	for (int i=0; i<MAXRBUFF; i++){
        [self mkBuffer:NO];
	}
    audioIn = [[NSMutableData alloc] initWithCapacity:aframeLen];
    wout = [[NSMutableData  alloc] initWithCapacity:160];
    ainLock = [[NSLock alloc] init];
	NSTimer *send  = [NSTimer timerWithTimeInterval:0.019 target:self selector:@selector(encodeAndSend) userInfo:nil repeats:YES];
	NSRunLoop *crl = [NSRunLoop currentRunLoop];
	[crl addTimer:send forMode:NSDefaultRunLoopMode];
}

- (void)spawnAudio {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // Do thread work here.
	if ([NSThread isMultiThreaded]){
		//[NSThread setThreadPriority:0.75];
        audioThread = [NSThread currentThread];
        NSLog(@"Audio thread Started");
	}
    [self audioSessionStuff ];
    [self setUpPlay];
    [self setUpRec];
    int res = AudioQueueStart(recQ, NULL);
    NSLog(@"Started RecQ %d" , (int)res);
    
    res = AudioQueueStart(playQ, NULL);
    NSLog(@"Started PlayQ %d" , (int)res);
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	[runLoop run];
    [pool release];
	[NSThread exit];
}

- (BOOL) setCodec:(NSString *) codecname{
    codec = [codecs objectForKey:codecname];
    if (codec != nil){
        aframeLen = 2* (frameIntervalMS * [codec getRate] )/1000;
        [self performSelectorInBackground:@selector(spawnAudio) withObject:nil];
    }
    NSLog(@"set codec to %@ - res = %@",codecname,((codec != nil)?@"Yes":@"NO"));
    return (codec != nil);
}



- (void) start{


}
- (void) stop{
    AudioQueueStop(recQ, NO);
    AudioQueueStop(playQ, NO);
    // do some cleanup here - including the thread....
}
- (void) setWireConsumer:(id <AudioDataConsumer>)w {
    wire = w; // this guy will take all  our data.
}

@end

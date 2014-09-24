//
//  PfhAudio.m
//  objiax
//
//  Created by Tim Panton on 14/05/2011.
//  Copyright 2011 phonefromhere.com. 
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

// Sections of this code come from phono (github/phono/phonSDK) with the following copyright

/*
 * Copyright 2011 Voxeo Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
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

#import "IAXNSLog.h"
#import "PfhAudio.h"
#import "UlawCodec.h"
#import "GSM610Codec.h"
#import "G722Codec.h"
#import "SpeexCodec.h"

#import <AVFoundation/AVFoundation.h>

static int frameIntervalMS = 20; 


@implementation PfhAudio


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
    // add more codecs here....
    
    playing = NO;
    muted = NO;
    currentDigitDuration = 0;
    //[self performSelectorInBackground:@selector(spawnAudio) withObject:nil];
    return self;
}

- (void) failTo: (NSString*) functionName withOSStatus: (OSStatus) stat {
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:stat userInfo:nil];
    IAXLog(LOGERROR ,@"Error in %@: %@", functionName, [error description]);
}

- (void) setSampleRate:(int) rate{
    AudioStreamBasicDescription asbd;
    memset(&asbd,0,sizeof(asbd));
    asbd.mSampleRate = rate;
    
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked ;
    asbd.mFramesPerPacket =1;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel = 16;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame = asbd.mChannelsPerFrame * sizeof (SInt16);
    OSStatus err = AudioUnitSetProperty(vioUnitSpeak, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, sizeof(asbd));
    if (err != 0) {
        [self failTo:@"kAudioUnitProperty_StreamFormat Speak" withOSStatus:err];
        return;
    }
    
    err = AudioUnitSetProperty(vioUnitMic, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, sizeof(asbd));
    if (err != 0) {
        [self failTo:@"kAudioUnitProperty_StreamFormat Mic"  withOSStatus:err];
        return;
    }
}

- (void) avAudioSessionStuff{
    NSError *setError = nil;

    // implicitly initializes your audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
   /*
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(audioRootChangedNote)
               name:AVAudioSessionRouteChangeNotification
             object:nil];
    */
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&setError ];
    if (setError){
        IAXLog(LOGERROR,@"setCategoryError");
        setError = nil;
    }
    
    [session setMode:AVAudioSessionModeVoiceChat error:&setError ];
    if (setError){
        IAXLog(LOGERROR,@"setModeError");
        setError = nil;
    }
	
    AVAudioSessionRouteDescription *avr = [session currentRoute];
    for(AVAudioSessionPortDescription *port in avr.outputs) {
        IAXLog(LOGDEBUG,@"AUDIO_OUTPUT IS NOW: %@",port.portType);
    }
    for(AVAudioSessionPortDescription *port in avr.inputs) {
        IAXLog(LOGDEBUG,@"AUDIO_INPUT IS NOW: %@",port.portType);
    }

        
    Float64 preferredSampleRate = [codec getRate]; // try and get the hardware to resample
    [session setPreferredSampleRate:preferredSampleRate error:&setError];
    if (setError){
        IAXLog(LOGERROR,@"setPreferredSampleRateError");
        setError = nil;
    }
    
    Float32 preferredBufferSize = .020; // I'd like a 20ms buffer duration
    [session setPreferredIOBufferDuration:preferredBufferSize error:&setError];
    if (setError){
        IAXLog(LOGERROR,@"setPreferredIOBufferDuration");
        setError = nil;
    }
    // *** Activate the Audio Session before asking for the "Current" properties ***
    [session setActive:true error:&setError];
    if (setError){
        IAXLog(LOGERROR,@"setActive");
        setError = nil;
    }
    
    IAXLog(LOGDEBUG,@" actual HW sample rate is %f and buffer duration is %f",(float)session.sampleRate, (float)session.IOBufferDuration);

    
    
    
}



- (NSArray *) listCodecs{
    return [codecs allKeys];
}

- (void) consumeWireData:(NSData*)data time:(NSInteger) stamp{
    if (stopped) {
        NSLog(@"Post call audio data ignored");
        return;
    }
    NSMutableData *din = [[NSMutableData alloc] initWithLength:aframeLen*2];
    if (data != nil){
        if (codec != nil) {
            [codec decode:data audioData:din];
        }
    } else {
        NSLog(@"Padding AudioQueue play buffer with empty buffer");
        memset([din mutableBytes],0,aframeLen*2);
    }
    int16_t *rp =  ringOut;
    int len = ringOutsz;
    int64_t put = putOut;
    if (firstOut) {
        firstOut = NO;
        put += ((MAXJITTER * aframeLen)/frameIntervalMS) ; // in effect insert some blank frames ahead of real data
    }
    int off = 0;
    NSInteger samples = aframeLen;
    int16_t *bp =  (int16_t *) [din mutableBytes];
    double energy = 0.0;
    for (UInt32 j=0;j< samples;j++){
        off = (put % len);
        rp[off] = bp[j];
        put++;
        energy = energy + ABS(bp[j]);
    }
    outEnergy = energy / samples;
    
    [din release];
    long diff = (stamp -ostamp);
    
    if ((diff < 0) && (diff > -2000)){
        NSLog(@"out of order %d > %d",ostamp , stamp);
    }
    if ((diff > 20) && (diff < 2000)) {
        NSLog(@"Missing packet ? %d -> %d",ostamp , stamp);
    }
    ostamp = stamp;
    putOut = put;
    // NSLog(@"put = %d get=%qd put=%qd last took = %qd avail = %qd wanted %ld",aframeLen,getOut,putOut, getOut-getOutold , putOut - getOut, wanted );
    getOutold = getOut;
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

static OSStatus inRender(
                         void *							inRefCon,
                         AudioUnitRenderActionFlags *	ioActionFlags,
                         const AudioTimeStamp *			inTimeStamp,
                         UInt32							inBusNumber,
                         UInt32							inNumberFrames,
                         AudioBufferList *				ioData){
    
    PfhAudio *myself = (PfhAudio *) inRefCon;
    OSStatus err =0;
    
    
    AudioBufferList abl;
    abl.mNumberBuffers = 1;
    abl.mBuffers[0].mNumberChannels = 1;
    abl.mBuffers[0].mData = myself->inslop;
    abl.mBuffers[0].mDataByteSize = ((inNumberFrames > ENOUGH) ? ENOUGH: inNumberFrames)*2;
    ioData = &abl;
    err = AudioUnitRender(myself->vioUnitMic, ioActionFlags, inTimeStamp,1 , inNumberFrames, ioData);
    if (err) { printf("inRender: error %d\n", (int)err); return err; }
    
    int16_t *rp = myself->ringIn;
    int len = myself->ringInsz;
    int64_t put = myself->putIn;
    int off = 0;
    for(UInt32 i = 0; i < ioData->mNumberBuffers; ++i){
        NSInteger samples = ioData->mBuffers[i].mDataByteSize / 2;
        int16_t *bp = (int16_t *) ioData->mBuffers[i].mData;
        for (UInt32 j=0;j< samples;j++){
            off = (put % len);
            rp[off] = bp[j];
            put++;
        }
    }
    myself->putIn = put;
    return err;
}

uint32_t toneMap[120][2] = {{1336,941},{1209,697},{1336,697},{1477,696},{1209,770},{1336,770},{1477,770},{1209,852},{1336,852},{1447,852},{1209,941},{1477,941}};

uint16_t getDigitSample(char digit, uint64_t position, uint64_t rate) {
    float n1 = (2*M_PI) * toneMap[digit][0] / rate;
    float n2 = (2*M_PI) * toneMap[digit][1] / rate;
    return ((sin(position*n1) + sin(position*n2))/4)*32768;
}

static OSStatus outRender(
                          void *							inRefCon,
                          AudioUnitRenderActionFlags *	ioActionFlags,
                          const AudioTimeStamp *			inTimeStamp,
                          UInt32							inBusNumber,
                          UInt32							inNumberFrames,
                          AudioBufferList *				ioData){
    PfhAudio *myself = (PfhAudio *) inRefCon;
    int64_t get = myself->getOut;
    int64_t put = myself->putOut;
    if ((put - get) < inNumberFrames) {
        memset((void *) ioData->mBuffers[0].mData,0,ioData->mBuffers[0].mDataByteSize);
        NSLog(@" No data to be sent to speaker - filling with silence %qd %qd",get,put);
        
    } else {
        int len = myself ->ringOutsz;
        int off = 0;
        int16_t *rp = myself->ringOut;
        
        int i=0;
        NSInteger samples = ioData->mBuffers[i].mDataByteSize / 2;
        uint16_t *bp = (uint16_t *) ioData->mBuffers[i].mData;
        for (UInt32 j=0;j< samples;j++){
            off = (get % len);
            if (myself->currentDigitDuration > 0) {
                bp[j] = getDigitSample(myself->currentDigit, get, [myself->codec getRate]) + rp[off]/2;
                myself->currentDigitDuration-=1;
            }
            else bp[j] = rp[off];
            get++;
            //if (get > target) break;
        }
        myself ->wanted = inNumberFrames;
        //NSLog(@" data sent to speaker %d",samples);

        if (inNumberFrames != (get -  myself->getOut)){
            NSLog(@" out problem with counting %ld != %qd", inNumberFrames , (get -  myself->getOut));
        }
        if (ioData->mNumberBuffers != 1){
            NSLog(@" out problem with number of buffers %ld", ioData->mNumberBuffers);
            
        }
        myself->getOut = get;
        
    }
    
    return 0;
}




- (void) setUpAU{
    OSStatus err =0;
    // configure audio unit here
    AudioComponentDescription ioUnitDescription;
    inRenderProc.inputProc = inRender;
    inRenderProc.inputProcRefCon = self;
    outRenderProc.inputProc = outRender;
    outRenderProc.inputProcRefCon = self;
    memset(&ioUnitDescription,0,sizeof(ioUnitDescription));
    
    
    ioUnitDescription.componentType          = kAudioUnitType_Output;
    ioUnitDescription.componentSubType       = kAudioUnitSubType_VoiceProcessingIO ;
    ioUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags         = 0;
    ioUnitDescription.componentFlagsMask     = 0;
    
    AudioComponent foundIoUnitReference = AudioComponentFindNext (
                                                                  NULL,
                                                                  &ioUnitDescription
                                                                  );
    
    err = AudioComponentInstanceNew (foundIoUnitReference,&vioUnitSpeak);
    if (err != 0) { NSLog(@"Error with %@ - %ld",@"AudioComponentInstanceNew",err); return;}
    memcpy (&vioUnitMic,&vioUnitSpeak,sizeof(vioUnitSpeak));
    
    /*err = AudioComponentInstanceNew (foundIoUnitReference,&vioUnitMic);
     if (err != 0) { NSLog(@"Error with %@ - %ld",@"AudioComponentInstanceNew",err); return;}
     */
    
    
    
    UInt32 one = 1;
    err = AudioUnitSetProperty(vioUnitMic, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    if (err != 0) { NSLog(@"Error with %@ - %ld",@"kAudioOutputUnitProperty_EnableIO mic",err); return;}
    
    err = AudioUnitSetProperty(vioUnitSpeak, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    if (err != 0) { NSLog(@"Error with %@ - %ld",@"kAudioOutputUnitProperty_EnableIO speak",err); return;}
    
    
    err = AudioUnitSetProperty(vioUnitSpeak, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Output, 0, &outRenderProc, sizeof(outRenderProc));
    if (err != 0) { NSLog(@"Error with %@ - %ld",@"kAudioUnitProperty_SetRenderCallback Speak",err); return;}
    
    err = AudioUnitSetProperty(vioUnitMic, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &inRenderProc, sizeof(inRenderProc));
    if (err != 0) { NSLog(@"Error with %@ - %ld",@"kAudioUnitProperty_SetRenderCallback Mic",err); return;}
    
    [self setSampleRate:8000];

    
    
    
    
    err = AudioUnitInitialize(vioUnitSpeak);
    if (err != 0) {
        [self failTo:@"AudioUnitInitialize "  withOSStatus:err];
    }
    
}


- (void) setUpSendTimer{
    send  = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(encodeAndSend) userInfo:nil repeats:YES];
    [audioRunLoop addTimer:send forMode:NSDefaultRunLoopMode];
}
- (void) setUpRingBuffers{
    ringInsz = ENOUGH;
    putIn =0;
    getIn =0;
    
    ringOutsz =ENOUGH;
    putOut =0;
    firstOut = YES;// start with some headroom (silent)
    getOut =0;
    getOutold =0;
}

- (void) setupAudio {
    [self setUpAU];
    [self avAudioSessionStuff ];
    [self setUpRingBuffers];
    [self setUpSendTimer];
}
- (void)spawnAudio {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // Do thread work here.
    if ([NSThread isMultiThreaded]){
        [NSThread setThreadPriority:1.0];
        audioThread = [NSThread currentThread];
        NSLog(@"Audio thread Started");
    }
    audioRunLoop = [NSRunLoop currentRunLoop];
    wout = [[NSMutableData  alloc] initWithCapacity:160]; // we put the wire data here before sending it.
    [self setupAudio];
    [audioRunLoop run];
    [pool release];
    [NSThread exit];
}
-(void) encodeAndSend{
    
    if (stopped) return;
    
    int64_t get = getIn;
    int64_t avail  = putIn - get;
    //NSLog(@"avail = %qd",avail);
    int64_t count = 0;
    if (avail >= aframeLen) {
        // got enough to send a packet
        //NSLog(@"taken = %d get=%qd put=%qd count=%qd",aframeLen,getIn,putIn,count );
        //count++;
        
        NSData * dts = nil ;
        if (muted) {
            uint8_t *zeros = alloca(aframeLen*2);
            memset(zeros,0,aframeLen*2);
            dts = [NSData dataWithBytes:zeros length:aframeLen*2];
            get += aframeLen;
        } else {
            int16_t *audio = alloca(aframeLen*2);
            int len = ringInsz;
            double energy = 0.0;
            for (int i=0;i<aframeLen;i++){
                int offs = get % len;
                audio[i] = ringIn[offs];
                energy += ABS(ringIn[offs]);
                get++;
            }
            inEnergy = energy / aframeLen;
            dts = [NSData dataWithBytes:audio length:aframeLen*2];
        }
        [codec encode:dts  wireData:wout];
        [wire consumeAudioData:wout time:(sent*frameIntervalMS)];
        sent++;
        getIn =  get;
        avail  = putIn - get;
    }
}

- (BOOL) setCodec:(NSString *) codecname{
    codec = [codecs objectForKey:codecname];
    if (codec != nil){
        aframeLen = (frameIntervalMS * [codec getRate] )/1000;
        [self performSelectorInBackground:@selector(spawnAudio) withObject:nil];
    }
    IAXLog(LOGINFO,@"set codec to %@ - res = %@",codecname,((codec != nil)?@"Yes":@"NO"));
    return (codec != nil);
}


- (void) start{
    OSStatus err =0;
    memset(inslop,0,sizeof(inslop));
    memset(ringIn,0,sizeof(ringIn));
    memset(ringOut,0,sizeof(ringOut));
    
    err = AudioOutputUnitStart(vioUnitSpeak);
    if (err != 0) { NSLog(@"Error with %@ - %ld",@"AudioOutputUnitStart Speak",err);}
    stopped = NO;
}


- (void) stop{
    OSStatus err =0;
    
    //AudioOutputUnitStop(vioUnitMic);
    err =  AudioOutputUnitStop(vioUnitSpeak);
    if (err != 0) { NSLog(@"Error with %@ - %ld",@"AudioOutputUnitStop Speak",err);}
    
    stopped = YES;
}
- (void) setWireConsumer:(id <AudioDataConsumer>)w {
    wire = w; // this guy will take all  our data.
}
- (void)dealloc {
    [codecs removeAllObjects];
    [codecs release];
    [audioThread release];
    [self stop];
    AudioComponentInstanceDispose(vioUnitSpeak);
    [super dealloc];
}
@end

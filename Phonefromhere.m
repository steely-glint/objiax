//

//
//  Created by Tim Panton on 28/02/2010.
//
#import <Security/Security.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>

#import "Phonefromhere.h"

@implementation Phonefromhere
@synthesize host, port, version;

- init {
    self = [super init];
    if (self) {
        calls = [[NSMutableDictionary alloc] init];
        audios = [[NSMutableDictionary alloc] init];
        version = @"1.3 12/12/2011";
    }
    return self;
}


- (void) getDatagram: (NSData *) frame{
    //NSLog(@"data arrived %d",[frame length]) ;
    IAXFrameIn *got = [IAXFrameIn alloc];
    [got setFrameData:frame];
    IAXCall *call = nil;
    if ([got isMiniFrame]){
        call = [audios objectForKey:[NSNumber numberWithInteger:[got getSourceCall]]];
        if (call != nil){
            [call rcv:got];
        }else {
            [got dumpFrame: @"disowned mini frame:"];
        }
        
    } else {
        call = [calls objectForKey:[NSNumber numberWithInteger:[got getDestinationCall]]];
        if (call != nil){
            [call rcv:got];
        } else {
            [got dumpFrame: @"disowned full frame:"];
        }
    }
    [got release];
}

/*void socketCallback (
                 CFSocketRef s,
                 CFSocketCallBackType callbackType,
                 CFDataRef address,
                 const void *data,
                 void *info
                 ){
    id me = (id) info;
    [me getDatagram:(NSData *)data];
}
*/
- (void)retryTime:(NSTimer *)timer {
    NSArray * cas = [calls allValues];
    for (IAXCall * c in cas){
        [c offerRetry];
    }
}

- (void)rcvLoop{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	IAXLog(LOGDEBUG,@"in rcv thread");
    uint8_t *rcvbuff;
    NSMutableData *rb = [NSMutableData dataWithLength:1024]; 
    NSTimeInterval ntv = 0.01;
    while (ipv4Soc > 0){
        [rb setLength:1024];
        rcvbuff = [rb mutableBytes];
        int got = recv(ipv4Soc,rcvbuff,1024,0);
        if (got > 4) {
            //NSLog(@"datagram of size %d",got);

            [rb setLength:got];
            [self getDatagram:rb];
        } 
        [NSThread sleepForTimeInterval:ntv];
    }
    [pool release];
}

- (BOOL)start {
    
    struct hostent *h;
    struct sockaddr_in sock_addr ;
    CFSocketNativeHandle sock ;
    
    
    memset(&sock_addr, 0, sizeof(sock_addr));
    
    h = gethostbyname([host UTF8String]);
    memcpy(&sock_addr.sin_addr.s_addr, h->h_addr, sizeof(struct in_addr));
    
    sock_addr.sin_family = AF_INET;
    /* port number we want to connect to */
    sock_addr.sin_port = htons(port);
    sock_addr.sin_len = sizeof(sock_addr);
    /* Create our socket */
    if ( ( sock = socket(AF_INET, SOCK_DGRAM,0)) < 0 )
    {
        IAXLog(LOGERROR,@"socket failed") ;
        //perror("socket");
    } else {
        IAXLog(LOGDEBUG,@"socket created") ;
        
        if (0 == (connect(sock, (struct sockaddr *)&sock_addr,sizeof(sock_addr)))){
            IAXLog(LOGDEBUG,@"socket connected to host %@ at %d ",host,port) ;
            ipv4Soc = sock;
            struct timeval tv;
            tv.tv_sec = 0;
            tv.tv_usec = 5000; // 5ms 
            setsockopt(ipv4Soc,SOL_SOCKET,SO_RCVTIMEO,&tv, sizeof(tv));
        } else {
            IAXLog(LOGERROR,@"connect failed to host %@ at %d ",host,port) ;
        }
    }	

    // spawn rcv thread here .....
    rcvThread = [[NSThread alloc] initWithTarget:self selector:@selector(rcvLoop) object:nil];
	[rcvThread setName:@"iax2-rcv"];
	[rcvThread start];
    NSRunLoop * crl ;
	NSTimer * tick;

	
	tick = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(retryTime:) userInfo:nil repeats:YES];
    
	crl = [NSRunLoop currentRunLoop];
	[crl addTimer:tick forMode:NSDefaultRunLoopMode];
    return YES;
}
/*
- (void)spawn {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    calls = [[NSMutableDictionary alloc] init];
    audios = [[NSMutableDictionary alloc] init];

    // Do thread work here.
	if ([NSThread isMultiThreaded]){
		//[NSThread setThreadPriority:0.75];
        netThread = [NSThread currentThread];
	}
    [self start];
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	[runLoop run];
    [pool release];
	[NSThread exit];
}
*/
- (void) startIAX{
    [self start];
	//[self performSelectorInBackground:@selector(start) withObject:nil];
}

- (void) addAudioCall:(id) icall{
    IAXCall * call = (IAXCall *)icall;
    [audios setObject:call forKey:[NSNumber numberWithInteger:[call destNo]]];
    IAXLog(LOGDEBUG,@"Adding call with destNo of %d ",[call destNo]) ;
}

- (void) doCall:(id) icall{
    IAXCall * call = (IAXCall *)icall;
    //[calls insertObject:call atIndex:[call srcNo]];
    [calls setObject:call forKey:[NSNumber numberWithInteger:[call srcNo]]];
    IAXLog(LOGDEBUG,@"Adding call with srcNo of %d ",[call srcNo]) ;

    [call sendNew];
}

- (BOOL) sendFrame: (IAXFrameOut *) frame {
    NSData *nsd = [frame getFrameData];
    /*CFTimeInterval timeout = 0.001; // 1ms max this is UDP after all
    
    CFSocketError e = CFSocketSendData (ipv4socket, NULL,(CFDataRef)nsd, timeout);


     */
    int e = send(ipv4Soc,[nsd bytes],[nsd length],0);
    
    //NSLog(@"sending frame of %d ",[nsd length]) ;

    return (e ==[nsd length])?YES:NO  ;
}

- (void)hungupCall: (IAXCall *)call cause:(NSString *)reason code:(NSNumber *)code {
    [calls removeObjectForKey:[NSNumber numberWithInteger:[call srcNo]]];
    IAXLog(LOGDEBUG,@"Call %d hung up because : %@ (%d)\n",[call srcNo],reason,code) ;
    [call cleanUp];
}
// main loop thread callable

- (uint16_t) mkCallNo{
    uint16_t cn;
    SecRandomCopyBytes (kSecRandomDefault,sizeof(cn),(uint8_t *)&cn);
    cn &= 0x7fff;
    // should really test this doesn't exist - but since we only support a single call
    // at the moment I don't care.
    return cn;
}

- (void) callZero{
    IAXCall * call = [IAXCall alloc];
    [call initQ];
    [call setSrcNo:0];
    [call setRunner:self];
    [calls setObject:call forKey:[NSNumber numberWithInteger:[call srcNo]]];
    IAXLog(LOGERROR,@"Adding call with srcNo of %d ",[call srcNo]) ;
}

- (IAXCall *) newCall:(NSString *)user pass:(NSString *)pass exten:(NSString *)exten forceCodec:(NSString *)codec statusListener:(id<callStatusListener>)statusListener {
    IAXCall * call = [IAXCall alloc];
    [call setSrcNo:[self mkCallNo]];
    [call setCodecName:codec];
    [call initQ];
    [call setUser:user];
    [call setPass:pass];
    [call setCalledNo:exten];
    [call setCallerID:@"TimPantonOnIos"];
    [call setCallingNo:@"TimPantonOnIos"];
    [call setStatusListener:statusListener];
    [call setRunner:self];
    //[self performSelector:@selector(doCall:) onThread:netThread withObject:call waitUntilDone:(BOOL)true];
    [self doCall:call];
    return call;
}
-(void) stopIAX{
    if (ipv4Soc > 0){
        close(ipv4Soc);
        ipv4Soc = -1;
    }
}
-(void) dealloc{
    
    [calls release];
    [audios release];
    [super dealloc];
}
@end

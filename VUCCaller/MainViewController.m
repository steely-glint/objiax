//
//  MainViewController.m
//  VUCCaller
//
//  Created by Tim Panton on 11/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    log = [[NSMutableString alloc] init ];
    nsr = [[Phonefromhere alloc] init];
    call = nil;
    //[nsr setHost: @"ss10.westhawk.co.uk"];
    [nsr setHost: @"api.phonefromhere.com"];

    [nsr setPort: 4569];
    [nsr startIAX];
    [self addText: @"started \n"];
}

- (void) addText:(NSString *) mess 
{
    [log appendString:mess];
    
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{    
    FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    controller.delegate = self;
    
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
    
    [controller release];
}



- (IBAction)pushBut{  
    if (call == nil){
        //call = [nsr newCall:@"android" pass:@"marvin" exten:@"4000" statusListener:self];

        //call = [nsr newCall:@"android" pass:@"marvin" exten:@"2000" statusListener:self];
        call = [nsr newCall:@"zdx" pass:@"showboat" exten:@"200901" statusListener:self];
        //[nsr newCall:@"iosTest" pass:@"spreektotmij" exten:@"200901" statusListener:self];


    } else {
        [call hangup];
    }
}

- (IBAction)mute{  
    if (call != nil){
        [call sendDtmf:@"*6*"];
    }
}
- (IBAction)pinSend{  
    if (call != nil){
        [call sendDtmf:@"74666#"];
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [super dealloc];
}
- (void) recvdDTMF:(char) dtmf{
    
}

- (void) lRecvdText:(NSString *)mess{
    NSString *bo = [bodyText text];
    NSMutableString *nbo = [NSMutableString stringWithString:bo];
    [nbo appendString:@"\n"];
    [nbo appendFormat:@"%@",mess];
    [bodyText setText:nbo];
}
- (void) recvdText:(NSString *)mess{
    [self performSelectorOnMainThread:@selector(lRecvdText:) withObject:mess waitUntilDone:NO];
}
- (void) showStatusChanged:(NSString *) detail{
    if (call != nil) {        
        NSInteger state = [call state];
        NSLog(@"Status change to %d - detail is %@",state,detail);
        switch (state) {
            case kIAXCallStateINITIAL:
                [botBut setEnabled:YES];
                [botBut setTitle:@"Call" forState:UIControlStateNormal];
                [botBut setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
                call = nil ; // that was a hangup of some sort
                break;
            case kIAXCallStateWAITING:
                [botBut setEnabled:NO];

                [botBut setTitle:@"Calling" forState:UIControlStateNormal];
                [botBut setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
                break;      
            case kIAXCallStateLINKED:
                [botBut setEnabled:YES];

                [botBut setTitle:@"Stop Ringing" forState:UIControlStateNormal];
                [botBut setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                break;     
            case kIAXCallStateUP:
                [botBut setEnabled:YES];

                [botBut setTitle:@"Hangup" forState:UIControlStateNormal];
                [botBut setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                break;   
        }
    }
    if (detail != nil){
        [topLabel setText:detail];
    }
}

- (void) callStatusChanged:(NSString *) detail{

    [self performSelectorOnMainThread:@selector(showStatusChanged:) withObject:detail waitUntilDone:NO];
  
    
}
@end

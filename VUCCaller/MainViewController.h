//
//  MainViewController.h
//  VUCCaller
//
//  Created by Tim Panton on 11/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import "FlipsideViewController.h"
#import "Phonefromhere.h"
#import "IAXCall.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate ,callStatusListener> {
    IBOutlet id topLabel;
    IBOutlet id bodyText;
    IBOutlet id botBut;
    NSMutableString *log;
    Phonefromhere *nsr;
    id call;
}


- (IBAction)showInfo:(id)sender;
- (IBAction)pushBut;
- (void) addText:(NSString *) mess;
- (IBAction)mute;
- (IBAction)pinSend;  

@end

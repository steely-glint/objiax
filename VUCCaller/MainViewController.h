//
//  MainViewController.h
//  VUCCaller
//
//  Created by Tim Panton on 11/05/2011.
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

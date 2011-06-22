//
//  FlipsideViewController.m
//  VUCCaller
//
//  Created by Tim Panton on 11/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import "FlipsideViewController.h"
#import "IAXNSLog.h"

@implementation FlipsideViewController

@synthesize delegate=_delegate;

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];  
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://vuc.me"]];
    [webView loadRequest:request];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

// UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    IAXLog(LOGDEBUG,@"about to load %@",[[request URL] absoluteString]);
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView{
    IAXLog(LOGDEBUG,@"Loading ");
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    IAXLog(LOGDEBUG,@"Loaded ");

    
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    IAXLog(LOGDEBUG,@"Failed with %d ",[error code]);

}

@end

//
//  MadServeDemoAdvViewController.m
//  MadServeDemoAdv
//
//  Created by Oliver Drobnik on 9/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MadServeDemoAdvViewController.h"

@implementation MadServeDemoAdvViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// create the banner view just outside of the visible area
	MadServeBannerView *bannerView = [[MadServeBannerView alloc] initWithFrame:CGRectZero]; // size does not matter yet
	bannerView.delegate = self;  // triggers ad loading
	bannerView.backgroundColor = [UIColor darkGrayColor]; // fill horizontally
	bannerView.refreshAnimation = UIViewAnimationTransitionCurlDown;
	[self.view addSubview:bannerView];
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark MadServe Delegate

- (NSURL *)apiURLForMadServeBannerView:(MadServeBannerView *)banner
{
	return [NSURL URLWithString:@"http://your.server.com/mad.request.php"];
}

- (NSString *)publisherIdForMadServeBannerView:(MadServeBannerView *)banner
{
	return @"YOUR_PUBLISHER_ID";
}

- (void)MadServeBannerViewDidLoadMadServeAd:(MadServeBannerView *)banner
{
	NSLog(@"MadServe: did load ad");

	// enlarge banner to fit width, preserve height
	banner.bounds = CGRectMake(0, 0, self.view.bounds.size.width, banner.bounds.size.height);
	
	// move banner to be at bottom of screen
	banner.center = CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height - banner.bounds.size.height/2.0);
	
	// set transform to be outside of screen
	banner.transform = CGAffineTransformMakeTranslation(0, banner.bounds.size.height);
	
	// animate banner into view
	[UIView beginAnimations:@"MadServe" context:nil];
	[UIView setAnimationDuration:1];
	banner.transform = CGAffineTransformIdentity;
	[UIView commitAnimations];
}

- (void)MadServeBannerView:(MadServeBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	NSLog(@"MadServe: did fail to load ad: %@", [error localizedDescription]);

	// move banner to be at bottom of screen
	banner.center = CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height - banner.bounds.size.height/2.0);
	
	// animate banner outside view
	[UIView beginAnimations:@"MadServe" context:nil];
	[UIView setAnimationDuration:1];
	
	banner.transform = CGAffineTransformMakeTranslation(0, banner.bounds.size.height);
	
	[UIView commitAnimations];
}


@end

//
//  MadServeBannerView.m
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "MadServeBannerView.h"
#import "NSString+MadServe.h"
#import "DTXMLDocument.h"
#import "DTXMLElement.h"
#import "UIView+FindViewController.h"
#import "NSURL+MadServe.h"
#import "MadServeAdBrowserViewController.h"
#import "RedirectChecker.h"


NSString * const MadServeErrorDomain = @"MadServe";


@interface MadServeBannerView () // private

- (void)requestAd;

@property (nonatomic, retain) NSURL *apiURL;

@end




@implementation MadServeBannerView

- (void)setup
{
	self.autoresizingMask = UIViewAutoresizingNone;
	self.backgroundColor = [UIColor clearColor];
	
	refreshAnimation = UIViewAnimationTransitionFlipFromLeft;
	
	// need notification to activate/deactivate timer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
		[self setup];
    }
    return self;
}

- (void)awakeFromNib
{
	[self setup];
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_refreshTimer invalidate], _refreshTimer = nil;
	[_bannerImage release];
	[_tapThroughURL release];
	[advertisingSection release];
	
	[_apiURL release];
	
    [super dealloc];
}

#pragma mark Utilities

- (NSString *)userAgent
{
	NSString *device = [UIDevice currentDevice].model;
	NSString *agent = @"MadServe";
	
	return [NSString stringWithFormat:@"%@/%@ (%@)", agent, SDK_VERSION, device];
}

- (UIImage*)darkeningImageOfSize:(CGSize)size
{
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGContextSetGrayFillColor(ctx, 0, 1);
	CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
	
	UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
	
	//pop the context to get back to the default
	UIGraphicsEndImageContext();
	
	//Note: this is autoreleased
	return cropped;
}

- (NSURL *)serverURL
{
	if (!_apiURL)
	{
		self.apiURL = [delegate apiURLForMadServeBannerView:self];
	}
	
	return _apiURL;
}

#pragma mark Properties
- (void)setBounds:(CGRect)bounds
{
	[super setBounds:bounds];
	
	for (UIView *oneView in self.subviews)
	{
		oneView.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
	}
}

- (void)setTransform:(CGAffineTransform)transform
{
	[super setTransform:transform];
	
	for (UIView *oneView in self.subviews)
	{
		oneView.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
	}
}

- (void)setDelegate:(id <MadServeBannerViewDelegate>)newDelegate
{
	if (newDelegate != delegate)
	{
		delegate = newDelegate;
		
		if (delegate)
		{
			[self requestAd];
		}
	}
}

- (void)setRefreshTimerActive:(BOOL)active
{
	BOOL currentlyActive = (_refreshTimer!=nil);
	
	if (active == currentlyActive)
	{
		return;
	}
	
	if (active && !bannerViewActionInProgress)
	{
		if (_refreshInterval)
		{
			_refreshTimer = [NSTimer scheduledTimerWithTimeInterval:_refreshInterval target:self selector:@selector(requestAd) userInfo:nil repeats:YES];
		}
	}
	else 
	{
		[_refreshTimer invalidate], _refreshTimer = nil;
	}
}

- (void)hideStatusBar
{
	UIApplication *app = [UIApplication sharedApplication];
	
	if (!app.statusBarHidden)
	{
		if ([app respondsToSelector:@selector(setStatusBarHidden:withAnimation:)])
		{
			// >= 3.2
			[app setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		}
		else 
		{
			// < 3.2
			[app setStatusBarHidden:YES];
		}
		
		_statusBarWasVisible = YES;
	}
}

- (void)showStatusBarIfNecessary
{
	if (_statusBarWasVisible)
	{
		UIApplication *app = [UIApplication sharedApplication];
		
		if ([app respondsToSelector:@selector(setStatusBarHidden:withAnimation:)])
		{
			// >= 3.2
			[app setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
		}
		else 
		{
			// < 3.2
			[app setStatusBarHidden:NO];
		}
	}
}

#pragma mark Ad Handling
- (void)reportSuccess
{
	bannerLoaded = YES;
	
	if ([delegate respondsToSelector:@selector(MadServeBannerViewDidLoadMadServeAd:)])
	{
		[delegate MadServeBannerViewDidLoadMadServeAd:self];
	}
}

- (void)reportError:(NSError *)error
{
	bannerLoaded = NO;
	
	if ([delegate respondsToSelector:@selector(MadServeBannerView:didFailToReceiveAdWithError:)])
	{
		[delegate MadServeBannerView:self didFailToReceiveAdWithError:error];
	}
}

- (void)setupAdFromXml:(DTXMLDocument *)xml
{
	
	if ([xml.documentRoot.name isEqualToString:@"error"])
	{
		NSString *errorMsg = xml.documentRoot.text;
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MadServeErrorDomain code:MadServeErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;	
	}
	
	
	// previous views will be removed if setup works
	NSArray *previousSubviews = [NSArray arrayWithArray:self.subviews];
	
	NSString *clickType = [xml.documentRoot getNamedChild:@"clicktype"].text;
	
	if ([clickType isEqualToString:@"inapp"])
	{
		_tapThroughLeavesApp = NO;
	}
	else
	{
		_tapThroughLeavesApp = YES;
	}
	
	NSString *clickUrlString = [xml.documentRoot getNamedChild:@"clickurl"].text;
	if ([clickUrlString length])
	{
		[_tapThroughURL release];
		_tapThroughURL = [[NSURL URLWithString:clickUrlString] retain];
	}
	
	_shouldScaleWebView = [[xml.documentRoot getNamedChild:@"scale"].text isEqualToString:@"yes"];
	
	_shouldSkipLinkPreflight = [[xml.documentRoot getNamedChild:@"skippreflight"].text isEqualToString:@"yes"];
	
	UIView *newAdView = nil;
	
	NSString *adType = [xml.documentRoot.attributes objectForKey:@"type"];
	
	if ([adType isEqualToString:@"imageAd"]) 
	{
		if (!_bannerImage)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error loading banner image" forKey:NSLocalizedDescriptionKey];
			
			NSError *error = [NSError errorWithDomain:MadServeErrorDomain code:MadServeErrorUnknown userInfo:userInfo];
			[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
			return;
		}
		
		CGFloat bannerWidth = [[xml.documentRoot getNamedChild:@"bannerwidth"].text floatValue];
		CGFloat bannerHeight = [[xml.documentRoot getNamedChild:@"bannerheight"].text floatValue];
		
		UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(0, 0, bannerWidth, bannerHeight)];
		[button addTarget:self action:@selector(tapThrough:) forControlEvents:UIControlEventTouchUpInside];
		
		[button setImage:_bannerImage forState:UIControlStateNormal];
		button.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
		//		button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		
		newAdView = button;
	}
	else if ([adType isEqualToString:@"textAd"]) 
	{
		NSString *html = [xml.documentRoot getNamedChild:@"htmlString"].text;
		
		CGSize bannerSize = CGSizeMake(320, 50);
		if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
		{
			bannerSize = CGSizeMake(728, 90);
		}
		
		UIWebView *webView=[[[UIWebView alloc]initWithFrame:CGRectMake(0, 0, bannerSize.width, bannerSize.height)] autorelease];
		webView.delegate = (id)self;
		webView.userInteractionEnabled = NO;
		
		[webView loadHTMLString:html baseURL:nil];
		
		
		// add an invisible button for the whole area
		UIImage *grayingImage = [self darkeningImageOfSize:bannerSize];
		
		UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:webView.bounds];
		[button addTarget:self action:@selector(tapThrough:) forControlEvents:UIControlEventTouchUpInside];
		[button setImage:grayingImage forState:UIControlStateHighlighted];
		button.alpha = 0.47;
		
		button.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
		//		button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		
		[self addSubview:button];
		
		// we want the webview to be translucent so that we see the developer's custom background
		webView.backgroundColor = [UIColor clearColor];
		webView.opaque = NO;
		
		newAdView = webView;
	} 
	else if ([adType isEqualToString:@"noAd"]) 
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No inventory for ad request" forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MadServeErrorDomain code:MadServeErrorInventoryUnavailable userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
	}
	else if ([adType isEqualToString:@"error"])
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MadServeErrorDomain code:MadServeErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	else 
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unknown ad type '%@'", adType] forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MadServeErrorDomain code:MadServeErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	
	if (newAdView)
	{
		if (CGRectEqualToRect(self.bounds, CGRectZero))
		{
			self.bounds = newAdView.bounds;
		}
		
		// animate if there was a previous ad
		
		if ([previousSubviews count])
		{
			[UIView beginAnimations:@"flip" context:nil];
			[UIView setAnimationDuration:1.5];
			[UIView setAnimationTransition:refreshAnimation forView:self cache:NO];
		}
		
		[self insertSubview:newAdView atIndex:0]; // goes below button
		[previousSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
		
		if ([previousSubviews count])
		{
			[UIView commitAnimations];
		}
		else 
		{
			// only inform delegate if its not a refresh
			[self performSelectorOnMainThread:@selector(reportSuccess) withObject:nil waitUntilDone:YES];
		}
	}		
	
	// start new timer
	_refreshInterval = [[xml.documentRoot getNamedChild:@"refresh"].text intValue];
	[self setRefreshTimerActive:YES];
}

- (void)asyncRequestAdWithPublisherId:(NSString *)publisherId
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc]init];
	
	NSString *requestType;
	if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
	{
		requestType = @"iphone_app";
	}
	else
	{
		requestType = @"ipad_app";
	}
	
	NSString *userAgent=[self userAgent];
	NSString *m=@"live";
	NSString *osVersion = [UIDevice currentDevice].systemVersion;
	
	NSString *cookieId = [[UIDevice currentDevice].uniqueIdentifier md5];
	
	NSString *requestString=[NSString stringWithFormat:@"rt=%@&u=%@&o=%@&v=%@&m=%@&s=%@&iphone_osversion=%@&spot_id=%@",
							 [requestType stringByUrlEncoding],
							 [[self userAgent] stringByUrlEncoding],
							 [cookieId stringByUrlEncoding],
							 [SDK_VERSION stringByUrlEncoding],
							 [m stringByUrlEncoding],
							 [publisherId stringByUrlEncoding],
							 [osVersion stringByUrlEncoding],
							 [advertisingSection?advertisingSection:@"" stringByUrlEncoding]];
	
	NSURL *serverURL = [self serverURL];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", serverURL, requestString]];
	
	NSMutableURLRequest *request;
	NSError *error;
    NSURLResponse *response;
    NSData *dataReply;
	
    request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod: @"GET"];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Accept"];
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
	
	dataReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	DTXMLDocument *xml = [DTXMLDocument documentWithData:dataReply];
	
	if (!xml)
	{		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error parsing xml response from server" forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MadServeErrorDomain code:MadServeErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	
	// also load banner image in background
	NSString *bannerUrlString = [xml.documentRoot getNamedChild:@"imageurl"].text;
	
	if ([bannerUrlString length])
	{
		NSURL *bannerUrl = [NSURL URLWithString:bannerUrlString];
		[_bannerImage release];
		_bannerImage = [[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:bannerUrl]];
	}
	
	// rest of setup on main thread to prevent weird image loading effect
	
	[self performSelectorOnMainThread:@selector(setupAdFromXml:) withObject:xml waitUntilDone:YES];
	
	[pool release];
}

- (void)showErrorLabelWithText:(NSString *)text
{
	UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
	label.numberOfLines = 0;
	label.backgroundColor = [UIColor whiteColor];
	label.font = [UIFont boldSystemFontOfSize:12];
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor redColor];
	label.shadowOffset = CGSizeMake(0, 1);
	label.shadowColor = [UIColor blackColor];
	
	label.text = text;
	
	[self addSubview:label];
	[label release];
}

- (void)requestAd
{
	if (!delegate)
	{
		[self showErrorLabelWithText:@"MadServeBannerViewDelegate not set"];
		
		return;
	}
	
	if (![delegate respondsToSelector:@selector(publisherIdForMadServeBannerView:)])
	{
		[self showErrorLabelWithText:@"MadServeBannerViewDelegate does not implement publisherIdForMadServeBannerView:"];
		
		return;
	}	
	
	
	NSString *publisherId = [delegate publisherIdForMadServeBannerView:self];
	
	if (![publisherId length])
	{
		[self showErrorLabelWithText:@"MadServeBannerViewDelegate returned invalid publisher ID."];
		
		return;
	}
	
	[self performSelectorInBackground:@selector(asyncRequestAdWithPublisherId:) withObject:publisherId];
}

#pragma mark Interaction

- (void)checker:(RedirectChecker *)checker detectedRedirectionTo:(NSURL *)redirectURL
{
	if ([redirectURL isDeviceSupported])
	{
		[[UIApplication sharedApplication] openURL:redirectURL];
		return;
	}
	
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	MadServeAdBrowserViewController *browser = [[[MadServeAdBrowserViewController alloc] initWithUrl:redirectURL] autorelease];
	browser.delegate = (id)self;
	browser.userAgent = [self userAgent];
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	[self hideStatusBar];
	[viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)checker:(RedirectChecker *)checker didFinishWithData:(NSData *)data
{
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	MadServeAdBrowserViewController *browser = [[[MadServeAdBrowserViewController alloc] initWithUrl:nil] autorelease];
	browser.delegate = (id)self;
	browser.userAgent = [self userAgent];
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	NSString *scheme = [_tapThroughURL scheme];
	NSString *host = [_tapThroughURL host];
	NSString *path = [[_tapThroughURL path] stringByDeletingLastPathComponent];
	
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@/", scheme, host, path]];
	
	
	[browser.webView loadData:data MIMEType:checker.mimeType textEncodingName:checker.textEncodingName baseURL:baseURL];
	
	[self hideStatusBar];
	[viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)checker:(RedirectChecker *)checker didFailWithError:(NSError *)error
{
	bannerViewActionInProgress = NO;
}

- (void)tapThrough:(id)sender
{
	if ([delegate respondsToSelector:@selector(MadServeBannerViewActionShouldBegin:willLeaveApplication:)])
	{
		BOOL allowAd = [delegate MadServeBannerViewActionShouldBegin:self willLeaveApplication:_tapThroughLeavesApp];
		
		if (!allowAd)
		{
			return;
		}
	}
	
	if (_tapThroughLeavesApp || [_tapThroughURL isDeviceSupported])
	{
		[[UIApplication sharedApplication]openURL:_tapThroughURL];
		return; // if the URL was valid then we have left the app or sent it to the background
	}
	
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	if (!viewController)
	{
		NSLog(@"Unable to find view controller for presenting modal ad browser");
		return;
	}
	
	[self setRefreshTimerActive:NO];
	
	// probes the URL (= record clickthrough) and acts based on the response
	
	if (!_shouldSkipLinkPreflight)
	{
		[[[RedirectChecker alloc] initWithURL:_tapThroughURL userAgent:[self userAgent] delegate:(id)self] autorelease];
		return;
	}
	
	MadServeAdBrowserViewController *browser = [[[MadServeAdBrowserViewController alloc] initWithUrl:_tapThroughURL] autorelease];
	browser.delegate = (id)self;
	browser.userAgent = [self userAgent];
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	[self hideStatusBar];
	[viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)MadServeAdBrowserControllerDidDismiss:(MadServeAdBrowserViewController *)MadServeAdBrowserController
{
	[self showStatusBarIfNecessary];
	[MadServeAdBrowserController dismissModalViewControllerAnimated:YES];
	
	bannerViewActionInProgress = NO;
	[self setRefreshTimerActive:YES];
	
	if ([delegate respondsToSelector:@selector(MadServeBannerViewActionDidFinish:)])
	{
		[delegate MadServeBannerViewActionDidFinish:self];
	}
}

#pragma mark WebView Delegate (Text Ads)

// obsolete, because there is full size transparent button over it
/*
 - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
 {
 if (navigationType == UIWebViewNavigationTypeLinkClicked)
 {
 _tapThroughURL = [[request URL] retain];
 
 [self tapThrough:nil];
 
 return NO;
 }
 
 return YES;
 }
 */


#pragma mark Notifications
- (void) appDidBecomeActive:(NSNotification *)notification
{
	[self setRefreshTimerActive:YES];
}

- (void) appWillResignActive:(NSNotification *)notification
{
	[self setRefreshTimerActive:NO];
}



@synthesize delegate;
@synthesize advertisingSection;
@synthesize bannerLoaded;
@synthesize bannerViewActionInProgress;
@synthesize refreshAnimation;
@synthesize apiURL = _apiURL;


@end


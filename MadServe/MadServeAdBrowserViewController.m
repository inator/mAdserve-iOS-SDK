//
//  MadServeAdBrowserViewController.m
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "MadServeAdBrowserViewController.h"

#import "NSData+Base64.h"
#import "NSURL+MadServe.h"

@interface MadServeAdBrowserViewController () // private

@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSString *mimeType;
@property (nonatomic, retain) NSString *textEncodingName;
@property (nonatomic, retain) NSURL *url;

@end



@implementation MadServeAdBrowserViewController

@synthesize url = _url;
@synthesize userAgent;
@synthesize receivedData;
@synthesize mimeType;
@synthesize textEncodingName;
@synthesize webView = _webView;

@synthesize delegate;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithUrl:(NSURL *)url
{
	if (self = [super init])
	{
		self.url = url;
	}
	
	return self;
}

- (void)dealloc 
{
	[_url release];
	[_webView release];
	[mimeType release];
	[textEncodingName release];
	[receivedData release];
	[userAgent release];
    [super dealloc];
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	CGRect mainFrame = [UIScreen mainScreen].applicationFrame;
	
	UIView *view = [[[UIView alloc] initWithFrame:mainFrame] autorelease];
	
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	self.webView.frame = view.bounds;
	[view addSubview:self.webView];
	
	
	NSString *buttonBase64encoded = CLOSE_BUTTON_DATA;
	UIImage *image = [UIImage imageWithData:[NSData dataFromBase64String:buttonBase64encoded]];
	
	UIButton *btnClose=[UIButton buttonWithType:UIButtonTypeCustom];
	[btnClose setImage:image forState:UIControlStateNormal];
	[btnClose addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
	[btnClose setFrame:CGRectMake(view.bounds.size.width - 32, 3, 32, 32)];
	btnClose.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
	[view addSubview:btnClose];
	
	self.view = view;
}

- (UIWebView *)webView
{
	if (!_webView)
	{
		_webView = [[UIWebView alloc] initWithFrame:CGRectZero];
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_webView.delegate = self;
	}
	
	return _webView;
}


- (void)loadURL:(NSURL *)url
{
	
	if (!_url)
	{
		self.url = url;
		return;
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	
	if (userAgent)
	{
		// do the http request manually
		[request addValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
		
		NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
		[connection start];
		[self webViewDidStartLoad:_webView];
	}
	else 
	{
		[_webView loadRequest:request];
	}	
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	[self loadURL:_url];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark Actions

-(void)dismiss:(id)sender
{
	if ([delegate respondsToSelector:@selector(MadServeAdBrowserControllerDidDismiss:)])
	{
		[delegate MadServeAdBrowserControllerDidDismiss:self];
	}
	else 
	{
		[self dismissModalViewControllerAnimated:NO];
	}
}

#pragma mark Web View Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
		NSURL *url = [request URL];
		
		if ( [url isDeviceSupported])
		{
			[[UIApplication sharedApplication] openURL:url];
		}
		
		return YES;
	}
	
	// different user agent:
	
	if (self.userAgent)
	{
		if ([request isKindOfClass:[NSMutableURLRequest class]])
		{
			[(NSMutableURLRequest *)request addValue:self.userAgent  forHTTPHeaderField:@"User-Agent"];
		}
	}
	
	return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// incorrect URL -1003
	// no internect connection -1009
	return;
}


#pragma mark Manual URL Loading for custom user agent
- (NSMutableData *)receivedData
{
	if (!receivedData)
	{
		receivedData = [[NSMutableData alloc] init];
	}
	
	return receivedData;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
	self.url = request.URL;
	
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.mimeType = response.MIMEType;
	self.textEncodingName = response.textEncodingName;
	
	// could be redirections, so we set the Length to 0 every time
	[self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[receivedData release];
	receivedData = nil;
	
	[self webView:_webView didFailLoadWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *scheme = [_url scheme];
	NSString *host = [_url host];
	NSString *path = [[_url path] stringByDeletingLastPathComponent];
	
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@/", scheme, host, path]];
	
	[_webView loadData:receivedData MIMEType:self.mimeType textEncodingName:textEncodingName baseURL:baseURL];
	[self webViewDidFinishLoad:_webView];
}

@end

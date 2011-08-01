//
//  MadServeBannerView.h
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    MadServeErrorUnknown = 0,
    MadServeErrorServerFailure = 1,
    MadServeErrorInventoryUnavailable = 2,
};

@class MadServeBannerView;

@protocol MadServeBannerViewDelegate <NSObject>

- (NSString *)publisherIdForMadServeBannerView:(MadServeBannerView *)banner;

- (NSURL *)apiURLForMadServeBannerView:(MadServeBannerView *)banner;

@optional

// called if an ad has been successfully retrieved
- (void)MadServeBannerViewDidLoadMadServeAd:(MadServeBannerView *)banner;

// called if no banner is available or there is an error
- (void)MadServeBannerView:(MadServeBannerView *)banner didFailToReceiveAdWithError:(NSError *)error;

// called when user taps on a banner
- (BOOL)MadServeBannerViewActionShouldBegin:(MadServeBannerView *)banner willLeaveApplication:(BOOL)willLeave;

// called when the modal web view is cancelled and the user is returning to your app
- (void)MadServeBannerViewActionDidFinish:(MadServeBannerView *)banner;

@end




@interface MadServeBannerView : UIView 
{
	NSString *advertisingSection;  // formerly know as "spot"
	BOOL bannerLoaded;
	BOOL bannerViewActionInProgress;
	UIViewAnimationTransition refreshAnimation;
	
	id <MadServeBannerViewDelegate> delegate;
	
	// internals
	UIImage *_bannerImage;
	BOOL _tapThroughLeavesApp;
	BOOL _shouldScaleWebView;
	BOOL _shouldSkipLinkPreflight;
	BOOL _statusBarWasVisible;
	NSURL *_tapThroughURL;
	NSInteger _refreshInterval;
	
	NSTimer *_refreshTimer;
	
	NSURL *_apiURL;
}

@property(nonatomic, assign) IBOutlet id <MadServeBannerViewDelegate> delegate;
@property(nonatomic, copy) NSString *advertisingSection;
@property(nonatomic, assign) UIViewAnimationTransition refreshAnimation;


@property(nonatomic, readonly, getter=isBannerLoaded) BOOL bannerLoaded;
@property(nonatomic, readonly, getter=isBannerViewActionInProgress) BOOL bannerViewActionInProgress;

@end

extern NSString * const MadServeErrorDomain;
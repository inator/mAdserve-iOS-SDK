//
//  RedirectChecker.h
//
//  Created by Oliver Drobnik on 9/25/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RedirectChecker;

@protocol RedirectCheckerDelegate <NSObject>

- (void)checker:(RedirectChecker *)checker detectedRedirectionTo:(NSURL *)redirectURL;
- (void)checker:(RedirectChecker *)checker didFinishWithData:(NSData *)data;

@optional
- (void)checker:(RedirectChecker *)checker didFailWithError:(NSError *)error;

@end



@interface RedirectChecker : NSObject 
{
	id <RedirectCheckerDelegate> _delegate;
	
	NSMutableData *receivedData;
	
	NSString *mimeType;
	NSString *textEncodingName;
	
	NSURLConnection *_connection;
}

- (id)initWithURL:(NSURL *)url userAgent:(NSString *)userAgent delegate:(id<RedirectCheckerDelegate>) delegate;

@property (nonatomic, assign) id <RedirectCheckerDelegate> delegate;

@property (nonatomic, retain) NSString *mimeType;
@property (nonatomic, retain) NSString *textEncodingName;

@end

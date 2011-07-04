//
//  DTXMLDocument.h
//
//  Created by Oliver Drobnik on 8/23/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>



@class DTXMLDocument, DTXMLElement;


@protocol DTXMLDocumentDelegate <NSObject>

@optional

- (void) didFinishLoadingXmlDocument:(DTXMLDocument *)xmlDocument;
- (void) xmlDocument:(DTXMLDocument *)xmlDocument didFailWithError:(NSError *)error;

- (NSURLCredential *) userCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end



@interface DTXMLDocument : NSObject 
{
	NSURL *_url;
	
	DTXMLElement *documentRoot;
	
	id <DTXMLDocumentDelegate> _delegate;
	
	// parsing 
	DTXMLElement *currentElement;
	
	// url loading
	NSMutableData *receivedData;
	NSURLConnection *theConnection;
	
	BOOL doneLoading;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) DTXMLElement *documentRoot;
@property (nonatomic, assign) id <DTXMLDocumentDelegate> delegate;
@property (nonatomic, readonly) BOOL doneLoading;

+ (DTXMLDocument *) documentWithData:(NSData *)data;
+ (DTXMLDocument *) documentWithContentsOfFile:(NSString *)path;
+ (DTXMLDocument *) documentWithContentsOfFile:(NSString *)path delegate:(id<DTXMLDocumentDelegate>)delegate;
+ (DTXMLDocument *) documentWithContentsOfURL:(NSURL *)url delegate:(id<DTXMLDocumentDelegate>)adelegate;

- (id) initWithContentsOfFile:(NSString *)path;
- (id) initWithContentsOfFile:(NSString *)path delegate:(id<DTXMLDocumentDelegate>)delegate;
- (id) initWithContentsOfURL:(NSURL *)url delegate:(id<DTXMLDocumentDelegate>)delegate;
- (id) initWithData:(NSData *)data;

@end

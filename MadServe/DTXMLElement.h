//
//  DTXMLElement.h
//
//  Created by Oliver Drobnik on 8/23/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DTXMLElement : NSObject {
	NSString *name;
	NSMutableString *text;
	NSMutableArray *children;
	NSMutableDictionary *attributes;
	DTXMLElement *parent;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableString *text;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, retain) NSMutableDictionary *attributes;
@property (nonatomic, assign) DTXMLElement *parent;


- (id) initWithName:(NSString *)elementName;
- (DTXMLElement *) getNamedChild:(NSString *)childName;
- (NSArray *) getNamedChildren:(NSString *)childName;
- (void) removeNamedChild:(NSString *)childName;
- (void) changeTextForNamedChild:(NSString *)childName toText:(NSString *)newText;
- (DTXMLElement *) addChildWithName:(NSString *)childName text:(NSString *)childText;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSURL *link;
@property (nonatomic, readonly) NSString *content;

@end

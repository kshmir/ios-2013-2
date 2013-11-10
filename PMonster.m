//
//  PMonster.m
//  Pombies
//
//  Created by Cristian Pereyra on 11/10/13.
//  Copyright (c) 2013 Cristian Pereyra. All rights reserved.
//

#import "PMonster.h"

// A class that represents a step of the computed path
@interface ShortestPathStep : NSObject
{
	CGPoint position;
	int gScore;
	int hScore;
	ShortestPathStep *_parent;
}

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) int gScore;
@property (nonatomic, assign) int hScore;
@property (nonatomic, assign) ShortestPathStep *parent;

- (id)initWithPosition:(CGPoint)pos;
- (int)fScore;

@end

@implementation PMonster {
    HelloWorldLayer * _layer;
}

// Add after @implementation CatSprite
@synthesize spOpenSteps;
@synthesize spClosedSteps;

- (id)initWithLayer:(HelloWorldLayer *)layer {
    if ((self = [super initWithFile:@"Player.png"])) {
        _layer = layer;
        
        self.spOpenSteps = nil;
        self.spClosedSteps = nil;
    }
    return self;
}

- (void)moveToward:(CGPoint)target {
    // Get current tile coordinate and desired tile coord
    CGPoint fromTileCoord = [_layer tileCoordForPosition:self.position];
    CGPoint toTileCoord = [_layer tileCoordForPosition:target];
    
    // Check that there is a path to compute ;-)
    if (CGPointEqualToPoint(fromTileCoord, toTileCoord)) {
        NSLog(@"You're already there! :P");
        return;
    }
    
    NSLog(@"From: %@", NSStringFromCGPoint(fromTileCoord));
    NSLog(@"To: %@", NSStringFromCGPoint(toTileCoord));
}

@end


@implementation ShortestPathStep

@synthesize position;
@synthesize gScore;
@synthesize hScore;
@synthesize parent;

- (id)initWithPosition:(CGPoint)pos
{
	if ((self = [super init])) {
		position = pos;
		gScore = 0;
		hScore = 0;
		parent = nil;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@  pos=[%.0f;%.0f]  g=%d  h=%d  f=%d", [super description], self.position.x, self.position.y, self.gScore, self.hScore, [self fScore]];
}

- (BOOL)isEqual:(ShortestPathStep *)other
{
	return CGPointEqualToPoint(self.position, other.position);
}

- (int)fScore
{
	return self.gScore + self.hScore;
}

@end
//
//  HelloWorldLayer.h
//  Pombies
//
//  Created by Cristian Pereyra on 11/9/13.
//  Copyright Cristian Pereyra 2013. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "ObjectiveChipmunk.h"
#import "ChipmunkAutoGeometry.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@property (strong) CCPhysicsSprite *player;

- (ChipmunkSpace *) space;
- (BOOL)isValidTileCoord:(CGPoint)tileCoord;
- (CGPoint)positionForTileCoord:(CGPoint)tileCoord;
- (BOOL)isWallAtTileCoord:(CGPoint)tileCoord;
- (CGPoint)tileCoordForPosition:(CGPoint)position;
- (NSArray *)walkableAdjacentTilesCoordForTileCoord:(CGPoint)tileCoord;

@end

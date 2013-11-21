//
//  HelloWorldLayer.m
//  Pombies
//
//  Created by Cristian Pereyra on 11/9/13.
//  Copyright Cristian Pereyra 2013. All rights reserved.
//
#import "HelloWorldLayer.h"
#import "AppDelegate.h"
#import "PMonster.h"
#import "PBullet.h"
#import "PGUI.h"

@interface HelloWorldLayer() {
    CGPoint _lastTouchPoint;
    CGPoint _lastTargetPoint;
    ChipmunkSpace * space;
    NSTimeInterval      mLastTapTime;
    NSTimeInterval      mLastMoveTime;
    int monsterCount;
    NSMutableArray * spawnPoints;
    PGUI * gui;
    int score;
    int lives;
}

#define MONSTER_LIMIT 15

@property (strong) CCTMXTiledMap *tileMap;
@property (strong) CCTMXLayer *background;
@property (strong) CCTMXLayer *meta;
@property (strong) ChipmunkBody *targetPointBody;
@property (atomic) BOOL *isTouching;
@property (atomic) BOOL *isClicking;

@end

@implementation HelloWorldLayer

- (ChipmunkSpace *) space {
    return space;
}

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
    
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer create: scene];

    
	// add layer as a child to scene
	[scene addChild: layer];
    
	// return the scene
	return scene;
}

- (void)createSpace {
    space = [[ChipmunkSpace alloc] init];
}


// Add new method
- (void)update:(ccTime)dt {
    
    if (self.isTouching) {
        [[self targetPointBody] setPos:self->_lastTouchPoint];
    }
    
    if (self.isClicking) {
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval diff = currentTime - mLastMoveTime;
        if (diff > 0.1) {
            mLastMoveTime = [NSDate timeIntervalSinceReferenceDate];
        }
    }
    
    ccTime fixed_dt = [CCDirector sharedDirector].animationInterval;
    [space step:fixed_dt];
    
    //update camera
    [self setViewPointCenter:_player.position];
}


+(id) create: (CCScene *) scene
{
    HelloWorldLayer * layer = [HelloWorldLayer node];
    layer.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"pv.tmx"];
    layer.background = [layer.tileMap layerNamed:@"Transparentes"];
    
    [layer addChild:layer->_tileMap z:-1];
    
    [layer createSpace];
    
    [layer setIsTouching:NO];
    
    layer.meta = [layer->_tileMap layerNamed:@"Meta"];
    layer->_meta.visible = NO;
    
    layer->mLastTapTime  = [NSDate timeIntervalSinceReferenceDate];
    layer->mLastMoveTime = [NSDate timeIntervalSinceReferenceDate];
    
    CCTMXObjectGroup *objects = [layer->_tileMap objectGroupNamed:@"Objects"];
    NSAssert(objects != nil, @"'Objects' object group not found");
    NSMutableDictionary *spawnPoint = [objects objectNamed:@"SpawnPoint"];
    
    NSAssert(spawnPoint != nil, @"SpawnPoint object not found");
    int x = [[spawnPoint valueForKey:@"x"] intValue];
    int y = [[spawnPoint valueForKey:@"y"] intValue];
    
    NSMutableArray * array = [objects objects];
    
    layer->spawnPoints = [[NSMutableArray alloc] init];
    
    for (NSMutableDictionary * object in array) {
        if ([[object valueForKey:@"name"] isEqualToString:@"BotSpawn"]) {
            [layer->spawnPoints addObject: object];
        }
    }
    
    
    [[layer space] addCollisionHandler:layer
                                 typeA:@"bullet" typeB:@"monster"
                                 begin:@selector(beginCollision:space:)
                              preSolve:nil
                             postSolve:@selector(postSolveCollision:space:)
                              separate:@selector(separateCollision:space:)
     ];
    
       [[layer space] addCollisionHandler:layer
                                 typeA:@"player" typeB:@"monster"
                                 begin:@selector(beginCollision:space:)
                              preSolve:nil
                             postSolve:@selector(postSolveCollision:space:)
                              separate:@selector(separateCollision:space:)
        ];
    
    layer->_meta = [layer->_tileMap layerNamed:@"Meta"];
    layer->_meta.visible = NO;
    
    [layer scheduleUpdate];
    
    PGUI * gui = [PGUI create];
    
    layer->lives = 10;
    layer->gui = gui;
    layer.touchEnabled = YES;
    
    [scene addChild:gui z:1000];
    
    [layer createPlayer:y x:x];
    [layer createTerrainGeometry];
    [layer setViewPointCenter:layer->_player.position];
    
    [layer schedule:@selector(addRandomZombie) interval:0.1];
    
    return layer;
}

- (NSDictionary *) randomSpawnPoint {
    int index = (int) ((rand() * 1.0 / RAND_MAX) * [spawnPoints count]);
    return [spawnPoints objectAtIndex:index];
}

- (void) addRandomZombie {
    if (monsterCount < MONSTER_LIMIT) {
        NSDictionary * spawnPoint = [self randomSpawnPoint];
        int x = [[spawnPoint valueForKey:@"x"] intValue];
        int y = [[spawnPoint valueForKey:@"y"] intValue];
        
        PMonster * monster = [[PMonster alloc] initWithLayer:self];
        
        [self addChild:monster];
        
        monster.position = ccp(x,y);
        
        monsterCount++;
    }
}


- (bool)beginCollision:(cpArbiter*)arbiter space:(ChipmunkSpace*)sp {
    return TRUE;
}

- (void) reload {
   	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:[HelloWorldLayer scene] ]];
}
// The post-solve collision callback is called right after Chipmunk has finished calculating all of the
// collision responses. You can use it to find out how hard objects hit each other.
// There is also a pre-solve callback that allows you to reject collisions conditionally.
- (void)postSolveCollision:(cpArbiter*)arbiter space:(ChipmunkSpace*)sp {
    CHIPMUNK_ARBITER_GET_SHAPES(arbiter, base, monster);
    CHIPMUNK_ARBITER_GET_BODIES(arbiter, baseBody, monsterBody);
    
    if ([[base collisionType] isEqualToString:@"bullet"]
        && [[monster collisionType] isEqualToString:@"monster"]) {

        [gui setScore: ++score];
        
        @try {
            monsterCount--;
            [sp addPostStepBlock:^{
                [[self space] removeShape:monster];
                [[self space] removeShape:base];
                [[self space] removeBody:monsterBody];
                [[self space] removeBody:monsterBody.data];
                [[self space] removeConstraint:[((ChipmunkBody *)[monsterBody data]) data]];
                [[self space] removeBody:baseBody];
                [self removeChild: [monster data]];
                [self removeChild: [base data]];
            } key:nil];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
        }
    }
    
    
       if ([[base collisionType] isEqualToString:@"player"]
        && [[monster collisionType] isEqualToString:@"monster"]) {

        [gui setLiveCount:--lives];
        
        @try {
            monsterCount--;
            [sp addPostStepBlock:^{
                [[self space] removeShape:monster];
                [[self space] removeBody:monsterBody];
                [[self space] removeBody:monsterBody.data];
                [[self space] removeConstraint:[((ChipmunkBody *)[monsterBody data]) data]];
                [self removeChild: [monster data]];
                if (lives == 0) {
                    [self reload];
                }
            } key:nil];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
        }
       }
}

- (void)separateCollision:(cpArbiter*)arbiter space:(ChipmunkSpace*)sp {
}

// Add new method
- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x, y);
}

- (void) createPlayer: (int) y x: (int) x {
    float playerMass = 1.0f;
    float playerRadius = 13.0f;

    ChipmunkBody *playerBody = [space add:[ChipmunkBody bodyWithMass:playerMass andMoment:INFINITY]];
    playerBody.pos = ccp(x,y);
    
    ChipmunkShape *playerShape = [space add:[ChipmunkCircleShape circleWithBody:playerBody radius:playerRadius offset:cpvzero]];
    playerShape.friction = 0.1;
    playerShape.collisionType = @"player";
    
    _player = [CCPhysicsSprite spriteWithFile:@"peron1"];
    
    [self setPlayer:_player];
    [self.player setChipmunkBody:playerBody];
    [self addChild:_player];
    
    ChipmunkBody *targetPointBody = [space add:[ChipmunkBody bodyWithMass:INFINITY andMoment:INFINITY]];
    targetPointBody.pos = ccp(x,y);
    
    [self setTargetPointBody:targetPointBody];
   
    
    ChipmunkPivotJoint* joint = [space add:[ChipmunkPivotJoint pivotJointWithBodyA:targetPointBody
                                                                             bodyB:playerBody
                                                                            anchr1:cpvzero
                                                                            anchr2:cpvzero]];
    joint.maxBias = 200.0f;
    joint.maxForce = 3000.0f;
}

- (void) createTerrainGeometry {
    int tileCountW = _meta.layerSize.width;
    int tileCountH = _meta.layerSize.height;
    
    cpBB sampleRect = cpBBNew(-0.5, -0.5, tileCountW + 0.5, tileCountH + 0.5);
    
    // Create a sampler using a block that samples the tilemap in tile coordinates.
    ChipmunkBlockSampler *sampler = [[ChipmunkBlockSampler alloc] initWithBlock:^(cpVect point){
        // Clamp the point so that samples outside the tilemap bounds will sample the edges.
        point = cpBBClampVect(cpBBNew(0.5, 0.5, tileCountW - 0.5, tileCountH - 0.5), point);
        // The samples will always be at tile centers.
        // So we just need to truncate to an integer to convert to tile coordinates.
        int x = point.x;
        int y = point.y;
        // Flip the y-coord (Cocos2D tilemap coords are flipped this way)
        y = tileCountH - 1 - y;
        
        // Look up the tile to see if we set a Collidable property in the Tileset meta layer
        NSDictionary *properties = [_tileMap propertiesForGID:[_meta tileGIDAt:ccp(x, y)]];
        BOOL collidable = [[properties valueForKey:@"collidable"] isEqualToString:@"true"];
        
        // If the tile is collidable, return a density of 1.0 (meaning solid)
        // Otherwise return a density of 0.0 meaning completely open.
        return (collidable ? 1.0f : 0.0f);
    }];
    
    ChipmunkPolylineSet * polylines = [sampler march:sampleRect xSamples:tileCountH + 2 ySamples:tileCountH + 2 hard:TRUE];
    
    cpFloat tileH = _tileMap.tileSize.height;
    
    for(ChipmunkPolyline * line in polylines){
        ChipmunkPolyline * simplified = [line simplifyCurves:0.0f];
        for(int i=0; i<simplified.count-1; i++){
            
            // The sampler coordinates were in tile coordinates.
            // Convert them to pixel coordinates by multiplying by the tile size.
            cpFloat tileSize = tileH; // fortunately our tiles are square, otherwise we'd need to multiply components independently
            cpVect a = cpvmult(simplified.verts[  i], tileSize);
            cpVect b = cpvmult(simplified.verts[i+1], tileSize);
            
            // Add the shape and set some properties.
            ChipmunkShape *seg = [space add:[ChipmunkSegmentShape segmentWithBody:space.staticBody from:a to:b radius:1.0f]];
            seg.friction = 1.0;
        }
    }
    
}


-(void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self
                                                              priority:0
                                                       swallowsTouches:YES];
}

-(void) addProjectile: (CGPoint) point {
    float radius = 5;
    float mass = 1;
    double diffX = point.x - _player.position.x;
    double diffY = point.y - _player.position.y;
    
    double dist = sqrt(diffX * diffX + diffY * diffY);
    ChipmunkBody *bulletBody = [space add:[ChipmunkBody bodyWithMass:mass andMoment:INFINITY]];;
    bulletBody.pos = ccp(_player.position.x + diffX / 15, _player.position.y + diffY / 15);
    
    ChipmunkShape *bulletplayerShape = [space add:[ChipmunkCircleShape circleWithBody:bulletBody radius:radius offset:cpvzero]];
    bulletplayerShape.friction = 0.0;
    bulletplayerShape.collisionType = @"bullet";
    
    
    PBullet * bullet = [PBullet spriteWithFile:@"bullet.png" andLayer: self];
    [bulletplayerShape setData:bullet];
    [bulletBody setData:bulletplayerShape];
    
    [bulletBody applyImpulse:ccp(diffX / dist * 750, diffY / dist * 750) offset:cpvzero];
    
    [bullet setChipmunkBody:bulletBody];
    
    [bullet scheduleOnce:@selector(deleteBullet) delay:5.0];
    
    [self addChild:bullet];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    self->_lastTouchPoint = touchLocation;
    
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval diff = currentTime - mLastTapTime;
    if (diff < 1.0) {
        [self setIsTouching: YES];
        [[self targetPointBody] setPos:self->_lastTargetPoint];
    }
    [self setIsClicking: YES];
    [self addProjectile: touchLocation];
    mLastTapTime = [NSDate timeIntervalSinceReferenceDate];
    
	return YES;
}
-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    self->_lastTouchPoint = touchLocation;
    _lastTargetPoint = [[self targetPointBody] pos];
}


-(void)setPlayerPosition:(CGPoint)position {
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];
    if (tileGid) {
        NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
        if (properties) {
            NSString *collision = properties[@"collidable"];
            if (collision && [collision isEqualToString:@"true"]) {
                return;
            }
        }
    }
    _player.position = position;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    _lastTargetPoint = [[self targetPointBody] pos];
    [self setIsTouching: NO];
    [self setIsClicking: NO];
}

- (void)setViewPointCenter:(CGPoint) position {
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    int x = MAX(position.x, winSize.width/2);
    int y = MAX(position.y, winSize.height/2);
    x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width) - winSize.width / 2);
    y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height) - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.position = viewPoint;
}


- (BOOL)isValidTileCoord:(CGPoint)tileCoord {
    if (tileCoord.x < 0 || tileCoord.y < 0 ||
        tileCoord.x >= _tileMap.mapSize.width ||
        tileCoord.y >= _tileMap.mapSize.height) {
        return FALSE;
    } else {
        return TRUE;
    }
}

-(BOOL)isProp:(NSString*)prop atTileCoord:(CGPoint)tileCoord forLayer:(CCTMXLayer *)layer {
    if (![self isValidTileCoord:tileCoord]) return NO;
    int gid = [layer tileGIDAt:tileCoord];
    NSDictionary * properties = [_tileMap propertiesForGID:gid];
    if (properties == nil) return NO;
    return [properties objectForKey:prop] != nil;
}


- (CGPoint)positionForTileCoord:(CGPoint)tileCoord {
    int x = (tileCoord.x * _tileMap.tileSize.width) + _tileMap.tileSize.width/2;
    int y = (_tileMap.mapSize.height * _tileMap.tileSize.height) - (tileCoord.y * _tileMap.tileSize.height) - _tileMap.tileSize.height/2;
    return ccp(x, y);
}

-(BOOL)isWallAtTileCoord:(CGPoint)tileCoord {
    return [self isProp:@"collidable" atTileCoord:tileCoord forLayer:_meta];
}


- (NSArray *)walkableAdjacentTilesCoordForTileCoord:(CGPoint)tileCoord
{
	NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:4];
    
	// Top
	CGPoint p = CGPointMake(tileCoord.x, tileCoord.y - 1);
	if ([self isValidTileCoord:p] && ![self isWallAtTileCoord:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Left
	p = CGPointMake(tileCoord.x - 1, tileCoord.y);
	if ([self isValidTileCoord:p] && ![self isWallAtTileCoord:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Bottom
	p = CGPointMake(tileCoord.x, tileCoord.y + 1);
	if ([self isValidTileCoord:p] && ![self isWallAtTileCoord:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Right
	p = CGPointMake(tileCoord.x + 1, tileCoord.y);
	if ([self isValidTileCoord:p] && ![self isWallAtTileCoord:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	return [NSArray arrayWithArray:tmp];
}

@end

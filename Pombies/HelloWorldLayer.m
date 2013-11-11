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


@interface HelloWorldLayer() {
    CGPoint _lastTouchPoint;
    CGPoint _lastTargetPoint;
    ChipmunkSpace * space;
    NSTimeInterval      mLastTapTime;
}

@property (strong) CCTMXTiledMap *tileMap;
@property (strong) CCTMXLayer *background;
@property (strong) CCPhysicsSprite *player;
@property (strong) CCTMXLayer *meta;
@property (strong) ChipmunkBody *targetPointBody;
@property (strong) PMonster *monster;
@property (atomic) BOOL *isTouching;

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
	HelloWorldLayer *layer = [HelloWorldLayer node];

    
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
        _lastTargetPoint = [[self targetPointBody] pos];
        [[self targetPointBody] setPos:self->_lastTouchPoint];
    }
    
    ccTime fixed_dt = [CCDirector sharedDirector].animationInterval;
    [space step:fixed_dt];
    
    //update camera
    [self setViewPointCenter:_player.position];
}



-(id) init
{
	if( (self=[super init]) ) {
        self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"pv.tmx"];
        self.background = [self.tileMap layerNamed:@"Transparentes"];
        
        [self addChild:_tileMap z:-1];
        
        // Comment out the lines that create the label in init, and add this:
        [self createSpace];

        [self setIsTouching:NO];
        
        self.meta = [_tileMap layerNamed:@"Meta"];
        _meta.visible = NO;
        
        mLastTapTime = [NSDate timeIntervalSinceReferenceDate];
       
        /** Init Player And Center Camera **/
        CCTMXObjectGroup *objects = [_tileMap objectGroupNamed:@"Objects"];
        NSAssert(objects != nil, @"'Objects' object group not found");
        NSMutableDictionary *spawnPoint = [objects objectNamed:@"SpawnPoint"];
        NSAssert(spawnPoint != nil, @"SpawnPoint object not found");
        int x = [[spawnPoint valueForKey:@"x"] intValue];
        int y = [[spawnPoint valueForKey:@"y"] intValue];
        
        [space addCollisionHandler:self
                             typeA:@"bullet" typeB:@"monster"
                             begin:@selector(beginCollision:space:)
                          preSolve:nil
                         postSolve:@selector(postSolveCollision:space:)
                          separate:@selector(separateCollision:space:)
         ];
        
        _meta = [_tileMap layerNamed:@"Meta"];
        _meta.visible = NO;
        
        [self scheduleUpdate];
        
        self.touchEnabled = YES;
        
        [[self monster] setPosition:ccp(x,y + 32)];
        
        [self createPlayer:y x:x];
        [self createTerrainGeometry];
        [self setViewPointCenter:_player.position];
        
        CCPhysicsDebugNode *debugNode = [CCPhysicsDebugNode debugNodeForChipmunkSpace:space];
        [self addChild:debugNode];
        
    }
    return self;
}


- (bool)beginCollision:(cpArbiter*)arbiter space:(ChipmunkSpace*)sp {
    return TRUE;
}

// The post-solve collision callback is called right after Chipmunk has finished calculating all of the
// collision responses. You can use it to find out how hard objects hit each other.
// There is also a pre-solve callback that allows you to reject collisions conditionally.
- (void)postSolveCollision:(cpArbiter*)arbiter space:(ChipmunkSpace*)sp {
    CHIPMUNK_ARBITER_GET_SHAPES(arbiter, bullet, monster);
    CHIPMUNK_ARBITER_GET_BODIES(arbiter, bulletBody, monsterBody);
    
    if ([[bullet collisionType] isEqualToString:@"bullet"]
        && [[monster collisionType] isEqualToString:@"monster"]) {
        [((PMonster *)[monster data]) setAsDead];
        [self removeChild: [monster data]];
        [self removeChild: [bullet data]];
        [sp addPostStepBlock:^{
            [[self space] removeShape:monster];
            [[self space] removeShape:bullet];
            [[self space] removeBody:monsterBody];
            [[self space] removeBody:monsterBody.data];
            [[self space] removeConstraint:[((ChipmunkBody *)[monsterBody data]) data]];
            [[self space] removeBody:bulletBody];
        } key:nil];
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
        ChipmunkPolyline * simplified = [line simplifyCurves:1.0f];
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
        [self addProjectile: touchLocation];
        [[self targetPointBody] setPos:self->_lastTargetPoint];
    }
    mLastTapTime = [NSDate timeIntervalSinceReferenceDate];
    [self setIsTouching: YES];
    
	return YES;
}
-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    self->_lastTouchPoint = touchLocation;
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
    [[self monster] moveToward:ccp(_lastTouchPoint.x + 64, _lastTouchPoint.y + 64)];
    [self setIsTouching: NO];
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

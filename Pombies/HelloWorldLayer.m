//
//  HelloWorldLayer.m
//  Pombies
//
//  Created by Cristian Pereyra on 11/9/13.
//  Copyright Cristian Pereyra 2013. All rights reserved.
//
#import "HelloWorldLayer.h"
#import "AppDelegate.h"

@interface HelloWorldLayer() {
    CGPoint _lastTouchPoint;
    ChipmunkSpace * space;
}

@property (strong) CCTMXTiledMap *tileMap;
@property (strong) CCTMXLayer *background;
@property (strong) CCPhysicsSprite *player;
@property (strong) CCTMXLayer *meta;
@property (strong) ChipmunkBody *targetPointBody;
@property (atomic) BOOL *isTouching;

@end

@implementation HelloWorldLayer

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
        
       
        /** Init Player And Center Camera **/
        CCTMXObjectGroup *objects = [_tileMap objectGroupNamed:@"Objects"];
        NSAssert(objects != nil, @"'Objects' object group not found");
        NSMutableDictionary *spawnPoint = [objects objectNamed:@"SpawnPoint"];
        NSAssert(spawnPoint != nil, @"SpawnPoint object not found");
        int x = [[spawnPoint valueForKey:@"x"] intValue];
        int y = [[spawnPoint valueForKey:@"y"] intValue];
        
        _meta = [_tileMap layerNamed:@"Meta"];
        _meta.visible = NO;
        
        [self scheduleUpdate];
        
        self.touchEnabled = YES;
        
        [self createPlayer:y x:x];
        [self createTerrainGeometry];
        [self setViewPointCenter:_player.position];
        
        CCPhysicsDebugNode *debugNode = [CCPhysicsDebugNode debugNodeForChipmunkSpace:space];
        [self addChild:debugNode];
        
    }
    return self;
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
    
    _player = [CCPhysicsSprite spriteWithFile:@"Player.png"];
    
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
    
    cpFloat tileW = _tileMap.tileSize.width;
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

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
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

@end

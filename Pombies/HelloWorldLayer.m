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
}

@property (strong) CCTMXTiledMap *tileMap;
@property (strong) CCTMXLayer *background;
@property (strong) CCPhysicsSprite *player;
@property (strong) CCTMXLayer *meta;
@property (atomic) cpBody *targetPointBody;
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
    space = cpSpaceNew();
    space->gravity = ccp(0, -1);
}

// Add new method
- (void)createBoxAtLocation:(CGPoint)location {
    
    float boxSize = 120.0;
    float mass = 100.0;
    cpBody *body = cpBodyNew(mass, cpMomentForBox(mass, boxSize, boxSize));
    body->p = location;
    cpSpaceAddBody(space, body);
    
    cpShape *shape = cpBoxShapeNew(body, boxSize, boxSize);
    shape->e = 100.0;
    shape->u = 100.0;
    cpSpaceAddShape(space, shape);
    
    [self.player setCPBody:body];
}

// Add new method
- (void)update:(ccTime)dt {
    if (self.isTouching) {
        [self targetPointBody]->p = self->_lastTouchPoint;
    }
    
    ccTime fixed_dt = [CCDirector sharedDirector].animationInterval;
    cpSpaceStep(space, fixed_dt);
    
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
        
        CCPhysicsDebugNode *debugNode = [CCPhysicsDebugNode debugNodeForCPSpace:space];
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
    float boxSize = 20.0f;
    float mass = 1.0;
    cpBody *body = cpBodyNew(mass, cpMomentForBox(mass, boxSize, boxSize * 2));
    body->p = ccp(x,y);
    cpSpaceAddBody(space, body);
    
    cpShape *shape = cpBoxShapeNew(body, boxSize, boxSize * 2);
    shape->e = 1.0;
    shape->u = 1.0;
    cpSpaceAddShape(space, shape);
    
    _player = [CCPhysicsSprite spriteWithFile:@"Player.png"];
    
    [self setPlayer:_player];
    [self.player setCPBody:body];
    [self addChild:_player];
    
    cpBody * targetPointBody = cpBodyNew(INFINITY, INFINITY);
    targetPointBody->p = ccp(x,y);
    cpSpaceAddBody(space, targetPointBody);
    
    [self setTargetPointBody:targetPointBody];
   
    cpPivotJoint * joint = cpPivotJointAlloc();
    cpPivotJointInit(joint, targetPointBody, body, cpvzero, cpvzero);
    
    cpConstraintSetMaxBias(&joint->constraint, 200.0f);
    cpConstraintSetMaxForce(&joint->constraint, 5000.0f);
    
    cpSpaceAddConstraint(space, &joint->constraint);
}

- (void) createTerrainGeometry {
    
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

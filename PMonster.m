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
    ChipmunkBody * _leaderPoint;
    BOOL hasMoved;
    float lastAng;
}

// Add after @implementation CatSprite
@synthesize spOpenSteps;
@synthesize spClosedSteps;
@synthesize shortestPath;
@synthesize currentMovingPath;

- (void)insertInOpenSteps:(ShortestPathStep *)step {
    int stepFScore = [step fScore]; // Compute the step's F score
	int count = [self.spOpenSteps count];
	int i = 0; // This will be the index at which we will insert the step
	for (; i < count; i++) {
		if (stepFScore <= [[self.spOpenSteps objectAtIndex:i] fScore]) { // If the step's F score is lower or equals to the step at index i
			// Then we found the index at which we have to insert the new step
            // Basically we want the list sorted by F score
			break;
		}
	}
	// Insert the new step at the determined index to preserve the F score ordering
	[self.spOpenSteps insertObject:step atIndex:i];
}

- (int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord {
    // Here we use the Manhattan method, which calculates the total number of step moved horizontally and vertically to reach the
	// final desired step from the current step, ignoring any obstacles that may be in the way
	return abs(toCoord.x - fromCoord.x) + abs(toCoord.y - fromCoord.y);
    
}
- (int)costToMoveFromStep:(ShortestPathStep *)fromStep toAdjacentStep:(ShortestPathStep *)toStep {
    // Because we can't move diagonally and because terrain is just walkable or unwalkable the cost is always the same.
	// But it have to be different if we can move diagonally and/or if there is swamps, hills, etc...
    
	return 1;
}

const float half = 1.57079633;

- (void) draw {
    float ang = [[self chipmunkBody] angle];
    float currentAng = 0;
    
    CGPoint toCoord = _leaderPoint.pos;
    CGPoint fromCoord = self.position;
    
   	double dist = sqrt(pow(abs(toCoord.x - fromCoord.x), 2) + pow(abs(toCoord.y - fromCoord.y), 2));
   
    if (dist > 32 && currentMovingPath != nil && toCoord.x != 0 && toCoord.y != 0) {
        if (self.position.y - _leaderPoint.pos.y != 0) {
            currentAng = atanf((self.position.x - _leaderPoint.pos.x)
                               / (self.position.y - _leaderPoint.pos.y));
        }
        
        ;
        [self setFlipX:(self.position.x < _leaderPoint.pos.x)];
        [self setFlipY:(self.position.y < _leaderPoint.pos.y)];
        
        
        if (!hasMoved) {
            lastAng = currentAng;
            hasMoved = YES;
        } else {
            float angDiff = lastAng - currentAng;
            lastAng = currentAng;
            [[self chipmunkBody] setAngle:(ang + angDiff)];
        }
        
    }
    
    NSLog(@"angle: %f", [[self chipmunkBody] angle]);
    [super draw];
}

- (id)initWithLayer:(HelloWorldLayer *)layer {
    if ((self = [super initWithFile:@"gorilazombie.png"])) {
        _layer = layer;
        
        self.spOpenSteps = nil;
        self.spClosedSteps = nil;
        
        
        float playerMass = 1.0f;
        float playerRadius = 13.0f;
        
        ChipmunkBody *monsterBody = [[layer space] add:[ChipmunkBody bodyWithMass:playerMass andMoment:INFINITY]];
        
        ChipmunkShape *monsterShape = [[layer space] add:[ChipmunkCircleShape circleWithBody:monsterBody radius:playerRadius offset:cpvzero]];
       
        monsterShape.collisionType = @"monster";
        
        
        [self setChipmunkBody:monsterBody];
        
        ChipmunkBody * leaderPoint = [[layer space] add:[ChipmunkBody bodyWithMass:INFINITY andMoment:INFINITY]];
        
       
        self->_leaderPoint = leaderPoint;
    
        ChipmunkPivotJoint* joint = [[layer space] add:[ChipmunkPivotJoint pivotJointWithBodyA:leaderPoint
                                                                                 bodyB:monsterBody
                                                                                anchr1:cpvzero
                                                                                anchr2:cpvzero]];
        joint.maxBias = 200.0f;
        joint.maxForce = 3000.0f;
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
    
    BOOL pathFound = NO;
    self.spOpenSteps = [[NSMutableArray alloc] init];
    self.spClosedSteps = [[NSMutableArray alloc] init];
    
    // Start by adding the from position to the open list
    [self insertInOpenSteps:[[ShortestPathStep alloc] initWithPosition:fromTileCoord]];
    
    do {
        // Get the lowest F cost step
        // Because the list is ordered, the first step is always the one with the lowest F cost
        ShortestPathStep *currentStep = [self.spOpenSteps objectAtIndex:0];
        
        // Add the current step to the closed set
        [self.spClosedSteps addObject:currentStep];
        
        // Remove it from the open list
        // Note that if we wanted to first removing from the open list, care should be taken to the memory
        [self.spOpenSteps removeObjectAtIndex:0];
        
        // If the currentStep is the desired tile coordinate, we are done!
        if (CGPointEqualToPoint(currentStep.position, toTileCoord)) {
            
            [self constructPathAndStartAnimationFromStep:currentStep];
            pathFound = YES;
            ShortestPathStep *tmpStep = currentStep;
            NSLog(@"PATH FOUND :");
            do {
                NSLog(@"%@", tmpStep);
                tmpStep = tmpStep.parent; // Go backward
            } while (tmpStep != nil); // Until there is not more parent
            
            self.spOpenSteps = nil; // Set to nil to release unused memory
            self.spClosedSteps = nil; // Set to nil to release unused memory
            break;
        }
        
        // Get the adjacent tiles coord of the current step
        NSArray *adjSteps = [_layer walkableAdjacentTilesCoordForTileCoord:currentStep.position];
        for (NSValue *v in adjSteps) {
            ShortestPathStep *step = [[ShortestPathStep alloc] initWithPosition:[v CGPointValue]];
            
            // Check if the step isn't already in the closed set
            if ([self.spClosedSteps containsObject:step]) {
                continue; // Ignore it
            }
            
            // Compute the cost from the current step to that step
            int moveCost = [self costToMoveFromStep:currentStep toAdjacentStep:step];
            
            // Check if the step is already in the open list
            NSUInteger index = [self.spOpenSteps indexOfObject:step];
            
            if (index == NSNotFound) { // Not on the open list, so add it
                
                // Set the current step as the parent
                step.parent = currentStep;
                
                // The G score is equal to the parent G score + the cost to move from the parent to it
                step.gScore = currentStep.gScore + moveCost;
                
                // Compute the H score which is the estimated movement cost to move from that step to the desired tile coordinate
                step.hScore = [self computeHScoreFromCoord:step.position toCoord:toTileCoord];
                
                // Adding it with the function which is preserving the list ordered by F score
                [self insertInOpenSteps:step];
            }
            else { // Already in the open list
                step = [self.spOpenSteps objectAtIndex:index]; // To retrieve the old one (which has its scores already computed ;-)
                
                // Check to see if the G score for that step is lower if we use the current step to get there
                if ((currentStep.gScore + moveCost) < step.gScore) {
                    
                    // The G score is equal to the parent G score + the cost to move from the parent to it
                    step.gScore = currentStep.gScore + moveCost;
                    
                    // Now we can removing it from the list without be afraid that it can be released
                    [self.spOpenSteps removeObjectAtIndex:index];
                    
                    // Re-insert it with the function which is preserving the list ordered by F score
                    [self insertInOpenSteps:step];
                }
            }
        }
        
    } while ([self.spOpenSteps count] > 0);
}

- (void)popStepAndAnimate
{
	// Check if there remains path steps to go through
	if ([self.currentMovingPath count] == 0) {
		self.currentMovingPath = nil;
        NSLog(@"out!");
		return;
	}
    
	// Get the next step to move to
	ShortestPathStep *s = [self.currentMovingPath objectAtIndex:0];
    
    [_leaderPoint setPos:[_layer positionForTileCoord:s.position]];
   
    [[self currentMovingPath] removeObjectAtIndex:0];
    
    NSLog(@"update!");
}

- (void)constructPathAndStartAnimationFromStep:(ShortestPathStep *)step
{
    self.shortestPath = [NSMutableArray array];
    
	do {
		if (step.parent != nil) { // Don't add the last step which is the start position (remember we go backward, so the last one is the origin position ;-)
			[self.shortestPath insertObject:step atIndex:0]; // Always insert at index 0 to reverse the path
		}
		step = step.parent; // Go backward
	} while (step != nil); // Until there is no more parents
    
    [self setCurrentMovingPath: [[NSMutableArray alloc] initWithArray:[self.shortestPath copy]]];
    [self schedule:@selector(popStepAndAnimate)
          interval:0.18
            repeat:[self.currentMovingPath count] + 1
             delay:0.0];
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
//
//  ShootingStarView.h
//  Starry Night
//
//  Created by Dan Yu on 1/7/12.
//  Copyright 2012 Mind Console Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// A transparent subview used for drawing the shooting star
// (so erasing it doesn't leave us with a large black streak in the sky)
@interface MCP_ShootingStarView : NSView {

    // Various property vars set by parent view in drawShootingStar
    
    BOOL drawShootingStarForeground;
    int foregroundLineWidth;
    int foregroundX1;
    int foregroundY1;
    int foregroundX2;
    int foregroundY2;
    NSColor *foregroundColor;
    
    BOOL drawShootingStarBackground;
    int backgroundLineWidth;
    int backgroundX1;
    int backgroundY1;
    int backgroundX2;
    int backgroundY2;
    
    NSBezierPath *workPath;
}

@property (assign) BOOL drawShootingStarForeground;
@property (nonatomic, retain) NSColor *foregroundColor;
@property (assign) int foregroundLineWidth;
@property (assign) int foregroundX1;
@property (assign) int foregroundY1;
@property (assign) int foregroundX2;
@property (assign) int foregroundY2;

@property (assign) BOOL drawShootingStarBackground;
@property (assign) int backgroundLineWidth;
@property (assign) int backgroundX1;
@property (assign) int backgroundY1;
@property (assign) int backgroundX2;
@property (assign) int backgroundY2;

@end

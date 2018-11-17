//
//  ScreensaverTemplateView.h
//  Starry Night
//
//  Created by Dan Yu on 1/2012.
//  Copyright (c) 2012, Mind Console Productions. Portions Copyright (c) 2010 Evan Green
//

#import <ScreenSaver/ScreenSaver.h>
#import <QuartzCore/QuartzCore.h>

@interface MCP_StarryNight_View : ScreenSaverView 
{
	// Configure sheet outlets
	IBOutlet id configSheet;
	IBOutlet NSTextField *configVersion;
    IBOutlet NSSlider *configBuildingHeight;
    IBOutlet NSSlider *configBuildingCount;
    IBOutlet NSButton *configFlasher;
    IBOutlet NSButton *configRetroColor;
    IBOutlet NSSlider *configBuildingWidthMin;
    IBOutlet NSSlider *configBuildingWidthMax;
    IBOutlet NSSlider *configStarDensity;
    
    // Various per-instance constants (time vals are kept in milliseconds)
    int starsPerUpdate;
    int buildingPixelsPerUpdate;    
    int minRainWidth;
    int maxRainWidth;
    int rainDropsPerUpdate;
    int flasherPeriodMs;
    int maxShootingStarPeriodMs;
    int maxShootingStarDurationMs;
    float maxShootingStarSpeedX;
    float minShootingStarSpeedY;
    float maxShootingStarSpeedY;
    int maxShootingStarWidth;
    // (non-constants)
    BOOL flasherOn;
    int flasherX;
    int flasherY;
    int flasherTime; 
    BOOL shootingStarActive;
    int shootingStarTime;
    int shootingStarStartX;
    int shootingStarStartY;
    float shootingStarVelocityX;
    float shootingStarVelocityY;
    int shootingStarDuration;
    
    // Building array (stored in a NSObject-compliant NSData)
    NSData *buildingArray; 
    
    // Arrays for drawn items, so we can periodically "erase" them
    // (also for star points, useful for "correcting" stars erased by shooting star trails)
    NSMutableArray *drawnStarPoints;
    NSMutableArray *drawnBuildingPoints;
    int maxDrawnStarPoints; 
    int maxDrawnBuildingPoints; 
    
    NSBezierPath *workPath; // general utility path so we don't have to realloc this every frame
    
	BOOL instanceIsInitialized;
}

// Configure sheet actions
- (IBAction)configCancel:(id)sender;
- (IBAction)configOk:(id)sender;

@end

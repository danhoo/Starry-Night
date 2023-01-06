//
//  StarryNightView.h
//  StarryNight
//
//  Created by dsyu on 12/12/22.
//

#import <ScreenSaver/ScreenSaver.h>

@interface StarryNightView : ScreenSaverView
{
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
    
    // Cached Bitmap we draw into and blit. This gets around
    // recent CG layer changes that clear the draw context on
    // every drawRect call (see https://tinyurl.com/yedkhfke)
    NSBitmapImageRep *cachedBitmap;    
    float cachedBitmapScale;
    NSRect cachedBitmapRect;
    
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
    IBOutlet NSSlider *configRefreshTime;

    IBOutlet NSTextField *configBuildingHeightLabel;
    IBOutlet NSTextField *configBuildingCountLabel;
    IBOutlet NSTextField *configBuildingWidthMinLabel;
    IBOutlet NSTextField *configBuildingWidthMaxLabel;
    IBOutlet NSTextField *configStarDensityLabel;
    IBOutlet NSTextField *configRefreshTimeLabel;
    
    // Timer used to refresh/start-over
    NSTimer *refreshTimer;
}

// Configure sheet actions
- (IBAction)configCancel:(id)sender;
- (IBAction)configOk:(id)sender;
- (IBAction)configBuildingHeightSliderChanged:(id)sender;
- (IBAction)configBuildingCountSliderChanged:(id)sender;
- (IBAction)configBuildingWidthMinSliderChanged:(id)sender;
- (IBAction)configBuildingWidthMaxSliderChanged:(id)sender;
- (IBAction)configStarDensitySliderChanged:(id)sender;
- (IBAction)refreshSliderChanged:(id)sender;

// Refresh timer selector
- (void)refreshTimerCalled;

@end

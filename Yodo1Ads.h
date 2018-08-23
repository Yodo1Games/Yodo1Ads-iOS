//
//  Yodo1Ads.h
//
//
//  Created by hyx on 17/7/14.
//  v3.0.8
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString* const kYodo1AdsVersion;

typedef enum {
    Yodo1AdsEventClose      = 0,//Close
    Yodo1AdsEventFinish     = 1,//Finish playing
    Yodo1AdsEventClick      = 2,//Click ad
    Yodo1AdsEventLoaded     = 3,//Ad load finish
    Yodo1AdsEventDisplay    = 4,//Display success
    Yodo1AdsEventError      = -1,//Error
}Yodo1AdsEvent;

typedef enum {
    Yodo1AdsBannerAdAlignLeft               = 1 << 0,
    Yodo1AdsBannerAdAlignHorizontalCenter   = 1 << 1,
    Yodo1AdsBannerAdAlignRight              = 1 << 2,
    Yodo1AdsBannerAdAlignTop                = 1 << 3,
    Yodo1AdsBannerAdAlignVerticalCenter     = 1 << 4,
    Yodo1AdsBannerAdAlignBottom             = 1 << 5,
}Yodo1AdsBannerAdAlign;

/**
 *  Banner callback
 *  @param adEvent Apecify the ad event.
 */
typedef void (^BannerCallback)(Yodo1AdsEvent adEvent);

/**
 *  Interstitial call back
 *  @param adEvent Apecify the ad event.
 */
typedef void (^InterstitialCallback)(Yodo1AdsEvent adEvent);

/**
 *  Video call back
 *  @param finished Video playing status.
 */
typedef void (^VideoCallback)(BOOL finished);

@interface Yodo1Ads : NSObject

//Init Yodo1Ads with appkey.
+ (void)initWithAppKey:(NSString *)appKey;

//Enable/Disable log
+ (void)setLogEnable:(BOOL)enable;

#pragma mark- Banner
//Set banner's call back
+ (void)setBannerCallback:(BannerCallback)callback;

//Set banner's align
+ (void)setBannerAlign:(Yodo1AdsBannerAdAlign)align;

//Set banner's align,User-controlled viewcontroller
+ (void)setBannerAlign:(Yodo1AdsBannerAdAlign)align
        viewcontroller:(UIViewController*)viewcontroller;

//Set banner's offset
+ (void)setBannerOffset:(CGPoint)point;

//Set the Banner Scale scaling factor x axis direction
//multiple sx,y axis direction multiple sy
+ (void)setBannerScale:(CGFloat)sx sy:(CGFloat)sy;

//Show banner
+ (void)showBanner;

//Hide banner
+ (void)hideBanner;

//Remove banner
+ (void)removeBanner;

#pragma mark- Interstitial

//Set interstitial's callback
+ (void)setInterstitialCallback:(InterstitialCallback)callback;

//Check if interstitial ad is ready to show
+ (BOOL)interstitialIsReady;

//Show interstitial
+ (void)showInterstitial;

//Show interstitial,User-controlled viewcontroller
+ (void)showInterstitial:(UIViewController*)viewcontroller;

#pragma mark- Video

//Set video callback
+ (void)setVideoCallback:(VideoCallback)callback;

//Check if video ad is ready to play
+ (BOOL)videoIsReady;

//Play video ad
+ (void)showVideo;

//Play video ad,User-controlled viewcontroller
+ (void)showVideo:(UIViewController*)viewcontroller;

@end

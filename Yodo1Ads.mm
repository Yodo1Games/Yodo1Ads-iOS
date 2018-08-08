//
//  Yodo1Ads.m
//
//  Created by hyx on 17/7/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Yodo1Ads.h"
#import "Yodo1AdsC.h"
#import "Yodo1UnityTool.h"

#import "Yodo1OnlineParameter.h"
#import "Yodo1Analytics.h"

#ifdef YODO1_ADS_VIDEO
#import "Yodo1AdVideoManager.h"
#endif

#ifdef YODO1_ADS_INTERSTITIAL
#import "Yodo1InterstitialAdManager.h"
#endif

#ifdef YODO1_ADS_BANNER
#import "Yodo1BannerManager.h"
#import "Yodo1BannerDelegate.h"
#endif

#ifdef YODO1_ANALYTICS
#import "Yodo1AnalyticsManager.h"
#endif

///C++
static Banner_callback s_banner_callback;

static Interstitial_callback s_interstitial_callback;

static Video_callback s_video_callback;

//OC
static BannerCallback s_bannerCallback;

static InterstitialCallback s_interstitialCallback;

static VideoCallback s_videoCallback;

//Unity3d
const char* UNITY3D_YODO1ADS_METHOD     = "Yodo1U3dSDKCallBackResult";
static NSString* kYodo1AdsGameObject    = @"Yodo1Ads";//默认

NSString* const kYodo1AdsVersion       = @"3.0.6";

typedef enum {
    Yodo1AdsTypeBanner          = 1001,//Banner
    Yodo1AdsTypeVideo           = 1002,//Video
    Yodo1AdsTypeInterstitial    = 1003//Interstitial
}Yodo1AdsType;

@interface Yodo1AdsDelegate : NSObject

+ (instancetype)instance;

+ (UIViewController*)getRootViewController;

+ (UIViewController*)topMostViewController:(UIViewController*)controller;

+ (NSString *)stringWithJSONObject:(id)obj error:(NSError**)error;

+ (id)JSONObjectWithString:(NSString*)str error:(NSError**)error;

+ (void)unitySendMessageResulTypeWithCode:(Yodo1AdsType)type code:(int)code;

@end

@implementation Yodo1AdsDelegate

+ (instancetype)instance {
    static Yodo1AdsDelegate *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Yodo1AdsDelegate alloc] init];
    });
    
    return sharedInstance;
}

+ (UIViewController*)getRootViewController {
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray* windows = [[UIApplication sharedApplication] windows];
        for (window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView* subView in [window subviews]) {
        UIResponder* responder = [subView nextResponder];
        if ([responder isKindOfClass:[UIViewController class]]) {
            return [Yodo1AdsDelegate topMostViewController:(UIViewController*)responder];
        }
    }
    
    return nil;
}

+ (UIViewController*)topMostViewController:(UIViewController*)controller {
    BOOL isPresenting = NO;
    do {
        // this path is called only on iOS 6+, so -presentedViewController is fine here.
        UIViewController* presented = [controller presentedViewController];
        isPresenting = presented != nil;
        if (presented != nil) {
            controller = presented;
        }
        
    } while (isPresenting);
    
    return controller;
}

+ (NSString*)stringWithJSONObject:(id)obj error:(NSError**)error {
    if (obj) {
        if (NSClassFromString(@"NSJSONSerialization")) {
            NSData* data = nil;
            @try {
                data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:error];
            }
            @catch (NSException* exception)
            {
                *error = [NSError errorWithDomain:[exception description] code:0 userInfo:nil];
                return nil;
            }
            @finally
            {
            }
            
            if (data) {
                return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
    }
    return nil;
}

+ (id)JSONObjectWithString:(NSString*)str error:(NSError**)error {
    if (str) {
        if (NSClassFromString(@"NSJSONSerialization")) {
            return [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                                   options:NSJSONReadingAllowFragments
                                                     error:error];
        }
    }
    return nil;
}

+ (void)unitySendMessageResulTypeWithCode:(Yodo1AdsType)type code:(int)code
{
    if (kYodo1AdsGameObject) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [dict setObject:[NSNumber numberWithInt:type] forKey:@"resulType"];
        [dict setObject:[NSNumber numberWithInt:code] forKey:@"code"];
        NSError* parseJSONError = nil;
        NSString* msg = [Yodo1AdsDelegate stringWithJSONObject:dict error:&parseJSONError];
        if(parseJSONError){
            [dict setObject:@"Convert result to json failed!" forKey:@"msg"];
            msg =  [Yodo1AdsDelegate stringWithJSONObject:dict error:&parseJSONError];
        }
        UnitySendMessage([kYodo1AdsGameObject cStringUsingEncoding:NSUTF8StringEncoding],UNITY3D_YODO1ADS_METHOD,
                         [msg cStringUsingEncoding:NSUTF8StringEncoding] );
    }
}

@end

#ifdef YODO1_ADS_INTERSTITIAL

@interface Yodo1AdsInterstitialDelegate : NSObject<InterstitialAdDelegate>

+ (instancetype)instance;

@end

@implementation Yodo1AdsInterstitialDelegate

+ (instancetype)instance {
    static Yodo1AdsInterstitialDelegate *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Yodo1AdsInterstitialDelegate alloc] init];
    });
    
    return sharedInstance;
}

- (void)interstitialDidLoad {
    if(s_interstitial_callback){
        s_interstitial_callback(Yodo1AdsCEventLoaded);
    }
    if(s_interstitialCallback){
        s_interstitialCallback(Yodo1AdsEventLoaded);
    }
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeInterstitial code:Yodo1AdsEventLoaded];
}

- (void)interstitialDidFailToLoadWithError:(NSError *)error {
    if(s_interstitial_callback){
        s_interstitial_callback(Yodo1AdsCEventError);
    }
    if(s_interstitialCallback){
        s_interstitialCallback(Yodo1AdsEventError);
    }
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeInterstitial code:Yodo1AdsEventError];
}

- (void)interstitialDidShow {
    if(s_interstitial_callback){
        s_interstitial_callback(Yodo1AdsCEventDisplay);
    }
    if(s_interstitialCallback){
        s_interstitialCallback(Yodo1AdsEventDisplay);
    }
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeInterstitial code:Yodo1AdsEventDisplay];
}

- (void)interstitialDidClose {
    if(s_interstitial_callback){
        s_interstitial_callback(Yodo1AdsCEventClose);
    }
    if(s_interstitialCallback){
        s_interstitialCallback(Yodo1AdsEventClose);
    }
    
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeInterstitial code:Yodo1AdsEventClose];
}

- (void)didClickInterstitial {
    if(s_interstitial_callback){
        s_interstitial_callback(Yodo1AdsCEventClick);
    }
    if(s_interstitialCallback){
        s_interstitialCallback(Yodo1AdsEventClick);
    }
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeInterstitial code:Yodo1AdsEventClick];
}

@end

#endif

#ifdef YODO1_ADS_BANNER

@interface Yodo1AdsBannerDelegate : NSObject<Yodo1BannerDelegate>

+ (instancetype)instance;

@end

@implementation Yodo1AdsBannerDelegate

+ (instancetype)instance {
    static Yodo1AdsBannerDelegate *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Yodo1AdsBannerDelegate alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark-BannerAdDelegate

- (void)bannerDidLoad {
    if(s_banner_callback){
        s_banner_callback(Yodo1AdsCEventLoaded);
    }
    
    if(s_bannerCallback){
        s_bannerCallback(Yodo1AdsEventLoaded);
    }
    
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeBanner code:Yodo1AdsEventLoaded];
}

- (void)bannerDidFailToLoadWithError:(NSError *)error {
    if(s_banner_callback){
        s_banner_callback(Yodo1AdsCEventError);
    }
    if(s_bannerCallback){
        s_bannerCallback(Yodo1AdsEventError);
    }
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeBanner code:Yodo1AdsEventError];
}

- (void)bannerWillPresentScreen {
    if(s_banner_callback){
        s_banner_callback(Yodo1AdsCEventDisplay);
    }
    if(s_bannerCallback){
        s_bannerCallback(Yodo1AdsEventDisplay);
    }
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeBanner code:Yodo1AdsEventDisplay];
}

- (void)didClickBanner {
    if(s_banner_callback){
        s_banner_callback(Yodo1AdsCEventClick);
    }
    if(s_bannerCallback){
        s_bannerCallback(Yodo1AdsEventClick);
    }
    [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeBanner code:Yodo1AdsEventClick];
}

@end

#endif


#pragma mark- ///OC实现

@implementation Yodo1Ads

+ (void)initWithAppKey:(NSString *)appKey {
    //初始化在线参数
    [Yodo1OnlineParameter initWithAppKey:appKey channel:@"AppStore"];
    //初始化数据统计
    [[Yodo1Analytics instance]releaseSDKVersion:kYodo1AdsVersion];
    [[Yodo1Analytics instance]initWithAppKey:appKey channelId:@"AppStore"];

#ifdef YODO1_ADS_BANNER
    //初始化Banner
    [[Yodo1BannerManager sharedInstance]initBannerSDK:[Yodo1AdsBannerDelegate instance]];
#endif
#ifdef YODO1_ADS_INTERSTITIAL
    //Interstital 初始化
    [[Yodo1InterstitialAdManager sharedInstance]initInterstitalSDK:[Yodo1AdsInterstitialDelegate instance]];
#endif
#ifdef YODO1_ADS_VIDEO
    //初始化Video
    [[Yodo1AdVideoManager sharedInstance]initAdVideoSDK];
#endif

}

+ (void)setLogEnable:(BOOL)enable {
    [Yodo1OnlineParameter setDebugMode:enable];
    [[Yodo1Analytics instance]setDebugMode:enable];
}

#pragma mark- OCBanner
+ (void)setBannerCallback:(BannerCallback)callback {
    if (callback == nil) {
        return;
    }
    if (s_bannerCallback) {
        s_bannerCallback = nil;
    }
    s_bannerCallback = callback;
}

+ (void)setBannerOffset:(CGPoint)point {
#ifdef YODO1_ADS_BANNER
    [[Yodo1BannerManager sharedInstance]setBannerOffset:point];
#endif
}

+ (void)setBannerScale:(CGFloat)sx sy:(CGFloat)sy {
#ifdef YODO1_ADS_BANNER
    [[Yodo1BannerManager sharedInstance]setBannerScale:sx sy:sy];
#endif
}

+ (void)setBannerAlign:(Yodo1AdsBannerAdAlign)align {
#ifdef YODO1_ADS_BANNER
    [Yodo1Ads setBannerAlign:align viewcontroller:nil];
#endif
}

+ (void)setBannerAlign:(Yodo1AdsBannerAdAlign)align
        viewcontroller:(UIViewController *)viewcontroller {
#ifdef YODO1_ADS_BANNER
    [[Yodo1BannerManager sharedInstance]setBannerAlign:(BannerAlign)align
                                        viewcontroller:viewcontroller?viewcontroller:[Yodo1AdsDelegate getRootViewController]];
#endif
}

+ (void)showBanner {
#ifdef YODO1_ADS_BANNER
    [[Yodo1BannerManager sharedInstance]showBanner];
#endif
}

+ (void)hideBanner {
#ifdef YODO1_ADS_BANNER
    [[Yodo1BannerManager sharedInstance]hideBanner];
#endif
}

+ (void)removeBanner {
#ifdef YODO1_ADS_BANNER
    [[Yodo1BannerManager sharedInstance]removeBanner];
#endif
}

#pragma mark- OCInterstitial

+ (void)setInterstitialCallback:(InterstitialCallback)callback {
    if (callback == nil) {
        return;
    }
    if (s_interstitialCallback) {
        s_interstitialCallback = nil;
    }
    s_interstitialCallback = callback;
}

+ (BOOL)interstitialIsReady {
#ifdef YODO1_ADS_INTERSTITIAL
    return [[Yodo1InterstitialAdManager sharedInstance]interstitialAdReady];
#else
    return NO;
#endif
}

+ (void)showInterstitial {
#ifdef YODO1_ADS_INTERSTITIAL
    [Yodo1Ads showInterstitial:nil];
#endif
}

+ (void)showInterstitial:(UIViewController*)viewcontroller {
#ifdef YODO1_ADS_INTERSTITIAL
    [[Yodo1InterstitialAdManager sharedInstance]showAd:viewcontroller?viewcontroller:[Yodo1AdsDelegate getRootViewController]];
#endif
}


#pragma mark- OCVideo

+ (void)setVideoCallback:(VideoCallback)callback {
    if (callback == nil) {
        return;
    }
    if (s_videoCallback) {
        s_videoCallback = nil;
    }
    s_videoCallback = callback;
}

+ (BOOL)videoIsReady {
#ifdef YODO1_ADS_VIDEO
    return [[Yodo1AdVideoManager sharedInstance]hasAdVideo];
#else
    return NO;
#endif
}

+ (void)showVideo {
#ifdef YODO1_ADS_VIDEO
    [Yodo1Ads showVideo:nil];
#endif
}

+ (void)showVideo:(UIViewController*)viewcontroller {
#ifdef YODO1_ADS_VIDEO
    [[Yodo1AdVideoManager sharedInstance]showAdVideo:viewcontroller?viewcontroller:[Yodo1AdsDelegate getRootViewController]
                                          awardBlock:^(bool finished) {
                                              if (s_videoCallback) {
                                                  s_videoCallback(finished);
                                              }
    }];
#endif
}

@end


#pragma mark- ///Unity3d

#ifdef __cplusplus

extern "C" {
    void Unity3dInitWithAppKey(const char *appKey,const char* gameObject)
    {
        NSString* m_appKey = Yodo1CreateNSString(appKey);
        NSCAssert(m_appKey != nil, @"AppKey 没有设置!");
        
        NSString* m_gameObject = Yodo1CreateNSString(gameObject);
        if (m_gameObject) {
            kYodo1AdsGameObject = m_gameObject;
        }
        NSCAssert(m_gameObject != nil, @"Unity3d gameObject isn't set!");
        
        [Yodo1Ads initWithAppKey:m_appKey];
        
        [Yodo1Ads setVideoCallback:^(BOOL finished) {
            Yodo1AdsEvent adsEvent = Yodo1AdsEventClose;
            if (finished) {
                adsEvent = Yodo1AdsEventFinish;
            }
            [Yodo1AdsDelegate unitySendMessageResulTypeWithCode:Yodo1AdsTypeVideo code:adsEvent];
        }];
    }
    
    void Unity3dSetLogEnable(BOOL enable)
    {
        [Yodo1Ads setLogEnable:enable];
    }

#pragma mark - Unity3dBanner
    
    void Unity3dSetBannerAlign(Yodo1AdsCBannerAdAlign align)
    {
        [Yodo1Ads setBannerAlign:(Yodo1AdsBannerAdAlign)align];
    }
    
    void Unity3dSetBannerOffset(float x,float y)
    {
        [Yodo1Ads setBannerOffset:CGPointMake(x,y)];
    }
    
    void Unity3dSetBannerScale(float sx,float sy)
    {
        [Yodo1Ads setBannerScale:sx sy:sy];
    }
    
    void UnityShowBanner()
    {
        [Yodo1Ads showBanner];
    }
    
    void Unity3dHideBanner()
    {
        [Yodo1Ads hideBanner];
    }
    
    void Unity3dRemoveBanner()
    {
        [Yodo1Ads removeBanner];
    }


#pragma mark - Unity3dInterstitial
    
    bool Unity3dInterstitialIsReady()
    {
        return [Yodo1Ads interstitialIsReady];

    }
    
    
    void Unity3dShowInterstitial()
    {
        [Yodo1Ads showInterstitial];
    }
    

#pragma mark - Unity3dVideo
    
    bool Unity3dVideoIsReady()
    {
        return [Yodo1Ads videoIsReady];
    }
    
    void Unity3dShowVideo()
    {
        [Yodo1Ads showVideo];
    }
}

#endif


#pragma mark- ///C++实现

void Yodo1AdsC::InitWithAppKey(const char *appKey)
{
    NSString* m_appKey = Yodo1CreateNSString(appKey);
    NSCAssert(m_appKey !=nil, @"appKey is null");
    [Yodo1Ads initWithAppKey:m_appKey];
}

void Yodo1AdsC::SetLogEnable(bool enable)
{
    [Yodo1Ads setLogEnable:enable];
}

#pragma mark - C++Banner

void Yodo1AdsC::SetBannerCallback(Banner_callback callback)
{
    if(callback == NULL){
        NSLog(@"Banner callback is null");
        return;
    }
    s_banner_callback = callback;
}

void Yodo1AdsC::SetBannerAlign(Yodo1AdsCBannerAdAlign align)
{
    [Yodo1Ads setBannerAlign:(Yodo1AdsBannerAdAlign)align];
}

void Yodo1AdsC::SetBannerOffset(float x, float y)
{
    [Yodo1Ads setBannerOffset:CGPointMake(x, y)];
}

void Yodo1AdsC::SetBannerScale(float sx,float sy)
{
    [Yodo1Ads setBannerScale:sx sy:sy];
}

void Yodo1AdsC::ShowBanner()
{
    [Yodo1Ads showBanner];
}

void Yodo1AdsC::HideBanner()
{
    [Yodo1Ads hideBanner];
}

void Yodo1AdsC::RemoveBanner()
{
    [Yodo1Ads removeBanner];
}

#pragma mark - C++Interstitial

void Yodo1AdsC::SetInterstitialCallback(Interstitial_callback callback)
{
    if(callback == NULL){
        NSLog(@"interstitial callback is null");
        return;
    }
    s_interstitial_callback = callback;
}


bool Yodo1AdsC::InterstitialIsReady()
{
    return [Yodo1Ads interstitialIsReady];
}


void Yodo1AdsC:: ShowInterstitial()
{
    [Yodo1Ads showInterstitial];
}

#pragma mark - C++Video

void Yodo1AdsC::SetVideoCallback(Video_callback callback)
{
    if (callback == NULL) {
        NSLog(@"video callback is null");
    }
    s_video_callback = callback;
    [Yodo1Ads setVideoCallback:^(BOOL finished) {
        if (s_video_callback) {
            s_video_callback(finished);
        }
    }];
  
}

bool Yodo1AdsC::VideoIsReady()
{
    return [Yodo1Ads videoIsReady];
}

void Yodo1AdsC::ShowVideo()
{
    [Yodo1Ads showVideo];
}


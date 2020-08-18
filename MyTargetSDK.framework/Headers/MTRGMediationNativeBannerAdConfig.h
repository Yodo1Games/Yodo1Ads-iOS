//
//  MTRGMediationNativeBannerAdConfig.h
//  myTargetSDK 5.7.4
//
//  Created by Andrey Seredkin on 11/06/2020.
//  Copyright © 2020 Mail.ru Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MyTargetSDK/MTRGMediationAdConfig.h>
#import <MyTargetSDK/MTRGCachePolicy.h>
#import <MyTargetSDK/MTRGAdChoicesPlacement.h>

@class MTRGPrivacy;

NS_ASSUME_NONNULL_BEGIN

@interface MTRGMediationNativeBannerAdConfig : MTRGMediationAdConfig

@property(nonatomic, readonly) MTRGCachePolicy cachePolicy;
@property(nonatomic, readonly) MTRGAdChoicesPlacement adChoicesPlacement;

+ (instancetype)configWithPlacementId:(NSString *)placementId
							  payload:(nullable NSString *)payload
						 serverParams:(NSDictionary<NSString *, NSString *> *)serverParams
								  age:(nullable NSNumber *)age
							   gender:(MTRGGender)gender
							  privacy:(MTRGPrivacy *)privacy
				 trackLocationEnabled:(BOOL)trackLocationEnabled
						  cachePolicy:(MTRGCachePolicy)cachePolicy
				   adChoicesPlacement:(MTRGAdChoicesPlacement)adChoicesPlacement;

@end

NS_ASSUME_NONNULL_END

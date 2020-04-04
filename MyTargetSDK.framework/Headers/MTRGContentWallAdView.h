//
//  MTRGContentWallAdView.h
//  myTargetSDK 5.4.8
//
//  Created by Anton Bulankin on 05.12.14.
//  Copyright (c) 2014 Mail.ru Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTRGNativePromoBanner.h"
#import "MTRGMediaAdView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTRGContentWallAdView : UIView

@property(nonatomic, nullable) MTRGNativePromoBanner *banner;
@property(nonatomic, nullable) UIColor *backgroundColor;

@property(nonatomic, readonly) UILabel *ageRestrictionsLabel;
@property(nonatomic, readonly) UILabel *adLabel;

@property(nonatomic) UIEdgeInsets contentMargins;
@property(nonatomic) UIEdgeInsets adLabelMargins;
@property(nonatomic) UIEdgeInsets ageRestrictionsMargins;

@property(nonatomic, readonly) MTRGMediaAdView *mediaAdView;
@property(nonatomic) UIEdgeInsets imageMargins;

+ (instancetype)createWithBanner:(MTRGNativePromoBanner *)promoBanner;

- (void)loadImages;

@end

NS_ASSUME_NONNULL_END

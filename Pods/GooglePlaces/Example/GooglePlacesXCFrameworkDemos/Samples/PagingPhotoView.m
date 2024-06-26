/*
 * Copyright 2016 Google LLC. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "GooglePlacesXCFrameworkDemos/Samples/PagingPhotoView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIAccessibility.h>

static const NSTimeInterval kAccessibilityAnnouncementDelay = 1.5 * NSEC_PER_SEC;

/** Class to store the image and text views that display the image and attributions. */
@interface ImageViewAndAttribution : NSObject

@property(nonatomic, strong) UIImageView *imageView;

@property(nonatomic, strong) UITextView *attributionView;

@end

@implementation ImageViewAndAttribution
@end

@implementation AttributedPhoto
@end

@interface PagingPhotoView () <UITextViewDelegate>
@end

@implementation PagingPhotoView {
  /**
   * An array of |ImageViewAndAttribution| objects representing the actual views that are being
   * displayed.
   */
  NSMutableArray<ImageViewAndAttribution *> *_photoImageViews;

  /**
   * Whether we should update the image and attribution view frames on the next |layoutSubviews|
   * call. This should be set to YES whenever the frame is updated or the photos change.
   */
  BOOL _imageLayoutUpdateNeeded;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    _photoImageViews = [NSMutableArray array];
    self.backgroundColor = [UIColor systemBackgroundColor];
    self.pagingEnabled = YES;
    self.accessibilityIdentifier = @"PagingPhotoView";
  }
  return self;
}

- (void)setPhotoList:(NSArray<AttributedPhoto *> *)photoList {
  // First, remove all of the existing image and attribution subviews.
  for (ImageViewAndAttribution *photoView in _photoImageViews) {
    [photoView.imageView removeFromSuperview];
    [photoView.attributionView removeFromSuperview];
  }
  [_photoImageViews removeAllObjects];

  // Add the new images and attributions as subviews.
  _photoList = [photoList copy];
  for (AttributedPhoto *photo in photoList) {
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectZero];
    textView.delegate = self;
    textView.editable = NO;
    textView.attributedText = photo.attributions;
    [self addSubview:textView];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:photo.image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    [self addSubview:imageView];

    ImageViewAndAttribution *attributedView = [[ImageViewAndAttribution alloc] init];
    attributedView.imageView = imageView;
    attributedView.attributionView = textView;
    [_photoImageViews addObject:attributedView];
  }
  [self updateContentSize];
  _imageLayoutUpdateNeeded = YES;
}

- (void)setFrame:(CGRect)frame {
  _imageLayoutUpdateNeeded = YES;

  // We want to make sure that we are still scrolled to the same photo when the frame changes.
  // Measure the current content offset and scroll to the same fraction along the content after the
  // frame change.
  CGFloat scrollOffsetFraction = 0;
  if (self.contentSize.width != 0) {
    scrollOffsetFraction = self.contentOffset.x / self.contentSize.width;
  }
  [super setFrame:frame];
  [UIView performWithoutAnimation:^{
    [self updateContentSize];
    self.contentOffset =
        CGPointMake(scrollOffsetFraction * self.contentSize.width, -self.contentInset.top);
  }];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  if (_imageLayoutUpdateNeeded) {
    [self layoutImages];
    _imageLayoutUpdateNeeded = NO;

    // Re-adjust the content offset to ensure the photos are aligned properly horizontally.
    if (self.contentSize.width != 0) {
      CGFloat scrollOffset =
          (CGFloat)round((self.contentOffset.x / self.contentSize.width) * 10.0f) / 10.0f;
      self.contentOffset =
          CGPointMake(scrollOffset * self.contentSize.width, -self.contentInset.top);
    }
  }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)url
                  inRange:(NSRange)characterRange {
  // Make links clickable.
  return YES;
}

#pragma mark - Helper methods

/**
 * Update the content size of the scroll view based on the number of photos and the view's width.
 * This should be called whenever the frame changes or the number of photos has changed.
 */
- (void)updateContentSize {
  CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, self.contentInset);
  CGFloat usableScrollViewHeight = insetBounds.size.height;

  self.contentSize =
      CGSizeMake(_photoImageViews.count * self.frame.size.width, usableScrollViewHeight);
}

/** Updates the frames of the images and attributions. */
- (void)layoutImages {
  CGFloat contentWidth = 0;
  CGFloat scrollViewWidth = self.bounds.size.width;
  CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, self.contentInset);
  CGFloat usableScrollViewHeight = insetBounds.size.height;

  // Lay out the images one after the other horizontally.
  for (ImageViewAndAttribution *attributedImageView in _photoImageViews) {
    UITextView *attributionView = attributedImageView.attributionView;
    UIImageView *imageView = attributedImageView.imageView;
    [attributionView sizeToFit];
    CGFloat attributionHeight = attributionView.frame.size.height;
    CGFloat imageHeight = usableScrollViewHeight - attributionHeight;
    CGFloat safeAreaX = 0.0f;

    // Take into account the safe areas of the device screen and do not use that space for the
    // attribution text.
    imageHeight -= self.safeAreaInsets.bottom;
    safeAreaX = self.safeAreaInsets.left;

    // Put the attribution view aligned to the same left edge as the photo, in the bottom left
    // corner of the screen.
    attributionView.frame = CGRectMake(contentWidth + safeAreaX, imageHeight,
                                       scrollViewWidth - (2 * safeAreaX), attributionHeight);
    imageView.frame = CGRectMake(contentWidth, 0, scrollViewWidth, imageHeight);
    contentWidth += imageView.frame.size.width;
  }
}

- (void)scrollToPageNumber:(int)pageNumber {
  UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                  _photoImageViews[pageNumber].attributionView.text);

  // Delay to allow attribution author to be read before page number.
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, kAccessibilityAnnouncementDelay), dispatch_get_main_queue(),
      ^{
        UIAccessibilityPostNotification(
            UIAccessibilityPageScrolledNotification,
            [NSString stringWithFormat:@"Page %d of %lu", pageNumber + 1, _photoImageViews.count]);
      });
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  double frameWidth = self.frame.size.width;
  double horizontalContentOffset = self.contentOffset.x;
  if (direction == UIAccessibilityScrollDirectionLeft &&
      horizontalContentOffset < (self.contentSize.width - frameWidth)) {
    self.contentOffset = CGPointMake(horizontalContentOffset + frameWidth, 0);
    int pageNumber = (int)fmax(0, (int)round(self.contentOffset.x / frameWidth));
    [self scrollToPageNumber:pageNumber];
    return YES;
  } else if (direction == UIAccessibilityScrollDirectionRight && horizontalContentOffset > 0) {
    self.contentOffset = CGPointMake(horizontalContentOffset - frameWidth, 0);
    int pageNumber = (int)fmax(0, (int)round(self.contentOffset.x / frameWidth));
    [self scrollToPageNumber:pageNumber];
    return YES;
  }
  return NO;
}

@end

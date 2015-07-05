    //
//  BaseViewController.m
//  RaisedCenterTabBar
//
//  Created by Peter Boctor on 12/15/10.
//
// Copyright (c) 2011 Peter Boctor
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE
//

#import "BaseViewController.h"
#import "HySideScrollingImagePicker.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "IQMediaPickerController.h"

@interface BaseViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, IQMediaPickerControllerDelegate>

@end

@implementation BaseViewController

// Create a view controller and setup it's tab bar item with a title and image
-(UIViewController*) viewControllerWithTabTitle:(NSString*) title image:(UIImage*)image
{
    UIViewController* viewController = [[UIViewController alloc] init];
    viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:image tag:0];
    return viewController;
}

// Create a custom UIButton and add it to the center of our tab bar
-(void) addCenterButtonWithImage:(UIImage*)buttonImage highlightImage:(UIImage*)highlightImage
{
  UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
  button.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
  [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
  [button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];

  CGFloat heightDifference = buttonImage.size.height - self.tabBar.frame.size.height;
  if (heightDifference < 0)
    button.center = self.tabBar.center;
  else
  {
    CGPoint center = self.tabBar.center;
    center.y = center.y - heightDifference/2.0;
    button.center = center;
  }
  
  [self.view addSubview:button];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}


- (void) showMenu{
//    BEShowMenuViewController *showMenuViewController = [[BEShowMenuViewController alloc] init];
//    [[[UIApplication sharedApplication].windows[0] rootViewController] presentViewController:showMenuViewController animated:NO completion:^{
//        ;
//    }];
    
    HySideScrollingImagePicker *hy = [[HySideScrollingImagePicker alloc] initWithCancelStr:@"取消" otherButtonTitles:@[@"拍摄",@"从相册选择"]];
    hy.isMultipleSelection = false;
    __weak __typeof(self) weakSelf = self;
    hy.SeletedImages = ^(NSArray *GetImages, NSInteger Buttonindex){
        
        NSLog(@"GetImages-%@,Buttonindex-%ld",GetImages,(long)Buttonindex);
        if(Buttonindex == 1){
            //还需要判断是否有相片，不如有相片，直接进去编辑页面。如果没有，则进入相机
            if(GetImages && GetImages.count > 0){
                
            }else{
                [weakSelf takePhotoFromCamera];
            }
        }else if(Buttonindex == 2){
            //打开相册
            [weakSelf takePhotoFromPhotoLibrary];
        }
        
    };
    [self.view insertSubview:hy atIndex:[[self.view subviews] count]];
}

- (void)takePhotoFromCamera
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [UIImagePickerController new];
        imagePicker.allowsEditing = NO;
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
//        imagePicker.mediaPicker = self;
//        [self delegatePerformWillPresentImagePicker:imagePicker];
//        UIViewController *controller = [[UIApplication sharedApplication].windows[0] rootViewController];
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)takePhotoFromPhotoLibrary
{
    IQMediaPickerController *controller = [[IQMediaPickerController alloc] init];
    controller.delegate = self;
    [controller setMediaType:IQMediaPickerControllerMediaTypePhotoLibrary];
    controller.allowsPickingMultipleItems = YES;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = nil;
//    [self delegatePerformFinishWithMediaInfo:info];
    if ([[info allKeys] containsObject:UIImagePickerControllerEditedImage]) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:info];
        image = dic[UIImagePickerControllerEditedImage];
    }
    if (_finishBlock) {
        _finishBlock(@[image]);
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    if (_cancelBlock) {
        _cancelBlock();
    }
}

- (void)mediaPickerController:(IQMediaPickerController*)controller didFinishMediaWithInfo:(NSDictionary *)info;
{
    NSLog(@"Info: %@",info);
    
    if(info && info.count > 0){
        NSMutableArray *images = [NSMutableArray array];
        [info enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSArray *imgs = [info objectForKey:key];
            [imgs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *dict = obj;
                if([dict objectForKey:IQMediaImage]){
                    [images addObject:[dict objectForKey:IQMediaImage]];
                }
            }];
        }];
        
        if(_finishBlock){
            _finishBlock(images);
        }
    }
}

- (void)mediaPickerControllerDidCancel:(IQMediaPickerController *)controller;
{
    if (_cancelBlock) {
        _cancelBlock();
    }
}
@end

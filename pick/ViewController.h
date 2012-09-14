//
//  ViewController.h
//  pick
//
//  Created by Echo Yu on 12-04-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import "imageProcess.h"




@interface ViewController :  UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIActionSheetDelegate>

{
    bool newMedia;
    UIImage *currentImg;
    UIImage *tempImg;
    UIImage *edgeImage;
    UIImage *finalImg;
    UIImage *greyscale;
    UIImage *edgedetect;
    UIImage *threshold;
    IplImage *convertImg;
    IplImage *convertTemp; 
    IplImage *edgeTemp;
    IplImage *edgeImg;
    
}



@property (nonatomic,retain) IBOutlet UIImageView *imgV;
@property (nonatomic,retain) UIView *subView;
//@property (nonatomic,retain) UIView *scollView;




-(IBAction)load:(id)sender;
-(IBAction)camera:(id)sender;
-(IBAction)save:(id)sender;
-(IBAction)effects:(id)sender;
-(IBAction)crop:(id)sender;


@end


//
//  imageProcess.h
//  pick
//
//  Created by Echo Yu on 12-04-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>


@interface imageProcess : NSObject 


#pragma mark -
//opencv help function 
+ (UIImage*)UIImageFromIplImage:(IplImage*)image;
+ (IplImage*)CreateIplImageFromUIImage:(UIImage*)image;

#pragma mark -
//fliters implement
+ (UIImage*)sepia:(UIImage*)inImage;
+ (UIImage*)texture:(UIImage*)inImage;
+ (UIImage*)bw:(UIImage*)inImage;
+ (UIImage*)greyscale:(UIImage*)inImage;
+ (UIImage*)threshold:(UIImage*)inImage;
+ (UIImage*)edge:(UIImage*)inImage;
+ (UIImage*)stroke:(UIImage*)inImage;
+ (UIImage*)chiwash:(UIImage*)inImage;



@end

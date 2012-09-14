//
//  imageProcess.m
//  pick
//
//  Created by Echo Yu on 12-04-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



//---------------------Credits to others-------------------
//  Note: listed methods cited from opensource
//  CreateRGBABitmapContext&
//  RequestImagePixelData(UIImage *inImage)
//  (UIImage*)UIImageFromIplImage:(IplImage*)image;
//  (IplImage*)CreateIplImageFromUIImage:(UIImage*)image;


#import "imageProcess.h"
#include <sys/time.h>
#include <math.h>
#include <stdio.h>
#include <string.h>


//------------------------Helper Functions ----------------------------
// Return a bitmap context using alpha/red/green/blue byte values 
CGContextRef CreateRGBABitmapContext (CGImageRef inImage) 
{
	CGContextRef context = NULL; 
	CGColorSpaceRef colorSpace; 
	void *bitmapData; 
	int bitmapByteCount; 
	int bitmapBytesPerRow;
	size_t pixelsWide = CGImageGetWidth(inImage); 
	size_t pixelsHigh = CGImageGetHeight(inImage); 
	bitmapBytesPerRow	= (pixelsWide * 4); 
	bitmapByteCount	= (bitmapBytesPerRow * pixelsHigh); 
	colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL) 
	{
		fprintf(stderr, "Error allocating color space\n"); return NULL;
	}
	// allocate the bitmap & create context 
	bitmapData = malloc( bitmapByteCount ); 
	if (bitmapData == NULL) 
	{
		fprintf (stderr, "Memory not allocated!"); 
		CGColorSpaceRelease( colorSpace ); 
		return NULL;
	}
	context = CGBitmapContextCreate (bitmapData, 
																	 pixelsWide, 
																	 pixelsHigh, 
																	 8, 
																	 bitmapBytesPerRow, 
																	 colorSpace, 
																	 kCGImageAlphaPremultipliedLast);
	if (context == NULL) 
	{
		free (bitmapData); 
		fprintf (stderr, "Context not created!");
	} 
	CGColorSpaceRelease( colorSpace ); 
	return context;
}

// Return Image Pixel data as an RGBA bitmap 
unsigned char *RequestImagePixelData(UIImage *inImage) 
{
	CGImageRef img = [inImage CGImage]; 
	CGSize size = [inImage size];
	CGContextRef cgctx = CreateRGBABitmapContext(img); 
	
	if (cgctx == NULL) 
		return NULL;
	
	CGRect rect = {{0,0},{size.width, size.height}}; 
	CGContextDrawImage(cgctx, rect, img); 
	unsigned char *data = CGBitmapContextGetData (cgctx); 
	CGContextRelease(cgctx);
	return data;
}


//calculate the otsu threshold value
static int otsuThreshold(UIImage* inImg){
    UIImage *currImg;
    //calculate the greyscale threshold value
    currImg = [imageProcess greyscale:inImg];
    
    unsigned char *imgPixel = RequestImagePixelData(currImg);
	CGImageRef currImageRef = [currImg CGImage];
	GLuint w = CGImageGetWidth(currImageRef);
	GLuint h = CGImageGetHeight(currImageRef);
    
    /*
     unsigned char *imgPixel = RequestImagePixelData(inImage);
     CGImageRef inImageRef = [inImage CGImage];
     GLuint w = CGImageGetWidth(inImageRef);
     GLuint h = CGImageGetHeight(inImageRef);*/
    
    float histogram[256]={0};
    
	int count_w = 0;
	int pixel = 0;
    
    //calculate grayscale histogram
    for (GLuint x=0; x<w; x++) {
        pixel = count_w;
        for (GLuint y=0; y<h; y++) {
            int red = (unsigned char)imgPixel[pixel];
			int green = (unsigned char)imgPixel[pixel+1];
			int blue = (unsigned char)imgPixel[pixel+2];
			
			//int graylevel = (int)(0.299*red + 0.587*green + 0.114*blue);
            int graylevel = (red+green+blue)/3;
            histogram[graylevel]+=1;
            
            pixel += 4;
        }
        count_w += w * 4;
    }
    
    GLuint size = w*h;
    
    //normalize histogram
    for (int i=0; i<256; i++) {
        histogram[i]=histogram[i]/size;
    }
    float avg=0;
    for (int i=0; i<256; i++) {
        avg+=i*histogram[i];
    }
    int threshold;
    float maxVariance=0;
    float wi=0, ui=0;
    for (int i=0; i<256; i++) {
        wi+=histogram[i];
        ui+=i*histogram[i];
        float t=avg*wi-ui;
        float variance=t*t/(w*(1-w));
        if (variance>maxVariance) {
            maxVariance = variance;
            threshold=i;
        }
    }
    
    return threshold;
    
}


@implementation imageProcess

#pragma mark -
//Creating UIImage from IplImage
+ (UIImage*)UIImageFromIplImage:(IplImage*)image
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Allocating the buffer for CGImage
    NSData *data =
    [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // Creating CGImage from chunk of IplImage
    CGImageRef imageRef = CGImageCreate(
                                        image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // Getting UIImage from CGImage
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
    
}

//Creating IplImage from UIImage
+ (IplImage*)CreateIplImageFromUIImage:(UIImage*)image
{
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}
    


#pragma mark -
//----------------------------------Black and White Reverse-------------------------------------
//change the black color to white color, white to black
+(UIImage*)bw:(UIImage*)inImage
{
    unsigned char *imgPixel = RequestImagePixelData(inImage);
	CGImageRef inImageRef = [inImage CGImage];
	GLuint w = CGImageGetWidth(inImageRef);
	GLuint h = CGImageGetHeight(inImageRef);
	
	int count_w = 0;
	int pixel = 0;
	
	for(GLuint y = 0;y< h;y++)
	{
		pixel = count_w;
		
		for (GLuint x = 0; x<w; x++) 
		{
			
			int red = (unsigned char)imgPixel[pixel];
			int green = (unsigned char)imgPixel[pixel+1];
			int blue = (unsigned char)imgPixel[pixel+2];
			
			int ava = (int)((red+green+blue)/3.0);
			//NSLog(@"ava is %d",ava);
            int newAva = ava==255 ? 0 : 255 ;
			
			imgPixel[pixel] = newAva;
			imgPixel[pixel+1] = newAva;
			imgPixel[pixel+2] = newAva;
			
			pixel += 4;
		}
		count_w += w * 4;
	}
	
	NSInteger dataLength = w*h* 4;
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imgPixel, dataLength, NULL);
	// prep the ingredients
	int bitsPerComponent = 8;
	int bitsPerPixel = 32;
	int bytesPerRow = 4 * w;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	// make the cgimage
	CGImageRef imageRef = CGImageCreate(w, h, 
                                        bitsPerComponent, 
                                        bitsPerPixel, 
                                        bytesPerRow, 
                                        colorSpaceRef, 
                                        bitmapInfo, 
                                        provider, NULL, NO, renderingIntent);
	
	UIImage *my_Image = [UIImage imageWithCGImage:imageRef];
	
	CFRelease(imageRef);
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);
	return my_Image;
}


//----------------------------------Grayscale-------------------------------------
//original image to grayscale 
+ (UIImage*)greyscale:(UIImage*)inImage
{
	unsigned char *imgPixel = RequestImagePixelData(inImage);
	CGImageRef inImageRef = [inImage CGImage];
	GLuint w = CGImageGetWidth(inImageRef);
	GLuint h = CGImageGetHeight(inImageRef);
	
	int count_w = 0;
	int pixel = 0;
	
	for(GLuint y = 0;y< h;y++)
	{
		pixel = count_w;
		
		for (GLuint x = 0; x<w; x++) 
		{
			//int alpha = (unsigned char)imgPixel[pixel];
			int red = (unsigned char)imgPixel[pixel];
			int green = (unsigned char)imgPixel[pixel+1];
			int blue = (unsigned char)imgPixel[pixel+2];
			
            //float bw =  0.299*red + 0.587*green + 0.114*blue;
			int bw = (int)((red+green+blue)/3.0);
			
			imgPixel[pixel] = bw;
			imgPixel[pixel+1] = bw;
			imgPixel[pixel+2] = bw;
			
			pixel += 4;
		}
		count_w += w * 4;
	}
	
	NSInteger dataLength = w*h* 4;
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imgPixel, dataLength, NULL);
	// prep the ingredients
	int bitsPerComponent = 8;
	int bitsPerPixel = 32;
	int bytesPerRow = 4 * w;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	CGImageRef imageRef = CGImageCreate(w, h, 
																			bitsPerComponent, 
																			bitsPerPixel, 
																			bytesPerRow, 
																			colorSpaceRef, 
																			bitmapInfo, 
																			provider, 
																			NULL, NO, renderingIntent);
	
	UIImage *my_Image = [UIImage imageWithCGImage:imageRef];
	
	CFRelease(imageRef);
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);
	return my_Image;
}



//----------------------------------Threshold-------------------------------------
//create threshold image, otsu value differs among different images 
+ (UIImage*)threshold:(UIImage*)inImage
{
	unsigned char *imgPixel = RequestImagePixelData(inImage);
	CGImageRef inImageRef = [inImage CGImage];
	GLuint w = CGImageGetWidth(inImageRef);
	GLuint h = CGImageGetHeight(inImageRef);
    int otsu = otsuThreshold(inImage);
    NSLog(@"otsu value is %d" , otsu);
	
	int count_w = 0;
	int pixel = 0;
	
	for(GLuint y = 0;y< h;y++)
	{
		pixel = count_w;
		
		for (GLuint x = 0; x<w; x++) 
		{
			
			int red = (unsigned char)imgPixel[pixel];
			int green = (unsigned char)imgPixel[pixel+1];
			int blue = (unsigned char)imgPixel[pixel+2];
			
            
			int ava = (int)((red+green+blue)/3.0);
			//NSLog(@"ava value is %d" , ava);

			int newAva = ava>otsu ? 255 : 0;
            
                       
			imgPixel[pixel] = newAva;
			imgPixel[pixel+1] = newAva;
			imgPixel[pixel+2] = newAva;
			
            
			pixel += 4;
		}
        
		count_w += w * 4;
	}
    
	
	NSInteger dataLength = w*h* 4;
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imgPixel, dataLength, NULL);
	// prep the ingredients
	int bitsPerComponent = 8;
	int bitsPerPixel = 32;
	int bytesPerRow = 4 * w;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	// make the cgimage
	CGImageRef imageRef = CGImageCreate(w, h, 
																			bitsPerComponent, 
																			bitsPerPixel, 
																			bytesPerRow, 
																			colorSpaceRef, 
																			bitmapInfo, 
																			provider, NULL, NO, renderingIntent);
	
	UIImage *my_Image = [UIImage imageWithCGImage:imageRef];
	
	CFRelease(imageRef);
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);
	return my_Image;
}



//----------------------------------Edge Detection-------------------------------------
//convert UIImage to IplImage
//greyscale to edge detection 
//opencv canny edge detection draws white edges on black background
//change it to black lines and white background by calling +(UIImage*)bw:(UIImage*)inImage;
+ (UIImage*)edge:(UIImage*)inImage
{
    int otsu = otsuThreshold(inImage);
    NSLog(@"higher otsu value is %d" , otsu);
    int lowotsu = 0.4*otsu;
    NSLog(@"lower otsu value is %d" , lowotsu);
    
    if (inImage) {
        cvSetErrMode(CV_ErrModeParent);
        
       //create grayscale IplImage from UIImage
		IplImage *origin = [self CreateIplImageFromUIImage:inImage];
		IplImage *greyImg = cvCreateImage(cvGetSize(origin), IPL_DEPTH_8U, 1);
		cvCvtColor(origin, greyImg, CV_BGR2GRAY);
		cvReleaseImage(&origin);
		
		// detect edge
		IplImage *edgeImg = cvCreateImage(cvGetSize(greyImg), IPL_DEPTH_8U, 1);
		cvCanny(greyImg, edgeImg, lowotsu, otsu, 3);
		cvReleaseImage(&greyImg);
        
       
                
		// convert image to 24bit image then convert to UIImage to show
		IplImage *image = cvCreateImage(cvGetSize(edgeImg), IPL_DEPTH_8U, 3);
		for(int y=0; y<edgeImg->height; y++) {
			for(int x=0; x<edgeImg->width; x++) {
				char *p = image->imageData + y * image->widthStep + x * 3;
				*p = *(p+1) = *(p+2) = edgeImg->imageData[y * edgeImg->widthStep + x];
			}
		}
        cvSmooth(image, image, CV_BLUR, 2, 2, 3, 3);
        UIImage *temp = [self UIImageFromIplImage:image];
        UIImage *temp1 = [imageProcess threshold:temp];
        inImage = [imageProcess bw:temp1];
        cvReleaseImage(&edgeImg);
		cvReleaseImage(&image);

    }
   
       
    NSData *imageData = UIImagePNGRepresentation(inImage);
    CIImage *start = [CIImage imageWithData:imageData];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [context createCGImage:start fromRect:[start extent]];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];
    return newImg;
}


//----------------------------------Stroke Drawing-----------------------------------
//edge detection
//blur image, dilate/erode edges by predefined value
+ (UIImage*)stroke:(UIImage *)inImage
{
    //calulate threshold value for cvcanny
    int otsu = otsuThreshold(inImage);
    NSLog(@"higher otsu value is %d" , otsu);
    int lowotsu = 0.4*otsu;
    NSLog(@"lower otsu value is %d" , lowotsu);
    
    if (inImage) {
        cvSetErrMode(CV_ErrModeParent);
        
        
        //Create grayscale IplImage from UIImage
		IplImage *origin = [self CreateIplImageFromUIImage:inImage];
		IplImage *greyImg = cvCreateImage(cvGetSize(origin), IPL_DEPTH_8U, 1);
		cvCvtColor(origin, greyImg, CV_BGR2GRAY);
		cvReleaseImage(&origin);
		
		// Detect edge
		IplImage *edgeImg = cvCreateImage(cvGetSize(greyImg), IPL_DEPTH_8U, 1);
		cvCanny(greyImg, edgeImg, lowotsu, otsu, 3);
		cvReleaseImage(&greyImg);
        
        
        
		// Convert image to 24bit image then convert to UIImage to show
		IplImage *image = cvCreateImage(cvGetSize(edgeImg), IPL_DEPTH_8U, 3);
		for(int y=0; y<edgeImg->height; y++) {
			for(int x=0; x<edgeImg->width; x++) {
				char *p = image->imageData + y * image->widthStep + x * 3;
				*p = *(p+1) = *(p+2) = edgeImg->imageData[y * edgeImg->widthStep + x];
			}
		}
        cvSmooth(image, image, CV_BLUR, 2, 2, 3, 3);
        //cvErode(image, image, 0, 1);
        cvDilate(image, image, 0, 1.2);
       // cvErode(image, image, 0, 1.0);
       // cvMorphologyEx(image, image, image, image, 0, 2);
        cvReleaseImage(&edgeImg);
        UIImage *temp = [self UIImageFromIplImage:image];
        UIImage *temp1 = [imageProcess threshold:temp];
        inImage = [imageProcess bw:temp1];
		cvReleaseImage(&image);
        
    }

    NSData *imageData = UIImagePNGRepresentation(inImage);
    CIImage *start = [CIImage imageWithData:imageData];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [context createCGImage:start fromRect:[start extent]];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];
    return newImg;
}

#pragma mark -

+ (UIImage*)sepia:(UIImage *)inImage
{
    NSData *imageData = UIImagePNGRepresentation(inImage);
    CIImage *start = [CIImage imageWithData:imageData];
    CIContext *context = [CIContext contextWithOptions:nil];
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone" 
                                  keysAndValues: kCIInputImageKey, start, 
                        @"inputIntensity", [NSNumber numberWithFloat:0.8], nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];
    return newImg;

}


//----------------------------------Texture----------------------------------------------
//scale and resize the texture image
//apply the resized texture image as the background image
//apply the blender function from core image (CIMultiplyBlendMode,CIColorBurnBlendMode,CILightenBlendMode)
//for more information refers to the Core Image Filter Reference https://developer.apple.com/library/mac/#documentation/graphicsimaging/reference/CoreImageFilterReference/Reference/reference.html
//texture image are hardcoded, can not selectable at this point, sample.png produce the chines ink wash paper texture
+(UIImage*)texture:(UIImage*)inImage
{
    NSString *texture = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"png"];
    NSURL *texturePath = [NSURL fileURLWithPath:texture];
    CIImage *textureCI = [CIImage imageWithContentsOfURL:texturePath];
    UIImage *textureUI = [[UIImage alloc] initWithCIImage:textureCI];
    
    
    if (CGSizeEqualToSize(inImage.size, textureUI.size)) {
        NSLog(@"size equal");
    }
    else {
        NSLog(@"size not equal");
        CGSize targetSize = inImage.size;
        CGFloat width = textureUI.size.width;
        CGFloat height = textureUI.size.height;
        CGFloat targetWidth = targetSize.width;
        CGFloat targetHeight = targetSize.height;
        CGFloat scaleFactor = 0.0;
        CGFloat scaledWidth = targetWidth;
        CGFloat scaledHeight = targetHeight;
        CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor){
            scaleFactor = widthFactor; 
        }
        else {
            scaleFactor = heightFactor; 
        }
            scaledWidth  = width * scaleFactor;
            scaledHeight = height * scaleFactor;
       
        //centeralize the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        }
        else 
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        
        UIGraphicsBeginImageContext(targetSize); 
        CGRect thumbnailRect = CGRectZero;
        thumbnailRect.origin = thumbnailPoint;
        thumbnailRect.size.width  = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        [textureUI drawInRect:thumbnailRect];
        
        UIImage *textureImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *textureDate = UIImagePNGRepresentation(textureImage);
        CIImage *textureDataCI = [CIImage imageWithData:textureDate];
        
        NSData *imageData = UIImagePNGRepresentation(inImage);
        CIImage *start = [CIImage imageWithData:imageData];
        CIContext *context = [CIContext contextWithOptions:nil];
        CIFilter *filter = [CIFilter filterWithName:@"CIMultiplyBlendMode" 
                                      keysAndValues: kCIInputImageKey, start, 
                            @"inputBackgroundImage", textureDataCI ,nil];
        CIImage *outputImage = [filter outputImage];
        CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
        UIImage *newImg = [UIImage imageWithCGImage:cgimg];
        return newImg;

        
        }
    
}



#pragma mark -
//-----------------------optimized stroke drawing uncomplete----------------------------
//the function is trying to define the threshold area as the stroke drawing not apply
//unfortunately, can't find a way to implement at this point
//now it works as the similar version of sroke() due to the iplimage format 
//result picture shows more like greyscale picture
//since the IplImage* outputImage only stores one channel insteal of 3 channels

+(UIImage*)chiwash:(UIImage*)inImage
{
       
    //calulate threshold value for cvcanny
    int otsu = otsuThreshold(inImage);
    NSLog(@"higher otsu value is %d" , otsu);
    int lowotsu = 0.4*otsu;
    NSLog(@"lower otsu value is %d" , lowotsu);
    

    
    if (inImage) {
        cvSetErrMode(CV_ErrModeParent);
               

        
        //Create grayscale IplImage from UIImage for original input image
		IplImage *origin = [self CreateIplImageFromUIImage:inImage];
		IplImage *greyImg = cvCreateImage(cvGetSize(origin), IPL_DEPTH_8U, 1);
		cvCvtColor(origin, greyImg, CV_BGR2GRAY);
        
        IplImage *threshold = cvCreateImage(cvGetSize(greyImg), IPL_DEPTH_8U, 1);
        cvThreshold(greyImg, threshold, otsu, 255, CV_THRESH_BINARY);
        cvReleaseImage(&origin);
	
	
        // Detect edge
		IplImage *edgeImg = cvCreateImage(cvGetSize(greyImg), IPL_DEPTH_8U, 1);
		cvCanny(greyImg, edgeImg, lowotsu, otsu, 3);
		
      
 
        NSLog(@"convert black and white");
        for (int i=0; i<edgeImg->imageSize; i++) {
            if (edgeImg->imageData[i]==-1) {
                edgeImg->imageData[i]=0;
        
            }
            else {
                edgeImg->imageData[i]=-1;
            }
        }

        
		// Convert image to 24bit image then convert to UIImage to show
		IplImage *image = cvCreateImage(cvGetSize(edgeImg), IPL_DEPTH_8U, 3);
		for(int y=0; y<edgeImg->height; y++) {
			for(int x=0; x<edgeImg->width; x++) {
				char *p = image->imageData + y * image->widthStep + x * 3;
				*p = *(p+1) = *(p+2) = edgeImg->imageData[y * edgeImg->widthStep + x];
			}
		}
        
                 
        cvSmooth(image, image, CV_BLUR, 2, 2, 3, 3);
        //cvErode(image, image, 0, 1);
       // cvDilate(image, image, 0, 1.2);
         cvErode(image, image, 0, 1.0);
        // cvMorphologyEx(image, image, image, image, 0, 2);
        cvReleaseImage(&edgeImg);
        cvReleaseImage(&greyImg);
        inImage = [self UIImageFromIplImage:image];
  
    
    }
    NSData *imageData = UIImagePNGRepresentation(inImage);
    CIImage *start = [CIImage imageWithData:imageData];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [context createCGImage:start fromRect:[start extent]];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];
    return newImg;

    
    
}

@end

//#import "GLUtility.h"
//
//@implementation GLUtility
//
//+ (UIImage *)takeVideoSnapshotOfView:(UIView*)glView
//{
//    // Draw OpenGL data to a UIImage
//    CGFloat scale = UIScreen.mainScreen.scale;
//    
//    CGSize size = CGSizeMake((glView.frame.size.width) * scale,
//                             glView.frame.size.height * scale);
//    
//    //Create buffer for pixels
//    GLuint bufferLength = size.width * size.height * 4;
//    GLubyte* buffer = (GLubyte*)malloc(bufferLength);
//    
//    //Read Pixels from OpenGL
//    float firstPixelX = 0.0f;
//    float firstPixelY = 0.0f;
//    glReadPixels(firstPixelX, firstPixelY, size.width, size.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
//    
//    //Make data provider with data.
//    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
//    
//    //Configure image
//    int bitsPerComponent = 8;
//    int bitsPerPixel = 32;
//    int bytesPerRow = 4 * size.width;
//    
//    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
//    CGBitmapInfo bitmapInfo = (CGBitmapInfo) kCGImageAlphaLast;
//    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
//    CGImageRef iref = CGImageCreate(size.width, size.height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, false, renderingIntent);
//    
//    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
//    CGContextRef context = CGBitmapContextCreate(pixels,
//                                                 size.width,
//                                                 size.height,
//                                                 bitsPerComponent,
//                                                 bytesPerRow,
//                                                 CGImageGetColorSpace(iref),
//                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
//    
//    CGContextTranslateCTM(context, 0.0f, size.height);
//    CGFloat factorScaleXAxis = 1.0f;
//    CGFloat factorScaleYAxis = -1.0f;
//    CGContextScaleCTM(context, factorScaleXAxis, factorScaleYAxis);
//    
//    CGFloat xOffset = 40.0f;
//    CGFloat yOffset = -16.0f;
//    CGFloat rectangleWidth = ((size.width - (6.0f * scale)) / scale) - (xOffset / 2);
//    CGFloat rectangleHeight = (size.height / scale) - (yOffset / 2);
//    
//    // Returns a rectangle with specified coordinate and size values
//    CGRect rectToDraw = CGRectMake(xOffset, yOffset, rectangleWidth, rectangleHeight);
//    CGContextDrawImage(context, rectToDraw, iref);
//    
//    UIImage *outputImage = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
//    
//    //Dealloc
//    CGDataProviderRelease(provider);
//    CGImageRelease(iref);
//    CGContextRelease(context);
//    free(buffer);
//    free(pixels);
//    
//    return outputImage;
//}
//
//
//@end

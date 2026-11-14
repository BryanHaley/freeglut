/*
 * fg_moogl_cocoa.h
 *
 * Copyright (C) The MooGL Project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * MooGL in place of NSOpenGL: a pixel format and a context that answer the
 * messages freeglut sends NSOpenGLPixelFormat and NSOpenGLContext, drawing
 * through MooGL (OpenGL 4.6 on Metal) instead of Apple's OpenGL.
 */

#ifndef FG_MOOGL_COCOA_H
#define FG_MOOGL_COCOA_H

#import <Cocoa/Cocoa.h>

@interface FGMGLPixelFormat : NSObject
- (instancetype)initWithAttributes:(const NSOpenGLPixelFormatAttribute *)attribs;
- (void)getValues:(GLint *)vals forAttribute:(NSOpenGLPixelFormatAttribute)attrib forVirtualScreen:(GLint)screen;
@end

@interface FGMGLContext : NSObject
- (instancetype)initWithFormat:(FGMGLPixelFormat *)format shareContext:(FGMGLContext *)share;
- (void)setView:(NSView *)view;
- (void)makeCurrentContext;
+ (void)clearCurrentContext;
- (void)flushBuffer;
- (void)update;
- (void)clearDrawable;
- (void)setValues:(const GLint *)vals forParameter:(NSOpenGLContextParameter)param;
@end

#endif /* FG_MOOGL_COCOA_H */

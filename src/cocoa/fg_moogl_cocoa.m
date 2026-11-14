/*
 * fg_moogl_cocoa.m
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
 */

#import "fg_moogl_cocoa.h"

/* From libmoogl. MGLRenderer.h needs Metal's headers, so the few calls used
   here are declared instead. */
typedef struct GLMContextRec_t *GLMContext;
extern GLMContext createGLMContext(unsigned format, unsigned type, unsigned depth_format, unsigned depth_type,
                                   unsigned stencil_format, unsigned stencil_type);
extern GLMContext createGLMContextProfile(unsigned format, unsigned type, unsigned depth_format, unsigned depth_type,
                                          unsigned stencil_format, unsigned stencil_type, GLMContext share,
                                          unsigned profile);
extern void destroyGLMContext(GLMContext ctx);
extern void MGLsetCurrentContext(GLMContext ctx);
extern void MGLswapBuffers(GLMContext ctx);
extern void MGLsetSwapInterval(GLMContext ctx, int interval);

@interface MGLRenderer : NSObject
- (void)createMGLRendererAndBindToContext:(GLMContext)glm_ctx view:(NSView *)view;
@end

#define MGL_BGRA                        0x80E1
#define MGL_UNSIGNED_INT_8_8_8_8_REV    0x8367
#define MGL_DEPTH_COMPONENT             0x1902
#define MGL_FLOAT                       0x1406
#define MGL_STENCIL_INDEX8              0x8D48
#define MGL_UNSIGNED_BYTE               0x1401
#define MGL_CORE_PROFILE                0x1
#define MGL_COMPATIBILITY_PROFILE       0x2

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/* the attributes that are followed by a value */
static BOOL takesValue( NSOpenGLPixelFormatAttribute a )
{
    switch ( a ) {
    case NSOpenGLPFAAuxBuffers:
    case NSOpenGLPFAColorSize:
    case NSOpenGLPFAAlphaSize:
    case NSOpenGLPFADepthSize:
    case NSOpenGLPFAStencilSize:
    case NSOpenGLPFAAccumSize:
    case NSOpenGLPFARendererID:
    case NSOpenGLPFAScreenMask:
    case NSOpenGLPFASampleBuffers:
    case NSOpenGLPFASamples:
    case NSOpenGLPFAOpenGLProfile:
    case NSOpenGLPFAVirtualScreenCount:
        return YES;
    default:
        return NO;
    }
}

@implementation FGMGLPixelFormat
{
@public
    GLint depth, stencil, profile;
    BOOL doubleBuffer;
}

- (instancetype)initWithAttributes:(const NSOpenGLPixelFormatAttribute *)attribs
{
    self = [super init];
    if ( !self )
        return nil;

    profile = NSOpenGLProfileVersionLegacy;

    for ( const NSOpenGLPixelFormatAttribute *a = attribs; a && *a; a++ ) {
        GLint value = takesValue( *a ) ? (GLint)a[1] : 1;

        switch ( *a ) {
        case NSOpenGLPFADepthSize:     depth = value;              break;
        case NSOpenGLPFAStencilSize:   stencil = value;            break;
        case NSOpenGLPFAOpenGLProfile: profile = value;            break;
        case NSOpenGLPFADoubleBuffer:  doubleBuffer = YES;         break;
        default:                                                   break;
        }

        if ( takesValue( *a ) )
            a++;
    }

    return self;
}

/* what MooGL gives, which is not always what was asked for */
- (void)getValues:(GLint *)vals forAttribute:(NSOpenGLPixelFormatAttribute)attrib forVirtualScreen:(GLint)screen
{
    (void)screen;

    switch ( attrib ) {
    case NSOpenGLPFAColorSize:     *vals = 24;                         break;
    case NSOpenGLPFAAlphaSize:     *vals = 8;                          break;
    case NSOpenGLPFADepthSize:     *vals = depth > 0 ? 32 : 0;         break;
    case NSOpenGLPFAStencilSize:   *vals = stencil > 0 ? 8 : 0;        break;
    case NSOpenGLPFADoubleBuffer:  *vals = 1;                          break;
    case NSOpenGLPFAOpenGLProfile: *vals = profile;                    break;
    case NSOpenGLPFAAccelerated:   *vals = 1;                          break;
    default:                       *vals = 0;                          break;
    }
}

@end

@implementation FGMGLContext
{
    FGMGLPixelFormat *format;
    FGMGLContext *share;
    GLMContext ctx;
    MGLRenderer *renderer;
}

/* MooGL has to have a context current for GL calls to land anywhere */
static GLMContext placeholder( void )
{
    static GLMContext p = NULL;

    if ( p == NULL )
        p = createGLMContext( 0, 0, 0, 0, 0, 0 );
    return p;
}

- (instancetype)initWithFormat:(FGMGLPixelFormat *)fmt shareContext:(FGMGLContext *)shareWith
{
    self = [super init];
    if ( !self )
        return nil;

    format = [fmt retain];
    share = [shareWith retain];
    return self;
}

/* the context is made here, once there is a view to draw into */
- (void)setView:(NSView *)view
{
    if ( ctx || !view )
        return;

    BOOL core = format->profile != NSOpenGLProfileVersionLegacy;

    ctx = createGLMContextProfile( MGL_BGRA, MGL_UNSIGNED_INT_8_8_8_8_REV,
                                   format->depth > 0 ? MGL_DEPTH_COMPONENT : 0, format->depth > 0 ? MGL_FLOAT : 0,
                                   format->stencil > 0 ? MGL_STENCIL_INDEX8 : 0,
                                   format->stencil > 0 ? MGL_UNSIGNED_BYTE : 0,
                                   share ? share->ctx : NULL, core ? MGL_CORE_PROFILE : MGL_COMPATIBILITY_PROFILE );
    if ( !ctx )
        return;

    renderer = [[MGLRenderer alloc] init];
    [renderer createMGLRendererAndBindToContext:ctx view:view];
}

- (void)makeCurrentContext
{
    MGLsetCurrentContext( ctx ? ctx : placeholder() );
}

+ (void)clearCurrentContext
{
    MGLsetCurrentContext( placeholder() );
}

- (void)flushBuffer
{
    if ( ctx )
        MGLswapBuffers( ctx );
}

/* MooGL follows the view's size at each swap */
- (void)update
{
}

/* the view goes away with the window; the context is destroyed with this object */
- (void)clearDrawable
{
}

- (void)setValues:(const GLint *)vals forParameter:(NSOpenGLContextParameter)param
{
    if ( ctx && param == NSOpenGLContextParameterSwapInterval )
        MGLsetSwapInterval( ctx, vals[0] );
}

- (void)dealloc
{
    if ( ctx ) {
        MGLsetCurrentContext( placeholder() );
        destroyGLMContext( ctx );
    }
    [renderer release];
    [share release];
    [format release];
    [super dealloc];
}

@end

#pragma clang diagnostic pop

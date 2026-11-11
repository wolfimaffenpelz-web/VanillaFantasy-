"""Real generic Mesa/OpenGL compile/link + synthetic output; NOT a Minecraft test."""
import os
from pathlib import Path
os.environ.setdefault('PYOPENGL_PLATFORM', 'egl')
os.environ.setdefault('EGL_PLATFORM', 'surfaceless')
os.environ.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
from ctypes import c_int
import numpy as np
from OpenGL import EGL, GL
from common import ROOT, SHADERS, source, profiles

def context():
    display = EGL.eglGetDisplay(EGL.EGL_DEFAULT_DISPLAY)
    major, minor, n = c_int(), c_int(), c_int()
    assert EGL.eglInitialize(display, major, minor)
    assert EGL.eglBindAPI(EGL.EGL_OPENGL_API)
    attrs = (c_int * 5)(EGL.EGL_SURFACE_TYPE, EGL.EGL_PBUFFER_BIT,
                       EGL.EGL_RENDERABLE_TYPE, EGL.EGL_OPENGL_BIT, EGL.EGL_NONE)
    configs = (EGL.EGLConfig * 1)()
    assert EGL.eglChooseConfig(display, attrs, configs, 1, n) and n.value
    ctx = EGL.eglCreateContext(display, configs[0], EGL.EGL_NO_CONTEXT,
        (c_int * 7)(0x3098, 3, 0x30FB, 3, 0x30FD, 2, EGL.EGL_NONE))
    assert EGL.eglMakeCurrent(display, EGL.EGL_NO_SURFACE, EGL.EGL_NO_SURFACE, ctx)
    print('Generic GL:', GL.glGetString(GL.GL_VERSION).decode())
    print('Renderer:', GL.glGetString(GL.GL_RENDERER).decode())
    return display, ctx

def compile_program(vertex, fragment, label):
    shaders = []
    program = GL.glCreateProgram()
    for stage, text in ((GL.GL_VERTEX_SHADER, vertex), (GL.GL_FRAGMENT_SHADER, fragment)):
        shader = GL.glCreateShader(stage)
        GL.glShaderSource(shader, text)
        GL.glCompileShader(shader)
        if not GL.glGetShaderiv(shader, GL.GL_COMPILE_STATUS):
            raise AssertionError(f'{label}, stage {stage}: {GL.glGetShaderInfoLog(shader).decode()}')
        GL.glAttachShader(program, shader)
        shaders.append(shader)
    GL.glLinkProgram(program)
    if not GL.glGetProgramiv(program, GL.GL_LINK_STATUS):
        raise AssertionError(f'{label}: {GL.glGetProgramInfoLog(program).decode()}')
    for shader in shaders:
        GL.glDeleteShader(shader)
    return program

def texture(data):
    h, w = data.shape[:2]
    tex = GL.glGenTextures(1)
    GL.glBindTexture(GL.GL_TEXTURE_2D, tex)
    GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_RGBA32F, w, h, 0,
                    GL.GL_RGBA, GL.GL_FLOAT, data)
    GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST)
    GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST)
    GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_CLAMP_TO_EDGE)
    GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_T, GL.GL_CLAMP_TO_EDGE)
    return tex

def output_test():
    w, h = 256, 32
    data = np.ones((h, w, 4), dtype=np.float32)
    data[:, :, :3] = np.linspace(0, 4, w)[None, :, None]
    src = texture(data)
    dest = texture(np.zeros_like(data))
    fb = GL.glGenFramebuffers(1)
    GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, fb)
    GL.glFramebufferTexture2D(GL.GL_FRAMEBUFFER, GL.GL_COLOR_ATTACHMENT0, GL.GL_TEXTURE_2D, dest, 0)
    assert GL.glCheckFramebufferStatus(GL.GL_FRAMEBUFFER) == GL.GL_FRAMEBUFFER_COMPLETE
    program = compile_program(source(SHADERS / 'final.vsh'), source(SHADERS / 'final.fsh'), 'final output')
    GL.glUseProgram(program)
    GL.glActiveTexture(GL.GL_TEXTURE0)
    GL.glBindTexture(GL.GL_TEXTURE_2D, src)
    GL.glUniform1i(GL.glGetUniformLocation(program, 'colortex0'), 0)
    GL.glViewport(0, 0, w, h)
    GL.glBegin(GL.GL_QUADS)
    for u, v, x, y in ((0,0,-1,-1), (1,0,1,-1), (1,1,1,1), (0,1,-1,1)):
        GL.glTexCoord2f(u, v)
        GL.glVertex2f(x, y)
    GL.glEnd()
    pixels = np.frombuffer(GL.glReadPixels(0,0,w,h,GL.GL_RGBA,GL.GL_FLOAT),dtype=np.float32).reshape(h,w,4)
    assert np.isfinite(pixels).all()
    assert (pixels >= 0).all() and (pixels <= 1.0001).all()
    assert np.all(np.diff(pixels[h//2,:,0]) >= -0.00001), 'non-monotonic tonemap'
    assert pixels[h//2,10,0] < pixels[h//2,100,0], 'missing image'
    assert np.allclose(pixels[:,:,3],1), 'final alpha'
    GL.glDeleteProgram(program)
    GL.glDeleteTextures([src, dest])
    GL.glDeleteFramebuffers(1, [fb])
    print('PASS: synthetic HDR ramp rendered; finite, bounded, monotonic output')

def main():
    display, ctx = context()
    count = 0
    for profile, values in profiles().items():
        for path in sorted(SHADERS.rglob('*.vsh')):
            if path.parent.name == 'program':
                continue
            fragment = path.with_suffix('.fsh')
            program = compile_program(source(path, values), source(fragment, values), f'{profile}/{path.relative_to(SHADERS)}')
            GL.glDeleteProgram(program)
            count += 1
    output_test()
    print(f'PASS: {count} program variants compiled and linked')
    EGL.eglMakeCurrent(display, EGL.EGL_NO_SURFACE, EGL.EGL_NO_SURFACE, EGL.EGL_NO_CONTEXT)
    EGL.eglDestroyContext(display, ctx)
    EGL.eglTerminate(display)

if __name__ == '__main__':
    main()

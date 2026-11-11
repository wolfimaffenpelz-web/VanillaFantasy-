"""Real generic Mesa/OpenGL compile/link + synthetic output; NOT a Minecraft test."""
import os
import argparse
import json
from pathlib import Path
os.environ.setdefault('PYOPENGL_PLATFORM', 'egl')
os.environ.setdefault('EGL_PLATFORM', 'surfaceless')
os.environ.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
from ctypes import c_int
import numpy as np
from OpenGL import EGL, GL
from common import ROOT, SHADERS, source, profiles, expand, prepare, options

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

def render(program, w, h, uniforms=None, samplers=None, draw=None):
    GL.glActiveTexture(GL.GL_TEXTURE0)
    dest = texture(np.zeros((h,w,4), dtype=np.float32))
    fb = GL.glGenFramebuffers(1)
    GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, fb)
    GL.glFramebufferTexture2D(GL.GL_FRAMEBUFFER, GL.GL_COLOR_ATTACHMENT0, GL.GL_TEXTURE_2D, dest, 0)
    assert GL.glCheckFramebufferStatus(GL.GL_FRAMEBUFFER) == GL.GL_FRAMEBUFFER_COMPLETE
    GL.glUseProgram(program)
    default_uniforms = {
        'viewWidth': float(w), 'viewHeight': float(h), 'near': 0.1, 'far': 256.0,
        'gbufferModelView': np.eye(4, dtype=np.float32),
        'gbufferModelViewInverse': np.eye(4, dtype=np.float32),
        'gbufferProjectionInverse': np.linalg.inv(perspective(w/h)),
        'cameraPosition': (0.0,64.0,0.0), 'sunPosition': (0.0,100.0,0.0),
        'moonPosition': (0.0,-100.0,0.0), 'shadowLightPosition': (0.0,100.0,0.0),
        'rainStrength': 0.0, 'wetness': 0.0, 'nightVision': 0.0,
        'isEyeInWater': 0, 'fogColor': (0.10,0.22,0.25), 'frameTimeCounter': 0.0}
    for name, value in (default_uniforms | (uniforms or {})).items():
        loc = GL.glGetUniformLocation(program, name)
        if loc < 0:
            continue
        if isinstance(value, np.ndarray):
            GL.glUniformMatrix4fv(loc, 1, GL.GL_TRUE, value.astype(np.float32))
        elif isinstance(value, tuple):
            GL.glUniform3f(loc, *value)
        elif isinstance(value, int):
            GL.glUniform1i(loc, value)
        else:
            GL.glUniform1f(loc, value)
    for unit, (name, tex) in enumerate((samplers or {}).items()):
        GL.glActiveTexture(GL.GL_TEXTURE0 + unit)
        GL.glBindTexture(GL.GL_TEXTURE_2D, tex)
        GL.glUniform1i(GL.glGetUniformLocation(program, name), unit)
    GL.glDisable(GL.GL_BLEND)
    GL.glDisable(GL.GL_DEPTH_TEST)
    GL.glViewport(0, 0, w, h)
    if draw:
        draw(program)
    else:
        GL.glBegin(GL.GL_QUADS)
        for u, v, x, y in ((0,0,-1,-1), (1,0,1,-1), (1,1,1,1), (0,1,-1,1)):
            GL.glTexCoord2f(u, v)
            GL.glVertex2f(x, y)
        GL.glEnd()
    pixels = np.frombuffer(GL.glReadPixels(0,0,w,h,GL.GL_RGBA,GL.GL_FLOAT),dtype=np.float32).reshape(h,w,4)
    assert np.isfinite(pixels).all()
    GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, 0)
    GL.glDeleteTextures([dest])
    GL.glDeleteFramebuffers(1, [fb])
    GL.glActiveTexture(GL.GL_TEXTURE0)
    return pixels

def perspective(aspect):
    f = 1.0 / np.tan(np.deg2rad(70.0) / 2.0)
    n, z = 0.1, 256.0
    return np.array([[f/aspect,0,0,0],[0,f,0,0],[0,0,-(z+n)/(z-n),-2*z*n/(z-n)],
                    [0,0,-1,0]], dtype=np.float32)

def fixture(libraries, body, overrides=None, dimension=0):
    text = f'#version 330 compatibility\n#define WF_DIMENSION {dimension}\n'
    for name in ('options','color','uniforms','math',*libraries):
        text += expand(SHADERS / 'lib' / f'{name}.glsl') + '\n'
    text += 'in vec2 wfTex;\n' + body
    return compile_program(source(SHADERS / 'final.vsh'), prepare(text, overrides), 'GLSL fixture')

def output_test():
    w, h = 2560, 1440
    data = np.ones((h, w, 4), dtype=np.float32)
    data[:, :, :3] = np.linspace(0, 4, w)[None, :, None]
    src = texture(data)
    program = compile_program(source(SHADERS / 'final.vsh'), source(SHADERS / 'final.fsh'), 'final output')
    pixels = render(program, w, h, samplers={'colortex0': src})
    assert (pixels >= 0).all() and (pixels <= 1.0001).all()
    assert np.all(np.diff(pixels[h//2,:,0]) >= -0.00001), 'non-monotonic tonemap'
    assert pixels[h//2,10,0] < pixels[h//2,100,0], 'missing image'
    assert pixels[h//2,-1,0] - pixels[h//2,int(w*0.75),0] > 0.003, 'clipped HDR highlights'
    assert np.allclose(pixels[:,:,3],1), 'final alpha'
    GL.glDeleteProgram(program)
    GL.glDeleteTextures([src])
    print('PASS: 2560x1440 synthetic HDR ramp; finite, bounded, monotonic output')

def numeric_tests():
    for dimension in (0,-1,1):
        program = fixture(('lighting',), '''void main() {
            gl_FragColor = vec4(wfLight(vec3(0.0,0.0,-4.0), vec3(0.0,1.0,0.0),
                               gl_FragCoord.xy / 16.0), 1.0); }''',
                          {'SHADOWS':'0','HAND_LIGHT':'0'}, dimension)
        for sun in ((0.0,100.0,0.0),(100.0,0.0,0.0),(0.0,-100.0,0.0)):
            pixels = render(program,16,16,{'sunPosition':sun,'moonPosition':tuple(-x for x in sun)})
            light = pixels[:,:,:3].mean(axis=2)
            assert (np.diff(light,axis=1) > 0.001).all(), 'level 0/1 contrast or monotonicity lost'
            assert pixels[:,:,:3].min() > 0.01 and pixels.max() < 5.0
        assert GL.glGetUniformLocation(program,'shadowtex0') < 0, 'disabled shadow sampler remains'
        assert GL.glGetUniformLocation(program,'wfHeldLight') < 0, 'disabled handlight remains'
        GL.glDeleteProgram(program)
    print('PASS: actual GLSL lighting at all 16x16 light levels, 3 sun states, 3 dimensions')

    for mode in ('0','1','2'):
        program = fixture(('shadow',), '''void main() {
            vec3 p = vec3((wfTex.x - 0.5)*80.0, 0.0, (wfTex.y - 0.5)*80.0);
            gl_FragColor = vec4(vec3(wfShadow(p,vec3(0,1,0),vec3(0,1,0))),1); }''', {'SHADOW_FILTER':mode})
        for depth, expected in ((0.2,0.2),(0.8,1.0)):
            tex = texture(np.full((1,1,4),depth,dtype=np.float32))
            pixels = render(program,16,16, {'shadowModelView':np.eye(4),
                'shadowProjection':np.diag([1/80,1/80,1/128,1])}, {'shadowtex0':tex})
            assert np.allclose(pixels[:,:,:3],expected,atol=0.001), 'shadow depth comparison'
            GL.glDeleteTextures([tex])
        GL.glDeleteProgram(program)
    print('PASS: lit and occluded receivers for all shadow filters')

    program = fixture(('lighting','water'), '''uniform vec3 testTint;
        void main() { gl_FragColor=wfWater(vec3(0,-1,-5),vec3(0,1,0),testTint,vec3(1),vec2(0.8)); }''',
        {'SHADOWS':'0','HAND_LIGHT':'0'})
    alphas=[]
    for depth in (0.985,0.995,0.9999):
        tex=texture(np.full((1,1,4),depth,dtype=np.float32))
        pixels=render(program,4,4,{'testTint':(0.2,0.5,0.7)},{'depthtex1':tex})
        alphas.append(float(pixels[2,2,3]))
        assert (pixels[:,:,:3]>=0).all() and pixels.max()<5
        GL.glDeleteTextures([tex])
    assert all(b>a for a,b in zip(alphas,alphas[1:])), 'water depth must increase opacity'
    tex=texture(np.full((1,1,4),0.995,dtype=np.float32))
    a=render(program,4,4,{'testTint':(0.2,0.5,0.7)},{'depthtex1':tex})
    b=render(program,4,4,{'testTint':(0.6,0.35,0.1)},{'depthtex1':tex})
    assert np.max(abs(a[:,:,:3]-b[:,:,:3]))>0.01, 'biome tint lost'
    GL.glDeleteTextures([tex]); GL.glDeleteProgram(program)
    print('PASS: water opacity increases with depth; distinct biome tints survive')

    for enabled in ('0','1'):
        program=fixture(('vegetation',), '''void main() {
            vec3 p=vec3(1,0,1); int id=wfTex.x<0.5?0:201;
            gl_FragColor=vec4(wfPlantMotion(p,id,float(wfTex.y>0.5))-p,1); }''',{'VEGETATION':enabled})
        motion=render(program,2,2)[:,:,:3]
        assert np.allclose(motion[0],0) and np.allclose(motion[:,0],0), 'plant base or static block moved'
        if enabled=='0': assert np.allclose(motion,0)
        else: assert 0.001 < np.linalg.norm(motion[1,1]) < 0.04
        GL.glDeleteProgram(program)
    print('PASS: mapped plant tips move, bases and unmapped blocks stay fixed; off disables motion')

    program=fixture(('handlight',), '''void main() {
        gl_FragColor=vec4(wfHandLight(vec3(0,0,-(wfTex.x*12.0+0.1)),vec3(0,0,1)),1); }''',{'HAND_LIGHT':'1'})
    base={'wfHeldLight':15.0,'heldBlockLightValue':15,'heldBlockLightValue2':0,'heldItemId':0}
    a=render(program,32,1,base)
    b=render(program,32,1,base|{'heldItemId':102})
    c=render(program,32,1,base|{'wfHeldLight':0.0})
    assert a[0,0,0]>a[0,0,2] and b[0,0,2]>b[0,0,0]
    assert np.allclose(a[0,-1,:3],0) and np.allclose(c[:,:,:3],0)
    assert (np.diff(a[0,:,0])<=0.00001).all()
    GL.glDeleteProgram(program)
    print('PASS: handlight range, attenuation, off state and soul-item color')

    program=fixture(('sky',), '''void main() {
        vec3 direction=wfNormalize(vec3((wfTex-0.5)*0.019,-1.0));
        gl_FragColor=vec4(wfCelestial(vec3(0),direction),1); }''',{'CELESTIAL_GLOW':'0.0'})
    phases=[]
    for phase in range(8):
        pixels=render(program,64,64,{'moonPosition':(0.0,0.0,-100.0),'moonPhase':phase})
        phases.append(float(pixels[:,:,:3].mean()))
    assert all(a>b for a,b in zip(phases[:4],phases[1:5])), phases
    assert np.allclose(phases[1:4],phases[7:4:-1],atol=0.005), phases
    GL.glDeleteProgram(program)
    print('PASS: eight analytic moon phases, decreasing full-to-new and symmetric crescents')

    # Exercise actual sky and final absorption shaders, including the horizon,
    # camera at the cloud plane, rain, and an underwater camera.
    program=compile_program(source(SHADERS/'final.vsh'),source(SHADERS/'gbuffers_skybasic.fsh'),'sky numerics')
    for height in (64.0,192.0,256.0):
        for rain in (0.0,1.0):
            pixels=render(program,128,64,{'cameraPosition':(0.0,height,0.0),'rainStrength':rain})
            assert (pixels>=0).all() and pixels.max()<5
    GL.glDeleteProgram(program)
    program=compile_program(source(SHADERS/'final.vsh'),source(SHADERS/'final.fsh'),'underwater numerics')
    scene=texture(np.ones((4,4,4),dtype=np.float32))
    outputs=[]
    for d in (0.97,0.999):
        depth=texture(np.full((4,4,4),d,dtype=np.float32))
        pixels=render(program,4,4,{'isEyeInWater':1},{'colortex0':scene,'depthtex0':depth})
        outputs.append(float(pixels[:,:,:3].mean()))
        GL.glDeleteTextures([depth])
    assert outputs[0]>outputs[1], 'underwater absorption must increase with path length'
    GL.glDeleteTextures([scene]); GL.glDeleteProgram(program)
    print('PASS: sky/cloud horizon and rain edge cases; underwater absorption')

def geometry_test():
    program=compile_program(source(SHADERS/'gbuffers_terrain.vsh',{'SHADOWS':'0'}),
                            source(SHADERS/'gbuffers_terrain.fsh',{'SHADOWS':'0'}),'terrain render')
    checker=np.ones((2,2,4),dtype=np.float32)
    checker[0,0]=[1,0.2,0.1,1]
    checker[0,1]=[0.1,1,0.2,1]
    checker[1,0]=[1,1,1,0]
    checker[1,1]=[0.1,0.2,1,1]
    tex=texture(checker)
    def draw(p):
        GL.glMatrixMode(GL.GL_PROJECTION)
        GL.glLoadMatrixf(perspective(2.0).T.copy())
        GL.glMatrixMode(GL.GL_MODELVIEW)
        GL.glLoadIdentity()
        loc=GL.glGetAttribLocation(p,'mc_Entity')
        if loc>=0: GL.glVertexAttrib4f(loc,0,0,0,0)
        GL.glNormal3f(0,1,0)
        GL.glColor4f(0.8,0.8,0.8,1)
        GL.glMultiTexCoord2f(GL.GL_TEXTURE1,15.5/16,15.5/16)
        GL.glBegin(GL.GL_QUADS)
        for u,v,x,y in ((0,0,-5.6,-2.8),(1,0,5.6,-2.8),(1,1,5.6,2.8),(0,1,-5.6,2.8)):
            GL.glTexCoord2f(u,v); GL.glVertex3f(x,y,-4)
        GL.glEnd()
        GL.glMatrixMode(GL.GL_PROJECTION); GL.glLoadIdentity()
        GL.glMatrixMode(GL.GL_MODELVIEW); GL.glLoadIdentity()
        GL.glColor4f(1,1,1,1)
    pixels=render(program,128,64,{'alphaTestRef':0.1},{'gtexture':tex},draw)
    assert pixels[16,32,0]>pixels[16,32,1], 'terrain texture or vertex color missing'
    assert pixels[16,96,1]>pixels[16,96,0], 'terrain texture coordinates missing'
    assert np.allclose(pixels[48,32],0), 'terrain alpha cutout not discarded'
    assert pixels[48,96,2]>pixels[48,96,0], 'terrain projected output missing'
    GL.glDeleteTextures([tex]); GL.glDeleteProgram(program)
    print('PASS: real terrain entry points render projected colored geometry and alpha cutouts')

def configurations():
    configs=profiles()
    defaults={k:v[0] for k,v in options().items()}
    switches=('SHADOWS','BLOOM','VEGETATION','WET_SURFACES','HAND_LIGHT','CLOUDS','WATER_WAVES','WATER_REFLECTIONS')
    configs['AllOff']=defaults|{k:'0' for k in switches}|{'ambientOcclusionLevel':'0.0','ATMOSPHERE':'0.0','CELESTIAL_GLOW':'0.0'}
    configs['AllOn']=defaults|{k:options()[k][1][-1] for k in switches}
    configs['Minimum']={k:v[1][0] for k,v in options().items()}
    configs['Maximum']={k:v[1][-1] for k,v in options().items()}
    for name in switches:
        configs['Toggle_'+name]=defaults|{name:'0' if defaults[name]!='0' else '1'}
    return configs

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--report-dir', type=Path)
    args=parser.parse_args()
    display, ctx = context()
    count = 0
    configs=configurations()
    for profile, values in configs.items():
        for path in sorted(SHADERS.rglob('*.vsh')):
            if path.parent.name == 'program':
                continue
            fragment = path.with_suffix('.fsh')
            program = compile_program(source(path, values), source(fragment, values), f'{profile}/{path.relative_to(SHADERS)}')
            GL.glDeleteProgram(program)
            count += 1
    numeric_tests()
    geometry_test()
    output_test()
    print(f'PASS: {count} program variants compiled and linked')
    if args.report_dir:
        args.report_dir.mkdir(parents=True,exist_ok=True)
        report={'generic_gl':GL.glGetString(GL.GL_VERSION).decode(),
                'renderer':GL.glGetString(GL.GL_RENDERER).decode(),
                'program_variants':count,'configurations':list(configs),
                'dimensions':['Overworld','Nether','End'],
                'synthetic_output_resolution':[2560,1440],
                'numeric_tests':'passed','iris_transformer_tested':False,
                'minecraft_runtime_tested':False,'rtx2080_benchmarked':False}
        (args.report_dir/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    EGL.eglMakeCurrent(display, EGL.EGL_NO_SURFACE, EGL.EGL_NO_SURFACE, EGL.EGL_NO_CONTEXT)
    EGL.eglDestroyContext(display, ctx)
    EGL.eglTerminate(display)

if __name__ == '__main__':
    main()

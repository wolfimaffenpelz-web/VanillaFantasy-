"""Keep identical thin dimension/pass entry points reproducible."""
import argparse
from common import SHADERS

# name: textured, lit, material IDs, entity overlay, water
GEOMETRY = {
    'basic': (0,0,0,0,0), 'textured': (1,0,0,0,0),
    'textured_lit': (1,1,0,0,0), 'terrain': (1,1,1,0,0),
    'entities': (1,1,0,1,0), 'block': (1,1,0,1,0),
    'hand': (1,1,0,1,0), 'water': (1,1,1,0,1),
    'lightning': (0,0,0,0,0),
}

def expected():
    result = {}
    for directory, dimension in (('',0), ('world-1',-1), ('world1',1)):
        for name, values in GEOMETRY.items():
            flags = ''.join(f'#define WF_{key} {value}\n' for key, value in zip(
                ('TEXTURED','LIT','MATERIAL','ENTITY','WATER'), values))
            for stage in ('vsh','fsh'):
                result[SHADERS/directory/f'gbuffers_{name}.{stage}'] = (
                    f'#version 330 compatibility\n#define WF_DIMENSION {dimension}\n'
                    + flags + f'#include "/program/geometry.{stage}"\n')
        for name, vert, frag in (
            ('final', 'fullscreen', 'final'), ('shadow','shadow','shadow'),
            ('shadow_water','shadow','shadow_water'),
            ('gbuffers_skybasic','sky','sky'),
            ('gbuffers_skytextured','sky','discard')):
            for stage, program in (('vsh',vert), ('fsh',frag)):
                result[SHADERS/directory/f'{name}.{stage}'] = (
                    f'#version 330 compatibility\n#define WF_DIMENSION {dimension}\n'
                    + f'#include "/program/{program}.{stage}"\n')
    return result

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    for path, text in expected().items():
        if args.check:
            assert path.read_text() == text, path
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
    print('PASS: generated entry points are consistent' if args.check else 'Entry points generated')

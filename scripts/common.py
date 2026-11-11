"""Small, auditable subset of Iris source expansion for generic GL tests.

This is NOT Iris's AST transformer or a replacement for a game test.
Only include expansion and numeric option substitution are done.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SHADERS = ROOT / 'shaders'
DEFINE = re.compile(r'^#define\s+(\w+)\s+([-\d.]+)\s*//\s*\[([^]]+)\]', re.M)
CONST = re.compile(r'^const\s+(?:int|float)\s+(\w+)\s*=\s*([-\d.]+);\s*//\s*\[([^]]+)\]', re.M)
INCLUDE = re.compile(r'^\s*#include\s+"([^"]+)"\s*$', re.M)

def properties(path):
    result = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        key, sep, value = line.partition('=')
        if not sep or key.strip() in result:
            raise ValueError(f'invalid or duplicate property: {line}')
        result[key.strip()] = value.strip()
    return result

def options():
    result = {}
    for path in SHADERS.rglob('*.glsl'):
        for pattern in (DEFINE, CONST):
            for m in pattern.finditer(path.read_text()):
                name, default, values = m.groups()
                if name in result:
                    raise ValueError(f'duplicate option: {name}')
                result[name] = (default, values.split())
    return result

def profiles():
    result = {'Default': {}}
    for key, value in properties(SHADERS / 'shaders.properties').items():
        if key.startswith('profile.'):
            result[key[8:]] = dict(token.split('=', 1) for token in value.split())
    return result

def expand(path, stack=()):
    path = path.resolve()
    if not path.is_relative_to(SHADERS.resolve()):
        raise ValueError(f'include escapes shaders: {path}')
    if path in stack:
        raise ValueError(f'include cycle: {stack + (path,)}')
    source = path.read_text()
    def inc(match):
        target = match[1]
        child = SHADERS / target[1:] if target.startswith('/') else path.parent / target
        return expand(child, stack + (path,))
    return INCLUDE.sub(inc, source)

def prepare(text, overrides=None):
    for name, value in (overrides or {}).items():
        text = re.sub(r'(^#define\s+' + re.escape(name) + r'\s+)[-\d.]+',
                      lambda m: m[1] + str(value), text, flags=re.M)
        text = re.sub(r'(^const\s+(?:int|float)\s+' + re.escape(name) + r'\s*=\s*)[-\d.]+',
                      lambda m: m[1] + str(value), text, flags=re.M)
    return text

def source(path, overrides=None):
    return prepare(expand(path), overrides)

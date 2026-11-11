"""Structural and configuration regression tests. Does not validate Iris runtime."""
import re
import tempfile
import unittest
from zipfile import ZipFile
from common import SHADERS, ROOT, expand, options, profiles, properties, DEFINE, CONST
from build import build

class Structure(unittest.TestCase):
    def test_entrypoints_and_includes(self):
        for name in ('gbuffers_basic', 'gbuffers_textured', 'gbuffers_textured_lit', 'final'):
            for stage in ('vsh', 'fsh'):
                self.assertTrue((SHADERS / f'{name}.{stage}').is_file())
        for path in SHADERS.rglob('*'):
            if path.suffix in ('.vsh', '.fsh') and path.parent.name != 'program':
                text = expand(path)
                self.assertTrue(text.startswith('#version 330 compatibility\n'), str(path))
                self.assertEqual(text.count('#version'), 1)
                self.assertNotIn('#include', text)
                self.assertEqual(len(re.findall(r'void\s+main\s*\(', text)), 1)

    def test_options_and_profiles(self):
        opts = options()
        for name, (default, values) in opts.items():
            self.assertIn(default, values, name)
            self.assertEqual(len(values), len(set(values)), name)
            texts = '\n'.join(p.read_text() for p in SHADERS.rglob('*')
                              if p.suffix in ('.glsl', '.fsh', '.vsh'))
            # These const values are consumed by Iris, rather than GLSL code.
            if name not in {'ambientOcclusionLevel', 'shadowMapResolution', 'shadowDistance'}:
                self.assertGreater(len(re.findall(r'\b' + name + r'\b', texts)), 1, name)
        for profile, assignments in profiles().items():
            for name, value in assignments.items():
                self.assertIn(name, opts, profile)
                self.assertIn(value, opts[name][1], name)
        if 'Balanced' in profiles():
            self.assertTrue(all(opts[k][0] == v for k, v in profiles()['Balanced'].items()))

    def test_menus(self):
        props = properties(SHADERS / 'shaders.properties')
        opts = options()
        exposed = set()
        graph = {}
        for key, value in props.items():
            if key == 'screen' or (key.startswith('screen.') and not key.endswith('.columns')):
                graph[key] = []
                for token in value.split():
                    if token in ('<empty>', '<profile>'):
                        continue
                    if token.startswith('[') and token.endswith(']'):
                        child = 'screen.' + token[1:-1]
                        self.assertIn(child, props)
                        graph[key].append(child)
                    else:
                        self.assertIn(token, opts)
                        exposed.add(token)
        self.assertEqual(set(opts), exposed, 'orphan or missing menu option')
        self.assertTrue(set(props.get('sliders', '').split()) <= set(opts))
        def visit(key, stack):
            self.assertNotIn(key, stack, 'cyclic menu')
            return {key}.union(*(visit(c, stack + [key]) for c in graph[key]))
        self.assertEqual(visit('screen', []), set(graph), 'unreachable menu')

    def test_reproducible_zip(self):
        with tempfile.TemporaryDirectory() as d:
            a, b = (ROOT / d / 'a.zip'), (ROOT / d / 'b.zip')
            self.assertEqual(build(a), build(b))
            with ZipFile(a) as z:
                names = z.namelist()
                self.assertIn('shaders/final.fsh', names)
                self.assertIn('shaders/shaders.properties', names)
                self.assertIsNone(z.testzip())
                self.assertTrue(all(n.startswith('shaders/') or n == 'LICENSE' for n in names))
                self.assertFalse(any('..' in n.split('/') for n in names))
                self.assertEqual(len(names), len(set(names)))

if __name__ == '__main__':
    unittest.main(verbosity=2)

"""Structural and configuration regression tests. Does not validate Iris runtime."""
import re
import tempfile
import unittest
from zipfile import ZipFile
from common import SHADERS, ROOT, expand, source, options, profiles, properties, DEFINE, CONST
from build import build

class Structure(unittest.TestCase):
    def test_format_directive_preserved_without_glsl_format_symbol(self):
        # Iris scans directive lines inside block comments. The GPU compiler
        # must never need a test-only declaration of RGBA16F to compile final.
        for directory in ('', 'world-1', 'world1'):
            path=SHADERS/directory/'final.fsh'
            text=source(path)
            comments=re.findall(r'/\*(.*?)\*/',text,re.S)
            directive_lines=[line.strip() for comment in comments for line in comment.splitlines()]
            self.assertEqual(directive_lines.count('const int colortex0Format = RGBA16F;'),1)
            executable=re.sub(r'/\*.*?\*/|//[^\n]*','',text,flags=re.S)
            self.assertNotRegex(executable,r'\bRGBA16F\b')
            self.assertEqual(text,expand(path),'compile helper must not inject format constants')

    def test_no_guard_flag_collisions_or_unused_modules(self):
        shader_files=[p for p in SHADERS.rglob('*') if p.suffix in ('.vsh','.fsh','.glsl')]
        guards=set()
        for p in shader_files:
            guards.update(re.findall(r'^#ifndef\s+(\w+)',p.read_text(),re.M))
        entries=[p for p in shader_files if p.suffix!='.glsl' and p.parent.name!='program']
        flags=set()
        for p in entries:
            flags.update(re.findall(r'^#define\s+(\w+)\s+[-\d.]+',p.read_text(),re.M))
        self.assertFalse(guards & flags, 'include guard collides with a pass flag')
        referenced='\n'.join(p.read_text() for p in shader_files)
        for p in shader_files:
            if p not in entries:
                self.assertIn('"/'+p.relative_to(SHADERS).as_posix()+'"',referenced,str(p))

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

    def test_dimension_wrappers(self):
        from generate_entrypoints import expected
        for path, text in expected().items():
            self.assertEqual(path.read_text(), text, str(path))
        entries = {p for p in SHADERS.rglob('*') if p.suffix in ('.vsh', '.fsh') and p.parent.name != 'program'}
        self.assertEqual(entries, set(expected()), 'unexpected or obsolete entry point')

    def test_languages(self):
        locales = [properties(SHADERS / 'lang' / f'{locale}.lang') for locale in ('en_us', 'de_de')]
        self.assertEqual(set(locales[0]), set(locales[1]))
        for locale in locales:
            for name in options():
                self.assertIn('option.' + name, locale)
                self.assertIn('option.' + name + '.comment', locale)
            for key in properties(SHADERS / 'shaders.properties'):
                if key.startswith('screen.') and not key.endswith('.columns'):
                    self.assertIn(key, locale)

    def test_fixed_profiles(self):
        presets = profiles()
        self.assertEqual(set(presets), {'Default', 'Performance', 'Balanced', 'Quality'})
        for name in ('Performance', 'Balanced', 'Quality'):
            self.assertEqual(set(presets[name]), set(options()))

    def test_property_contract(self):
        props=properties(SHADERS/'shaders.properties')
        fixed={'oldLighting','oldHandLight','clouds','sun','moon','stars','screen','sliders'}
        for key,value in props.items():
            self.assertTrue(key in fixed or key.startswith(('screen.','profile.','uniform.float.')),key)
            if key in {'oldLighting','oldHandLight','sun','moon','stars'}:
                self.assertIn(value,{'true','false'},key)
        self.assertIn(props['clouds'],{'off','fast','fancy'})
        self.assertEqual(props['uniform.float.wfHeldLight'],
                         'smooth(91, max(heldBlockLightValue, heldBlockLightValue2), 0.12, 0.20)')
        for file in ('block.properties','item.properties'):
            seen=set()
            for key,value in properties(SHADERS/file).items():
                self.assertRegex(key,r'^(block|item)\.\d+$')
                for material in value.split():
                    self.assertRegex(material,r'^minecraft:[a-z0-9_]+$')
                    self.assertNotIn(material,seen,'ambiguous material mapping')
                    seen.add(material)

    def test_benchmark_rejects_invalid_observations(self):
        from benchmark import summarize
        self.assertAlmostEqual(summarize([10.0]*100)['average_fps'],100.0)
        self.assertAlmostEqual(summarize([10.0]*99+[100.0])['one_percent_low_fps'],10.0)
        for invalid in ([],[0.0],[-1.0],[float('nan')],[float('inf')]):
            with self.assertRaises(ValueError): summarize(invalid)

    def test_repository_deliverables(self):
        for file in ('README.md','INSTALLATION.md','ARCHITECTURE.md','TESTING.md',
                     'CHANGELOG.md','LICENSE','VERSION','docs/RESEARCH.md','docs/STATUS.md',
                     '.github/workflows/validate.yml','.github/workflows/release.yml'):
            self.assertTrue((ROOT/file).is_file(),file)
        for path in ROOT.rglob('*.md'):
            if 'work' in path.relative_to(ROOT).parts:
                continue
            for target in re.findall(r'\]\(([^)]+)\)',path.read_text()):
                if not target.startswith(('https://','http://','#')):
                    self.assertTrue((path.parent/target.split('#')[0]).exists(),f'{path}: {target}')

if __name__ == '__main__':
    unittest.main(verbosity=2)

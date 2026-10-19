import tempfile
import unittest
import warnings
from pathlib import Path
from viewer_test_support import RadarParser

class FinalFrameTests(unittest.TestCase):
    def parse(self, text):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)/'frames.csv'
            path.write_text('ObjId,range,speed,angle\n'+text)
            with warnings.catch_warnings(record=True) as recorded:
                warnings.simplefilter('always')
                parser = RadarParser(path)
        return parser, recorded

    def test_last_open_frame_is_retained_and_flagged(self):
        p, w = self.parse('START,FrameNb:1\n1,10,1,0\nEND,frame\nSTART,FrameNb:2\n2,20,1,0\n')
        self.assertEqual(len(p.frame_index), 2)
        info = list(p.frame_index.values())[-1]
        self.assertTrue(info['incomplete'])
        self.assertEqual(info['count'], 1)
        self.assertEqual(len(w), 1)
        self.assertIn('incomplete', str(w[0].message).lower())
        self.assertEqual(p.get_frame(list(p.frame_index)[-1]).ObjId.iloc[0], 2)

    def test_single_open_frame_avoids_tabular_fallback(self):
        p, w = self.parse('START,FrameNb:4\n1,10,1,0\n')
        self.assertFalse(hasattr(p, 'df_all'))
        self.assertEqual(len(p.get_frame(list(p.frame_index)[0])), 1)
        self.assertEqual(len(w), 1)

    def test_empty_unclosed_frame_is_visible(self):
        p, w = self.parse('START,FrameNb:4\n')
        self.assertEqual(list(p.frame_index.values())[0]['count'], 0)
        self.assertEqual(len(w), 1)

    def test_normal_close_has_no_warning(self):
        p, w = self.parse('START,FrameNb:4\n1,10,1,0\nEND,frame\n')
        self.assertFalse(list(p.frame_index.values())[0]['incomplete'])
        self.assertEqual(len(w), 0)

if __name__ == '__main__': unittest.main()

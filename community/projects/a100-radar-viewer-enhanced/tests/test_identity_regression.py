import tempfile
import unittest
from pathlib import Path
from viewer_test_support import RadarParser

class FrameIdentityTests(unittest.TestCase):
    def parse(self, numbers):
        text = 'ObjId,range,speed,angle\n'
        for i, number in enumerate(numbers):
            tag = '' if number is None else f'FrameNb:{number}'
            text += f'START,{tag}capture\n{i},10,1,0\nEND,frame\n'
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)/'frames.csv'
            path.write_text(text)
            parser = RadarParser(path)
        return parser

    def test_duplicate_numbers_keep_both_captures(self):
        parser = self.parse([8,8])
        self.assertEqual(list(parser.frame_index), [0,1])
        self.assertEqual([parser.get_frame(i).ObjId.iloc[0] for i in [0,1]], [0,1])
        self.assertEqual([parser.get_frame(i).FrameNb.iloc[0] for i in [0,1]], [8,8])

    def test_reset_and_wrap_keep_file_order(self):
        parser = self.parse([65535,0,4,0])
        self.assertEqual(list(parser.frame_index), [0,1,2,3])
        self.assertEqual([parser.frame_index[i]['frame_number'] for i in range(4)], [65535,0,4,0])
        self.assertEqual([parser.get_frame(i).ObjId.iloc[0] for i in range(4)], list(range(4)))

    def test_missing_device_number_is_distinct(self):
        parser = self.parse([0,None,0])
        self.assertEqual(len(parser.frame_index), 3)
        self.assertIsNone(parser.frame_index[1]['frame_number'])
        self.assertEqual(parser.get_frame(1).FrameNb.iloc[0], 1)

if __name__ == '__main__': unittest.main()

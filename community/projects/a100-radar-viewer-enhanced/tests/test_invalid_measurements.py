import runpy
import tempfile
import unittest
from pathlib import Path

import numpy as np

viewer = runpy.run_path(str(Path(__file__).resolve().parents[1] / "radarViewer.py"))


class InvalidMeasurementsTest(unittest.TestCase):
    def read_rows(self, rows, tabular=False):
        header = "ObjId,range,speed,angle,RCS"
        if tabular:
            text = header + ",FrameNb\n" + "\n".join(row + ",1" for row in rows)
        else:
            text = header + "\nSTART,FrameNb:1\n" + "\n".join(rows) + "\nEND,Total:0\n"
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "capture.csv"
            path.write_text(text, encoding="utf-8")
            parser = viewer["RadarParser"](path)
            result = parser.get_frame(1 if tabular else 0)
            if not result.empty:
                self.assertEqual(result.FrameNb.unique().tolist(), [1])
            return result

    def test_bad_measurements_are_dropped_in_both_formats(self):
        for tabular in (False, True):
            for column in (1, 2, 3):
                for bad in ("broken", "", "NaN", "inf", "-inf"):
                    with self.subTest(tabular=tabular, column=column, bad=bad):
                        row = ["1", "10", "2", "30", ""]
                        row[column] = bad
                        result = self.read_rows([",".join(row), "2,20,1,0,0"], tabular)
                        self.assertEqual(result.ObjId.tolist(), [2])

    def test_invalid_ids_are_not_imputed_or_rounded(self):
        result = self.read_rows(["broken,10,1,0,0", "-1,10,1,0,0",
                                 "1.5,10,1,0,0", "inf,10,1,0,0", "0,0,0,0,"], True)
        self.assertEqual(result.ObjId.tolist(), [0])

    def test_negative_range_is_rejected_but_zero_is_valid(self):
        result = self.read_rows(["1,-1,0,0,0", "0,0,0,0,"])
        self.assertEqual(result.ObjId.tolist(), [0])
        self.assertEqual(result[["X", "Y"]].to_numpy().tolist(), [[0.0, 0.0]])
        self.assertEqual(result.RCS.tolist(), [0])

    def test_valid_polar_coordinates_are_preserved(self):
        result = self.read_rows(["1,10,2,30,"])
        self.assertAlmostEqual(result.X.iloc[0], 5 * np.sqrt(3))
        self.assertAlmostEqual(result.Y.iloc[0], 5)

    def test_empty_valid_frame_retains_expected_columns(self):
        result = self.read_rows(["1,broken,1,0,0"])
        self.assertTrue(result.empty)
        self.assertTrue({"ObjId", "range", "X", "Y"}.issubset(result.columns))

    def test_bundled_capture_still_loads(self):
        sample = Path(__file__).resolve().parents[1] / "data/sample.csv"
        parser = viewer["RadarParser"](sample)
        self.assertEqual(len(parser.frame_index), 2463)
        result = parser.get_frame(0)
        self.assertFalse(result.empty)
        self.assertTrue(np.isfinite(result[["range", "speed", "angle", "X", "Y"]]).all().all())


if __name__ == "__main__":
    unittest.main()

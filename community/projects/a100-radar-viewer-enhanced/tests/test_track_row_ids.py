import runpy
import tkinter as tk
import unittest
from pathlib import Path
from unittest.mock import patch

import pandas as pd

viewer = runpy.run_path(str(Path(__file__).resolve().parents[1] / "radarViewer.py"))


def detections(points):
    return pd.DataFrame({"ObjId": range(len(points)),
                         "X": [p[0] for p in points],
                         "Y": [p[1] for p in points]})


class TrackRowIdsTest(unittest.TestCase):
    def setUp(self):
        self.interpreter = tk.Tcl()
        with patch.object(tk, "_default_root", self.interpreter):
            self.tracker = viewer["KalmanTracker"]()

    def test_new_detection_before_matched_detection(self):
        self.tracker.track(detections([(0.0, 0.0)]))
        result = self.tracker.track(detections([(100.0, 0.0), (0.0, 0.0)]))
        self.assertEqual(result.track_id.tolist(), [1, 0])

    def test_rectangular_assignment_preserves_detection_rows(self):
        self.tracker.track(detections([(0.0, 0.0), (20.0, 0.0)]))
        result = self.tracker.track(detections([(100.0, 0.0), (20.0, 0.0), (0.0, 0.0)]))
        self.assertEqual(result.track_id.tolist(), [2, 1, 0])

    def test_outside_gate_gets_new_id_in_its_own_row(self):
        self.tracker.track(detections([(0.0, 0.0), (20.0, 0.0)]))
        result = self.tracker.track(detections([(100.0, 0.0), (0.0, 0.0)]))
        self.assertEqual(result.track_id.tolist(), [2, 0])


if __name__ == "__main__":
    unittest.main()

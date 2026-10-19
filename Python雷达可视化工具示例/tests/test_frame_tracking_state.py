import runpy
import tkinter as tk
import unittest
from pathlib import Path
from unittest.mock import patch

import pandas as pd

viewer = runpy.run_path(str(Path(__file__).resolve().parents[1] / "radarViewer.py"))


def detections(x=None):
    return pd.DataFrame({"ObjId": [] if x is None else [0],
                         "X": [] if x is None else [float(x)],
                         "Y": [] if x is None else [0.0]})


class FrameTrackingStateTest(unittest.TestCase):
    def setUp(self):
        self.interpreter = tk.Tcl()
        with patch.object(tk, "_default_root", self.interpreter):
            self.tracker = viewer["KalmanTracker"]()
        self.player = object.__new__(viewer["RadarPlayer"])
        self.player.tracker = self.tracker
        self.player.current = 10
        self.player.fns = [10, 20, 30, 40, 50]
        self.player._last_tracking_frame = None
        self.player._last_tracking_input = None
        self.player._last_tracking_result = None
        self.player._last_tracking_options = None

    def process(self, x=0):
        data = detections(x)
        return self.player._track_frame(data)

    def test_empty_frames_expire_old_tracks(self):
        self.tracker.track(detections(0))
        for _ in range(4):
            self.tracker.track(detections())
        self.assertEqual(len(self.tracker.tracked_targets), 0)

    def test_same_frame_redraw_does_not_append_history(self):
        result = self.process()
        result.loc[0, "X"] = 999  # A caller must not mutate the cache.
        again = self.process()
        self.assertEqual(len(self.tracker.tracked_targets[0]["history"]), 1)
        self.assertEqual(again.X.tolist(), [0.0])

    def test_sequential_frame_advances_once(self):
        self.process()
        self.player.current = 20
        self.process(0.1)
        self.process(0.1)
        self.assertEqual(len(self.tracker.tracked_targets[0]["history"]), 2)

    def test_seek_resets_instead_of_linking_unrelated_frames(self):
        for destination in (10, 40):
            self.player.current = 10
            self.process()
            self.player.current = 20
            self.process(0.1)
            self.player.current = destination
            self.process(0.2)
            self.assertEqual(len(self.tracker.tracked_targets[0]["history"]), 1)

    def test_changed_input_and_parameters_reset_same_frame(self):
        self.process()
        self.process(0.2)
        self.assertEqual(len(self.tracker.tracked_targets[0]["history"]), 1)
        self.tracker.match_thresh.set(8)
        self.process(0.2)
        self.assertEqual(len(self.tracker.tracked_targets[0]["history"]), 1)

    def test_explicit_reset_invalidates_cached_frame(self):
        self.process()
        self.player.update_frame = lambda: self.process()
        self.player._reset_tracker()
        self.assertEqual(len(self.tracker.tracked_targets[0]["history"]), 1)


if __name__ == "__main__":
    unittest.main()

import unittest
from datetime import datetime, timedelta
import numpy as np
import pandas as pd
from viewer_test_support import KalmanTracker, RadarPlayer

class TimestampTests(unittest.TestCase):
    def setUp(self):
        self.t = KalmanTracker()
        self.start = datetime(2026,1,1)
    def frame(self, seconds, x=0):
        self.t.measurement_timestamp = None if seconds is None else self.start+timedelta(seconds=seconds)
        return self.t.track(pd.DataFrame(dict(ObjId=[0],X=[float(x)],Y=[0.])))

    def test_capture_time_sets_prediction_interval(self):
        self.frame(0)
        self.frame(.2)
        self.assertAlmostEqual(self.t.dt,.2)
        self.assertAlmostEqual(self.t.tracked_targets[0]['F'][0,2],.2)
        self.frame(.7)
        self.assertAlmostEqual(self.t.tracked_targets[0]['F'][0,2],.5)
        self.assertGreater(self.t.tracked_targets[0]['Q'][0,0],0)

    def test_known_velocity_predicts_using_capture_seconds(self):
        self.t.dt = .2
        track = self.t._init_kalman(0.,0.,vx=1.)
        track = self.t._predict(track)
        self.assertAlmostEqual(track['x'][0], .2)
        self.t.dt = .5
        track = self.t._predict(track)
        self.assertAlmostEqual(track['x'][0], .7)

    def test_process_noise_follows_constant_acceleration_model(self):
        self.frame(0); self.frame(.5)
        q=self.t.tracked_targets[0]['Q']
        self.assertGreater(q[0,2],0)
        self.assertAlmostEqual(q[0,0]/q[2,2], .5**2/4)

    def test_missing_timestamp_uses_documented_fallback_and_breaks_delta_chain(self):
        self.frame(0); self.frame(None)
        self.assertAlmostEqual(self.t.dt,.1)
        self.frame(10)
        self.assertAlmostEqual(self.t.dt,.1)
        self.frame(10.3)
        self.assertAlmostEqual(self.t.dt,.3)

    def test_duplicate_or_backward_timestamp_starts_new_state(self):
        for bad in [0.,-.1]:
            self.t.reset()
            self.frame(0)
            self.t.tracked_targets[0]['x'][2]=100
            self.frame(bad)
            np.testing.assert_allclose(next(iter(self.t.tracked_targets.values()))['x'],[0,0,0,0])

    def test_reset_forgets_previous_timestamp(self):
        self.frame(0); self.frame(.5)
        self.t.reset(); self.frame(100)
        self.assertAlmostEqual(self.t.dt,.1)

@unittest.skipUnless(hasattr(RadarPlayer, '_track_frame'), 'Requires companion PR #106')
class TrackingCacheIntegrationTests(unittest.TestCase):
    def test_redraw_and_seek_preserve_clock_semantics(self):
        player = RadarPlayer.__new__(RadarPlayer)
        player.tracker = KalmanTracker()
        player.fns = [0,1,2,3]
        for name in ('_last_tracking_frame', '_last_tracking_input',
                     '_last_tracking_result', '_last_tracking_options'):
            setattr(player,name,None)
        start = datetime(2026,1,1)
        data = pd.DataFrame(dict(ObjId=[0],X=[0.],Y=[0.]))
        def capture(index,seconds,df=data):
            player.current = index
            player.tracker.measurement_timestamp = start+timedelta(seconds=seconds)
            return player._track_frame(df.copy())
        capture(0,0)
        capture(1,.2)
        capture(1,.2)
        self.assertAlmostEqual(player.tracker.dt,.2)
        self.assertEqual(len(player.tracker.tracked_targets[0]['history']),2)
        capture(2,.7,data.iloc[:0])
        self.assertAlmostEqual(player.tracker.dt,.5)
        capture(3,1.)
        self.assertAlmostEqual(player.tracker.dt,.3)
        capture(0,0)
        self.assertAlmostEqual(player.tracker.dt,.1)
        self.assertEqual(len(player.tracker.tracked_targets[0]['history']),1)

if __name__ == '__main__': unittest.main()

import unittest
import numpy as np
import pandas as pd
from viewer_test_support import KalmanTracker

class GatedAssignmentTests(unittest.TestCase):
    def frame(self, tracker, points):
        return tracker.track(pd.DataFrame(dict(ObjId=range(len(points)),
            X=[p[0] for p in points], Y=[p[1] for p in points])))

    def test_maximize_feasible_matches_before_minimizing_distance(self):
        t=KalmanTracker()
        self.frame(t,[(-5.,-3.),(0.,-5.)])
        self.frame(t,[(1.,-1.),(-1.,-5.)])
        self.assertEqual(t.next_id,2)
        self.assertEqual(set(t.tracked_targets),{0,1})
        self.assertTrue(all(v['lost_frames']==0 for v in t.tracked_targets.values()))
        np.testing.assert_allclose(t.tracked_targets[0]['history'][-1],[-1,-5])
        np.testing.assert_allclose(t.tracked_targets[1]['history'][-1],[1,-1])

    def test_all_forbidden_associations_remain_unmatched(self):
        t=KalmanTracker(); self.frame(t,[(0.,0.)])
        self.frame(t,[(10.,0.),(20.,0.)])
        self.assertEqual(t.next_id,3)
        self.assertEqual(t.tracked_targets[0]['lost_frames'],1)

    def test_rectangular_assignment_keeps_available_tracks(self):
        t=KalmanTracker(); self.frame(t,[(-5.,-3.),(0.,-5.)])
        self.frame(t,[(1.,-1.),(-1.,-5.),(100.,100.)])
        self.assertEqual(t.next_id,3)
        self.assertEqual(t.tracked_targets[0]['lost_frames'],0)
        self.assertEqual(t.tracked_targets[1]['lost_frames'],0)

    def test_equal_gate_distance_is_not_accepted(self):
        t=KalmanTracker(); self.frame(t,[(0.,0.)])
        self.frame(t,[(3.,4.)])
        self.assertEqual(t.next_id,2)

if __name__=='__main__': unittest.main()

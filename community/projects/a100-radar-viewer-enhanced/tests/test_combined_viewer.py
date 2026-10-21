import tempfile
import unittest
from datetime import datetime, timedelta
from pathlib import Path
from viewer_test_support import RadarParser, RadarPlayer, KalmanTracker

class CombinedViewerTests(unittest.TestCase):
    def test_parser_clock_cache_empty_frame_and_tracking_compose(self):
        start=datetime(2026,1,1)
        rows=['ObjId,range,speed,angle,RCS']
        captures=[(7,0,['1,10,1,0,0']),
                  (7,.2,['2,broken,1,0,0','1,10.2,1,0,0']),
                  (0,.7,[]),(8,1.,['1,10.5,1,0,0'])]
        for number,seconds,targets in captures:
            rows.extend([f'START,FrameNb:{number}',
                (start+timedelta(seconds=seconds)).strftime('%Y/%m/%d %H:%M:%S:%f')+' ---->'])
            rows.extend(targets)
            rows.append('END,complete')
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'capture.csv'
            path.write_text('\n'.join(rows))
            parser=RadarParser(path)
        self.assertEqual(list(parser.frame_index),[0,1,2,3])
        self.assertEqual(parser.get_frame(1).FrameNb.tolist(),[7])
        self.assertEqual(parser.get_frame(1).ObjId.tolist(),[1])
        player=RadarPlayer.__new__(RadarPlayer)
        player.tracker=KalmanTracker()
        player.fns=list(parser.frame_index)
        for name in ('_last_tracking_frame','_last_tracking_input',
                     '_last_tracking_result','_last_tracking_options'):
            setattr(player,name,None)
        for index in player.fns:
            player.current=index
            player.tracker.measurement_timestamp=parser.frame_index[index]['ts']
            frame=parser.get_frame(index)
            result=player._track_frame(frame)
            if not result.empty: self.assertEqual(result.track_id.tolist(),[0])
            before=len(player.tracker.tracked_targets[0]['history'])
            player._track_frame(frame)
            self.assertEqual(len(player.tracker.tracked_targets[0]['history']),before)
        self.assertEqual(len(player.tracker.tracked_targets[0]['history']),3)
        self.assertEqual(player.tracker.tracked_targets[0]['lost_frames'],0)
        self.assertAlmostEqual(player.tracker.dt,.3)

if __name__=='__main__': unittest.main()

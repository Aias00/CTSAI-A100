import unittest
import warnings
from types import SimpleNamespace
from datetime import datetime
import numpy as np
import pandas as pd
from matplotlib.figure import Figure
from matplotlib.backends.backend_agg import FigureCanvasAgg
from viewer_test_support import RadarPlayer, Variable, plt

class Tree:
    def get_children(self): return []
    def delete(self, *args): pass
    def __setitem__(self, key, value): pass
    def heading(self, *args, **kwargs): pass
    def column(self, *args, **kwargs): pass
    def insert(self, *args, **kwargs): pass

class ColorbarTests(unittest.TestCase):
    def setUp(self):
        warnings.filterwarnings('ignore', message='Glyph .* missing from font')
        self.font_context = plt.rc_context({'font.sans-serif': ['DejaVu Sans']})
        self.font_context.__enter__()
        self.addCleanup(self.font_context.__exit__, None, None, None)
        p = RadarPlayer.__new__(RadarPlayer)
        self.p = p
        self.df = pd.DataFrame(dict(ObjId=[0,1], track_id=[0,1], range=[20.,80.],
            X=[20.,80.],Y=[0.,1.],cluster_id=[0,1],cluster_size=[1,1],
            cluster_center_x=[20.,80.],cluster_center_y=[0.,1.]))
        p.parser = SimpleNamespace(get_frame=lambda _:self.df.copy(),
            frame_index={1:dict(ts=datetime(2026,1,1))})
        p.fns=[1]; p.current=1
        p.filter=SimpleNamespace(apply=lambda df:df)
        p._track_frame=lambda df:df  # Isolate drawing from optional tracking cache.
        p.tracker=SimpleNamespace(track=lambda df:df, tracked_targets={}, enable_tracking=Variable(True))
        p.cluster=SimpleNamespace(cluster=lambda df:df, enable_clustering=Variable(False),
            cluster_colors=plt.get_cmap('tab10',20))
        p.trajectory=SimpleNamespace(draw=lambda ax:None)
        p.info_var=Variable(); p.frame_var=Variable(); p.tree=Tree()
        p.fig=Figure(); p.ax=p.fig.add_subplot(111); p.canvas=FigureCanvasAgg(p.fig)
        p.cbar=None; p.cluster_centers=[]; p.id_texts=[]
        p.init_plot()

    def test_colorbar_tracks_new_scatter_and_range(self):
        self.p.update_frame()
        self.assertIs(self.p.cbar.mappable, self.p.scatter)
        np.testing.assert_allclose(self.p.cbar.mappable.get_clim(), [20,80])
        self.assertEqual(self.p.ax.get_xlabel(), 'Y坐标 (m)')
        self.assertEqual(self.p.ax.get_ylabel(), 'X坐标 (m)')
        self.df['range']=[40.,120.]
        self.p.update_frame()
        self.assertIs(self.p.cbar.mappable,self.p.scatter)
        np.testing.assert_allclose(self.p.cbar.mappable.get_clim(), [40,120])
        self.assertEqual(len(self.p.fig.axes),2)

    def test_cluster_mode_hides_distance_colorbar_and_can_restore(self):
        self.p.cluster.enable_clustering.set(True)
        self.p.update_frame()
        self.assertFalse(self.p.cbar.ax.get_visible())
        self.p.cluster.enable_clustering.set(False)
        self.p.update_frame()
        self.assertTrue(self.p.cbar.ax.get_visible())
        self.assertIs(self.p.cbar.mappable,self.p.scatter)
        self.assertEqual(len(self.p.fig.axes),2)

    def test_empty_frame_hides_stale_colorbar(self):
        self.p.update_frame()
        self.df=self.df.iloc[:0]
        self.p.update_frame()
        self.assertFalse(self.p.cbar.ax.get_visible())

if __name__ == '__main__': unittest.main()

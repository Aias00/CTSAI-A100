"""Render public capture playback with the actual parser and tracker, without Tk GUI."""
import argparse
from pathlib import Path
import tkinter as tk
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter
from radarViewer import RadarParser, KalmanTracker


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data', type=Path, default=Path(__file__).parent / 'data/sample.csv')
    parser.add_argument('--output', type=Path, default=Path(__file__).parent / 'figures')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    # Tcl variables support the real tracker without a display server.
    interpreter = tk.Tcl()
    tk._default_root = interpreter
    capture = RadarParser(args.data)
    tracker = KalmanTracker()
    snapshots = []
    for sequence in list(capture.frame_index)[:80]:
        tracker.measurement_timestamp = capture.frame_index[sequence]['ts']
        points = tracker.track(capture.get_frame(sequence))
        histories = {key: list(value['history']) for key, value in tracker.tracked_targets.items()}
        snapshots.append((sequence, points.copy(), histories))
    if not snapshots:
        raise ValueError('Capture contains no frames')
    plt.rcParams['font.sans-serif'] = ['DejaVu Sans']
    fig, ax = plt.subplots(figsize=(8, 6))
    xs = [x for _, points, _ in snapshots for x in points.X]
    ys = [y for _, points, _ in snapshots for y in points.Y]
    if not xs:
        raise ValueError('Selected frames contain no valid observations')
    def draw(index):
        sequence, points, histories = snapshots[index]
        ax.clear()
        ax.set(xlim=(min(xs)-2, max(xs)+2), ylim=(min(ys)-2, max(ys)+2),
               xlabel='X (m)', ylabel='Y (m)',
               title=f'Community radar viewer | frame {sequence} | {len(points)} observations')
        ax.grid(alpha=.3)
        ax.scatter(points.X, points.Y, c=points.track_id, cmap='tab20', s=24)
        for key, history in histories.items():
            if history:
                x, y = zip(*history)
                ax.plot(x, y, alpha=.5, linewidth=1)
        # Label a few targets to keep the dense real capture readable.
        for row in points.head(6).itertuples():
            ax.annotate(f'ID {row.track_id}', (row.X, row.Y), fontsize=7)
        return []
    animation = FuncAnimation(fig, draw, frames=len(snapshots), interval=100, blit=False)
    animation.save(args.output / 'playback.gif', writer=PillowWriter(fps=10))
    draw(len(snapshots)-1)
    fig.savefig(args.output / 'tracking.png', dpi=120)
    plt.close(fig)
    print(f'{len(capture.frame_index)} capture frames; rendered {len(snapshots)} frames to {args.output}')


if __name__ == '__main__':
    main()

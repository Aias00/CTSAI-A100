"""Load real viewer classes without creating a Tk window or importing TkAgg."""
import ast
import re
import warnings
from pathlib import Path
from datetime import datetime
from collections import deque, defaultdict
from types import SimpleNamespace
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.optimize import linear_sum_assignment

class Variable:
    def __init__(self, value=None): self.value = value
    def get(self): return self.value
    def set(self, value): self.value = value

path = Path(__file__).resolve().parents[1] / 'radarViewer.py'
tree = ast.parse(path.read_text(encoding='utf-8'))
namespace = dict(warnings=warnings, np=np, pd=pd, re=re, datetime=datetime, deque=deque,
                 defaultdict=defaultdict, plt=plt,
                 tk=SimpleNamespace(Tk=object, END='end', CENTER='center'),
                 BooleanVar=Variable, DoubleVar=Variable, IntVar=Variable,
                 linear_sum_assignment=linear_sum_assignment)
exec(compile(ast.Module(body=[node for node in tree.body if isinstance(node, ast.ClassDef)],
                        type_ignores=[]), str(path), 'exec'), namespace)
RadarParser = namespace['RadarParser']
KalmanTracker = namespace['KalmanTracker']
RadarPlayer = namespace['RadarPlayer']

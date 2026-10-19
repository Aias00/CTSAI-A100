# 距离颜色条

距离模式每次刷新后把颜色条关联到当前散点，范围随当前帧距离数据更新。
不同帧的相同颜色不一定表示相同距离，应读取当前颜色条。
聚类模式下颜色表示簇编号，因此隐藏距离颜色条；空帧也隐藏旧颜色条。
返回距离模式时恢复同一个颜色条，避免累积额外坐标轴。

回归使用真实 Matplotlib Agg 画布，不创建 Tk 窗口：
python -m unittest discover -s Python雷达可视化工具示例/tests -p test_color_regression.py -v

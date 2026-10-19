# 跟踪的采集时间

界面在处理每帧前设置 tracker.measurement_timestamp。跟踪器使用相邻有效采集时间
计算 dt，每次预测更新 F 与匀加速过程噪声 Q；播放倍速不参与计算。
支持 datetime 和 ISO 时间字符串。缺失或无效时间使用 0.1 秒回退，并打断时间差链，
避免恢复时间戳后错误累计跨越缺失段的时间。
重复、倒退或混合时区的时间会清理旧运动状态，从当前观测重新建轨。
reset 会清除上次采集时间。缺少时间的旧数据仍兼容。

本修改不代替 Issue #105 的空帧/重绘/跳帧修复，应组合合并 PR #106。
同一帧重绘需要由该 PR 的缓存阻止重复调用 track；本 PR 不把重绘当成时间推进。

回归：python -m unittest discover -s Python雷达可视化工具示例/tests -p test_time_regression.py -v

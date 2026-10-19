# 标记式日志的帧索引

包含 START/END 的日志现在使用从 0 开始的文件内帧序号选择和回放。
设备原始 FrameNb 保存在 frame_index 的 frame_number 元数据及返回表的 FrameNb 列，
可以重复或回绕，不再决定回放顺序。缺少设备帧号时，返回表使用文件内序号。
界面标题同时显示序号和设备帧号。普通矩形 CSV 的分组规则保持原样。

回归：python -m unittest discover -s Python雷达可视化工具示例/tests -p test_identity_regression.py -v

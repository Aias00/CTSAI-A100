# 未闭合的末帧

采集异常中断而缺少 END 时，解析器保留最后一个 START 之后已经写入的记录，
包括没有目标记录的空帧，并在该帧元数据标注 incomplete=True。
同时发出 RuntimeWarning，提醒调用方这不是一帧已确认完整的采集。
正常闭合的标记式帧为 incomplete=False。
该标记只说明帧的闭合状态，不保证 ADC、CSV 字段或目标记录完整性。

回归：python -m unittest discover -s Python雷达可视化工具示例/tests -p test_eof_regression.py -v

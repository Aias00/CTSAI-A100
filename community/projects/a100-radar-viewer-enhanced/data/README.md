# 公开样例数据

`sample.csv` 是仓库公开文件的逐字节副本（只重命名，未筛选或修改）：

`Python雷达可视化工具示例/负30度_Tatget_2026_03_10_15_34_39_CTLRR-300-V2_1_RawTarget.csv`

来源：https://github.com/Super-Radar/CTSAI-A100/tree/9a41e22b22b981d1500e4a28e056407baeb1027f/Python雷达可视化工具示例

沿用仓库 Apache-2.0 许可证，见项目 LICENSE。SHA-256：

```text
a9b41f33a54312e051c1ae510850df2c0a7d99f48af0d8c931587af6f72bd7ab
```

数据为 START/END 分帧的目标日志，包含设备 FrameNb、采集时间及 ObjId、range、speed、angle、RCS 等观测列。解析为 2463 帧，range 单位米，speed 米/秒，angle 度；转换坐标沿用基础示例。文件名包含采集时间和设备标签，但上游没有随此文件提供完整硬件/固件版本、标注真值或采集流程，本项目不推断这些信息，也不据此声称跟踪准确率。

独立目录中保留完整样例供 2463 帧回归使用；Demo 仅展示前 80 帧。可用 `python demo.py --data /path/to/capture.csv` 处理相同格式的公开或自有日志。

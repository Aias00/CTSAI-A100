# Python 雷达可视化：帧、测量值和跟踪修复

本次把 #104、#106、#112、#118、#120、#122、#124、#128 的修改集中到一个可组合验证的模块修复中。

## 行为与兼容性

- 标记式 START/END 日志按文件内从 0 开始的帧序号回放；原始设备 FrameNb 保存在
  frame_index.frame_number 和目标表 FrameNb，可重复、回绕或缺失。普通矩形 CSV 分组规则保持原样。
- 末帧缺少 END 时保留已有记录和空帧，标记 incomplete=True，并发出 RuntimeWarning。
  该标记只描述闭合状态，不保证整帧目标记录完整。
- 必要的身份/测量值先验证再填可选显示字段默认值，坏词元、NaN/Inf、非法 ID 和负距离不生成有效目标。
- 跟踪 ID 按观测行写回。分配前使用距离门限和未匹配选项，先最大化有效关联数，再最小化距离。
- 空数据帧推进预测与丢失计数；同帧重绘复用副本，回退/跳帧、筛选结果或跟踪参数变化时重建状态。
- 跟踪 dt 使用有效采集时间，F/Q 随之更新；缺失或非法时间使用 0.1 秒回退并打断时间差链。
  重复、倒退或不兼容时区的时间清除旧运动状态。播放倍速不改变物理时间。
- 距离颜色条关联当前散点，范围随当前帧变化；跨帧的相同颜色不能视为固定距离。
  聚类和空帧隐藏距离颜色条，恢复距离显示时复用原颜色条轴。

## 验证

从仓库根目录运行：

```sh
python -m pip install numpy pandas scipy matplotlib scikit-learn
MPLBACKEND=Agg PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s Python雷达可视化工具示例/tests -p 'test_*.py' -v
```

测试不创建 Tk 窗口；真实 NumPy/SciPy 跟踪、pandas 解析和 Matplotlib Agg 渲染参与验证，
部分控件使用替身，部分使用 Tcl 变量。综合用例连接重复设备帧号、坏测量值、真实时间间隔、
空帧、同帧重绘与 ID 延续，并保留随附 2463 帧数据的解析检查。
GitHub Actions 统一运行完整测试套件，不再为各修复保留分散 workflow。

本 PR 未进行交互式 GUI 或硬件验证。另一位贡献者的 #89 仍单独评审，其中包含普通 CSV 表头识别、
缺少 SciPy 时降级、聚类噪点中心、Matplotlib colormap API 和播放计时器修复；
本次与其测量 ID 校验有重叠，但不宣称替代整个 #89，也不关闭该 PR。

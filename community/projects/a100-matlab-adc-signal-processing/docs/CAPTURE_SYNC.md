# 相干测角的采集证据

默认四路同步状态未知，距离/速度处理继续，所有角度列输出 NaN，
CSV 增加 CaptureSyncVerified=false，空间图给出无可用位置的说明。
MAT 保存 radarCfg.capture_sync，记录实际使用的同步依据。
文件名中的时间可能是导出时间，不能用来证明同步或不同步。

只有采集系统能证明这些文件来自同一帧且保留通道间相位关系时，才填写：

```matlab
opts.io.capture_sync = struct('verified',true, ...
    'capture_id','DAQ frame identifier', ...
    'evidence','Acquisition record explaining common frame and coherent RX phase', ...
    'files',{{'/absolute/rx0.txt','/absolute/rx1.txt','/absolute/rx2.txt','/absolute/rx3.txt'}});
```

files 必须精确绑定当前加载文件，capture_id/evidence 不得为空。
这是调用方基于采集记录的声明，不是读取器独立认证，也不代表相位标定完成。
不要因为文件名相近或只是希望显示点云就置为 true。随附数据没有在本 PR 中补造同步证据。

旧调用只取 load_adc_dataset 的前两个返回值仍兼容；第三个返回值是同步信息，
统一入口将其传给角度层。直接调用角度函数而未传 cfg.capture_sync 时也默认不可用。
已有示例 PNG/CSV 为历史结果，不代表本次同步校验后的输出。

回归：run_capture_sync_tests（Octave/MATLAB）；run_capture_sync_table_tests（原生 MATLAB）。

# Dart ↔ 仓颉 片段检测比对

`cases.dart` 与 `cangjie/verify/` 是把**同一批输入**（邻域边界毫秒数组 + 视频时长）分别喂给两套实现：

| 侧 | 入口 | 语义 |
| --- | --- | --- |
| Dart | `lib/features/ads/domain/airstrike_detector.dart` 的 `clusterBoundaries` + `segmentsFromBoundaries` | 线上实际运行的实现 |
| 仓颉 | `cangjie/src/ad/airstrike.cj` 的 `clusterBoundaries` + `segmentsFromBoundaries` | 移植实现 |

两边约定默认参数：聚类窗口 12s、最少 2 票、片段 3s–6min、合并间距 2s。

## 跑法

```bash
# 需要 PATH 上有 dart(3.13+) 与 cjpm(1.2.0)
node verify/compare.mjs
```

退出码 0 表示逐行一致。**2026-11-02 实测结果见 [仓颉移植手册](../docs/cangjie-port.md)。**

修改 fixture 时只改 `cases.dart` 与 `cangjie/verify/src/cases.cj` 两处同源数据。
C:\Users\16857\Desktop\dsh\_bilisail\verify-readme-add.md
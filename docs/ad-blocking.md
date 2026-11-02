# 广告屏蔽与 AI 视频广告跳过

## 1. 三层结构

| 层 | 位置 | 行为 |
| --- | --- | --- |
| 列表层 | `lib/domain/ad_card_classifier.dart` + `RecommendationFilter` | 从推荐/搜索/动态移除 commerce 卡片 |
| 弹幕层 | `AdCardClassifier.isAdvertisingDanmaku` | 识别导流/代刷类弹幕文本 |
| 播放层 | `features/ads` + `SponsorRepository` 装饰器 | 跳过视频内广告片段 |

`RecommendationSettings.blockAds` 默认 **true**，并参与 `filterKey`（改了规则会立即重建索引）。
广告判定发生在**关注豁免之前**：关注的 UP 也可能发付费推广。

## 2. 列表层判据（保守优先）

- 长词组标记：`限时折扣`、`点击领券`、`加微信`、`扫码进群`、`广告位招租`……
- commerce 账号名：`旗舰店`、`好物推荐官`、`优惠券小助手`……
- API 自带的推荐理由含「广告 / 推广」
- 短促销片段组合：≤90s 且标题含 `秒杀/抢购` 之一、且含 `包邮/到手价/原价` 之一

单个品牌词不足以判广告——正常的开箱与测评必须留下。

## 3. 播放层：两条来源合并

```
AiAssistedSponsorRepository
  ├─ inner: ApiSponsorRepository（BilibiliSponsorBlock，社区标记）
  └─ signalSource: ApiAdSignalSource（弹幕 → AirstrikeDetector → 片段）
```

- **装饰器而不是新状态机**：上游已实现 manual/automatic 跳过与分类配置，AI 片段只是多出来的
  `SponsorSegment`，复用同一套跳过 UI 与 `PlaybackSession` 所有权。
- **社区数据优先**：AI 片段与社区片段重叠时**直接丢弃**，因为社区区间是人工确认过的，
  AI 区间只是从弹幕推断。
- **扫描有界**：只取前 4 个弹幕分段（6 分钟/段，共 24 分钟）。视频内广告与「空降」边界都集中在开头。

## 4. 「空降」检测怎么工作

观众用「空降 03:45」「正片开始 1:02」这类带时间码的弹幕标注广告结束点：

1. 只保留命中关键词（`空降/广告/恰饭/跳过/正片开始/前方高能`）**且带时间码**的弹幕；
2. 把时间码投票聚成簇（默认窗口 12s，最少 2 票）；
3. 广告从上一个边界（或 0）持续到「正片开始」边界；
4. 置信度随片段长度上升，0.55 → 0.95。

`AdPolicy` 门控：低于 `minimumConfidence`（默认 0.6）只提示不自动跳；`skipMode` 为 `disabled` 时
完全不产出。

## 5. 未验证

没有真实账号与在线环境，跳过链路**未做在线验证**；`AirstrikeDetector` 与仓颉侧的聚类算法
目前只有同一套语义的两种实现，尚未用真实弹幕做交叉比对。
C:/Users/16857/Desktop/dsh/_bilisail/ad-note.mdC:/Users/16857/Desktop/dsh/_bilisail/ad-note2.md
package bilicore.ad

import std.collection.*

/**
 * 弹幕「空降」边界聚类。
 *
 * 分工说明：**时间码文本解析留在 Dart 侧**（`AirstrikeDetector` 已经实现并有解析
 * 校验），仓颉只接数字：调用方传入已解析出来的边界毫秒数组，这里负责
 * 聚类、投票门限与片段生成。这样跨语言边界只传定长数值，不传 UTF-8 字符串，
 * 避免两套运行时在编码与生命周期上互相假设。
 */
public struct AirstrikeOptions {
    public let clusterWindowMs: Int64
    public let minimumVotes: Int32
    public let minimumSegmentMs: Int64
    public let maximumSegmentMs: Int64

    public init(
        clusterWindowMs: Int64,
        minimumVotes: Int32,
        minimumSegmentMs: Int64,
        maximumSegmentMs: Int64
    ) {
        this.clusterWindowMs = clusterWindowMs
        this.minimumVotes = minimumVotes
        this.minimumSegmentMs = minimumSegmentMs
        this.maximumSegmentMs = maximumSegmentMs
    }
}

/**
 * 把落在 clusterWindowMs 内的票数合并成一个簇，返回满足 minimumVotes 的边界。
 *
 * points 允许重复——重复即票数，与 Dart 侧 map 累加的语义一致。
 */
public func clusterBoundaries(points: ArrayList<Int64>, options: AirstrikeOptions): ArrayList<Int64> {
    var ordered = ArrayList<Int64>(points)
    ordered.sort(comparator: { a: Int64, b: Int64 => a.compare(b) })
    var clusters = ArrayList<Int64>()   // 簇代表时间点
    var votes = ArrayList<Int64>()      // 对应票数
    for (point in ordered) {
        if (clusters.isEmpty()) {
            clusters.append(point)
            votes.append(1)
            continue
        }
        let last = clusters[clusters.size - 1]
        if (point - last <= options.clusterWindowMs) {
            votes[votes.size - 1] = votes[votes.size - 1] + 1
        } else {
            clusters.append(point)
            votes.append(1)
        }
    }
    var boundaries = ArrayList<Int64>()
    var index = 0
    while (index < clusters.size) {
        if (votes[index] >= Int64(options.minimumVotes)) {
            boundaries.append(clusters[index])
        }
        index += 1
    }
    return boundaries
}

/** 置信度：越长的片段越可信，映射到 0.55–0.95，与 Dart 侧一致。 */
func confidenceOf(lengthMs: Int64, minimumSegmentMs: Int64): Float64 {
    var seconds = lengthMs / 1000
    let floorSeconds = minimumSegmentMs / 1000
    if (seconds < floorSeconds) {
        seconds = floorSeconds
    }
    if (seconds > 600) {
        seconds = 600
    }
    return 0.55 + (Float64(seconds) / 600.0) * 0.4
}

/**
 * 由边界序列生成片段：广告从上一个边界（或视频开头）持续到「正片开始」的边界。
 */
public func segmentsFromBoundaries(
    boundaries: ArrayList<Int64>,
    videoDurationMs: Int64,
    options: AirstrikeOptions
): ArrayList<AdSegment> {
    var segments = ArrayList<AdSegment>()
    if (videoDurationMs <= 0) {
        return segments
    }
    var cursor: Int64 = 0
    for (boundary in boundaries) {
        if (boundary <= cursor || boundary > videoDurationMs) {
            cursor = if (boundary > cursor) { boundary } else { cursor }
            continue
        }
        let length = boundary - cursor
        if (length >= options.minimumSegmentMs && length <= options.maximumSegmentMs) {
            segments.append(
                AdSegment(
                    cursor,
                    boundary,
                    AdSource.DanmakuAirstrike,
                    confidenceOf(length, options.minimumSegmentMs)
                )
            )
        }
        cursor = boundary
    }
    return mergeSegments(segments, 2000)
}

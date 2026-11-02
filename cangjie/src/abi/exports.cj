package bilicore.abi

import std.collection.*
import bilicore.ad.*

/**
 * C ABI 导出面，供 Dart FFI 与 ArkTS 侧调用。
 *
 * 约定：
 * - 所有时间单位是毫秒（Int64），置信度以千分比（Int32）跨边界，避免浮点。
 * - 输出缓冲区由调用方分配；返回值为实际写入条数。
 * - 容量不足时返回 **负数**，其绝对值为所需条数，调用方据此重试。
 *
 * 说明：这一层的指针读写按仓颉 1.2.0 的 CPointer<T>.read/.write 写就，
 * **尚未用 cjpm 编译验证**（本机没有仓颉 SDK），首次构建时需按 SDK 文档核对。
 */

const VERSION_MAJOR: Int32 = 0
const VERSION_MINOR: Int32 = 1

@C
public func bilicore_version(): Int32 {
    return VERSION_MAJOR * 100 + VERSION_MINOR
}

/**
 * 由「已解析的边界票数」生成广告片段。
 *
 * @param points 边界毫秒数组，可重复（重复即票数）
 * @param count points 长度
 * @param clusterWindowMs 聚类窗口
 * @param minimumVotes 最少票数
 * @param videoDurationMs 视频总时长
 * @param minimumSegmentMs 片段最短
 * @param maximumSegmentMs 片段最长
 * @param out 输出缓冲，步长 3：startMs, endMs, confidencePermille
 * @param outCapacity out 能容纳的片段数
 */
@C
public func bilicore_detect_airstrike(
    points: CPointer<Int64>,
    count: Int32,
    clusterWindowMs: Int64,
    minimumVotes: Int32,
    videoDurationMs: Int64,
    minimumSegmentMs: Int64,
    maximumSegmentMs: Int64,
    out: CPointer<Int64>,
    outCapacity: Int32
): Int32 {
    unsafe {
        if (count < 0 || outCapacity < 0) {
            return -1
        }
        var input = ArrayList<Int64>()
        var index: Int32 = 0
        while (index < count) {
            input.append(points.read(Int64(index)))
            index += 1
        }
        let options = AirstrikeOptions(
            clusterWindowMs,
            minimumVotes,
            minimumSegmentMs,
            maximumSegmentMs
        )
        let boundaries = clusterBoundaries(input, options)
        let segments = segmentsFromBoundaries(boundaries, videoDurationMs, options)
        if (segments.size > Int64(outCapacity)) {
            return Int32(0 - segments.size)
        }
        var written: Int32 = 0
        for (segment in segments) {
            let base = Int64(written) * 3
            out.write(base, segment.startMs)
            out.write(base + 1, segment.endMs)
            let permille = Int64(segment.confidence * 1000.0)
            out.write(base + 2, permille)
            written += 1
        }
        return written
    }
}

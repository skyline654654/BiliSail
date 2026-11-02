package bilisail::bilicore.ad

import std.collection.*

/**
 * 广告片段来源。priority 越大，合并时越优先保留其身份。
 */
public enum AdSource {
    | SponsorBlock
    | DanmakuAirstrike
    | Description
    | OnDeviceModel

    public func priority(): Int32 {
        match (this) {
            case SponsorBlock => 4
            case DanmakuAirstrike => 3
            case Description => 2
            case OnDeviceModel => 1
        }
    }

    public func slot(): Int32 {
        match (this) {
            case SponsorBlock => 0
            case DanmakuAirstrike => 1
            case Description => 2
            case OnDeviceModel => 3
        }
    }
}

/**
 * 一条视频内广告片段，时间单位统一为毫秒。
 */
public struct AdSegment {
    public let startMs: Int64
    public let endMs: Int64
    public let source: AdSource
    public let confidence: Float64

    public init(startMs: Int64, endMs: Int64, source: AdSource, confidence: Float64) {
        this.startMs = startMs
        this.endMs = endMs
        this.source = source
        this.confidence = confidence
    }

    public func lengthMs(): Int64 {
        return endMs - startMs
    }

    public func contains(positionMs: Int64): Bool {
        return positionMs >= startMs && positionMs < endMs
    }

    public func overlaps(other: AdSegment): Bool {
        return startMs < other.endMs && other.startMs < endMs
    }
}

func stronger(a: AdSegment, b: AdSegment): AdSegment {
    if (a.source.priority() >= b.source.priority()) {
        return a
    }
    return b
}

/**
 * 合并重叠或间距不超过 mergeGapMs 的片段，返回按 startMs 升序的结果。
 *
 * 与 Dart 侧 `mergeAdSegments` 保持同一语义：合并后取更高优先级来源与更高置信度。
 */
public func mergeSegments(input: ArrayList<AdSegment>, mergeGapMs: Int64): ArrayList<AdSegment> {
    var ordered = ArrayList<AdSegment>(input)
    ordered.sortBy(comparator: {
        a: AdSegment, b: AdSegment => a.startMs.compare(b.startMs)
    })
    var merged = ArrayList<AdSegment>()
    for (segment in ordered) {
        if (merged.isEmpty()) {
            merged.add(segment)
            continue
        }
        let previous = merged[merged.size - 1]
        let adjacent = segment.startMs <= previous.endMs + mergeGapMs
        if (!adjacent) {
            merged.add(segment)
            continue
        }
        let strongest = stronger(previous, segment)
        let endMs = if (segment.endMs > previous.endMs) { segment.endMs } else { previous.endMs }
        let confidence = if (segment.confidence > previous.confidence) {
            segment.confidence
        } else {
            previous.confidence
        }
        merged[merged.size - 1] = AdSegment(previous.startMs, endMs, strongest.source, confidence)
    }
    return merged
}

/** 返回覆盖 positionMs 的片段；多条重叠时取置信度最高的一条。 */
public func segmentAt(segments: ArrayList<AdSegment>, positionMs: Int64): ?AdSegment {
    var best: ?AdSegment = None
    for (segment in segments) {
        if (!segment.contains(positionMs)) {
            continue
        }
        match (best) {
            case Some(current) =>
                if (segment.confidence > current.confidence) {
                    best = Some(segment)
                }
            case None => best = Some(segment)
        }
    }
    return best
}

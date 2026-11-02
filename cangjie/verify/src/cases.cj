package bilisail::bilicore_verify

import std.collection.*
import bilisail::bilicore.ad.*

public struct Case {
    public let name: String
    public let durationMs: Int64
    public let boundariesMs: Array<Int64>

    public init(name: String, durationMs: Int64, boundariesMs: Array<Int64>) {
        this.name = name
        this.durationMs = durationMs
        this.boundariesMs = boundariesMs
    }
}

public func cases(): Array<Case> {
    return [
        Case("typical_short_ad", 600000, [180000, 180000, 180000]),
        Case("below_vote_threshold", 600000, [180000]),
        Case("clustered_votes", 900000, [60000, 63000, 66000, 420000, 422000]),
        Case("too_short_segment", 600000, [1000, 1000]),
        Case("merged_close_boundaries", 1200000, [200000, 200000, 205000, 205000]),
        Case("beyond_duration", 300000, [900000, 900000]),
        Case("two_ads", 1500000, [300000, 300000, 900000, 900000]),
        Case("empty", 600000, []),
    ]
}
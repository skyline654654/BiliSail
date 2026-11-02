package bilisail::bilicore_verify

import std.collection.*
import bilisail::bilicore.ad.*

main() {
    for (item in cases()) {
        var points = ArrayList<Int64>()
        for (ms in item.boundariesMs) {
            points.add(ms)
        }
        let options = AirstrikeOptions(12000, 2, 3000, 360000)
        let boundaries = clusterBoundaries(points, options)
        let segments = segmentsFromBoundaries(boundaries, item.durationMs, options)
        var parts = ArrayList<String>()
        for (segment in segments) {
            let permille = Int64(segment.confidence * 1000.0)
            parts.add(segment.startMs.toString() + "-" + segment.endMs.toString() + "@" + permille.toString())
        }
        println(item.name + " | " + String.join(parts.toArray(), delimiter: ","))
    }
}
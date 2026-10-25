#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// One direction of a Gaussian blur whose radius grows from nothing at `start` to `maxRadius` at `end`, both measured
// down from the top of the layer.
[[ stitchable ]] half4 bottomBlur(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float start,
    float end,
    float maxRadius,
    float2 direction
) {
    float sigma = maxRadius * smoothstep(start, end, position.y);

    if (sigma < 0.25) {
        return layer.sample(position);
    }

    const int taps = 24;
    // How many sigmas the taps reach, which `bottomBlur(radius:height:fullHeight:)` leaves room for.
    const float reach = 2.5;
    half4 sum = half4(0.0);
    float total = 0.0;

    for (int i = -taps; i <= taps; i++) {
        // The weights fall off in sigmas, so they are the same at every strength.
        float sigmas = reach * float(i) / float(taps);
        float weight = exp(-0.5 * sigmas * sigmas);
        // Clamped, so the edges blur with the layer's own pixels rather than with clear ones.
        float2 point = clamp(position + direction * sigma * sigmas, float2(0.5), size - 0.5);

        sum += layer.sample(point) * half(weight);
        total += weight;
    }

    return sum / half(total);
}

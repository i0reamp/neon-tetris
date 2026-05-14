import SpriteKit

/// GLSL-ES fragment shaders used to drive the neon background, scanlines,
/// and the emissive cores of the active blocks.
///
/// SpriteKit injects:
///   u_time (float)        — accumulated scene time
///   v_tex_coord (vec2)    — 0..1 texture coords for the shaded node
///   SKDefaultShading()    — base color sample
enum ShaderLibrary {

    /// A slowly drifting nebula. Cheap fbm-style noise blend of two color pulses.
    static func nebula() -> SKShader {
        let source = """
        void main() {
            vec2 uv = v_tex_coord;
            float t = u_time * 0.07;

            // shift uv into screen-space-ish coordinates
            vec2 p = uv * 2.0 - 1.0;
            float r = length(p);

            // two animated soft circles drifting around
            vec2 c1 = vec2(0.6 * sin(t * 1.3), 0.4 * cos(t * 1.7));
            vec2 c2 = vec2(0.7 * cos(t * 1.1 + 1.7), 0.5 * sin(t * 0.9));
            float d1 = length(p - c1);
            float d2 = length(p - c2);

            float pulse1 = smoothstep(0.95, 0.1, d1);
            float pulse2 = smoothstep(1.05, 0.05, d2);

            // base palette: deep indigo -> magenta -> teal
            vec3 base    = vec3(0.03, 0.02, 0.08);
            vec3 magenta = vec3(0.45, 0.05, 0.55);
            vec3 teal    = vec3(0.02, 0.40, 0.55);
            vec3 violet  = vec3(0.16, 0.05, 0.42);

            vec3 col = base;
            col = mix(col, violet,  0.55 * pulse1);
            col = mix(col, magenta, 0.55 * pulse2);
            col = mix(col, teal,    0.35 * pulse1 * pulse2);

            // soft vignette
            float vig = smoothstep(1.30, 0.15, r);
            col *= mix(0.55, 1.0, vig);

            // subtle grain
            float n = fract(sin(dot(uv * (u_time * 0.001 + 1.0), vec2(12.9898, 78.233))) * 43758.5453);
            col += (n - 0.5) * 0.012;

            gl_FragColor = vec4(col, 1.0);
        }
        """
        return SKShader(source: source)
    }

    /// Thin horizontal scanlines + animated chromatic shimmer.
    static func scanlines() -> SKShader {
        let source = """
        void main() {
            vec2 uv = v_tex_coord;
            float t = u_time;

            float band = sin(uv.y * 600.0 + t * 4.0);
            float scan = 0.04 * smoothstep(0.0, 1.0, band);

            float shimmer = 0.025 * sin(uv.y * 18.0 - t * 0.6);

            vec4 base = SKDefaultShading();
            base.rgb += vec3(scan + shimmer * 0.5, scan + shimmer * 0.7, scan);
            gl_FragColor = base;
        }
        """
        return SKShader(source: source)
    }

    /// Radial neon glow for individual blocks.
    static func blockEmissive(core: SIMD3<Float>, halo: SIMD3<Float>) -> SKShader {
        let source = """
        void main() {
            vec2 uv = v_tex_coord;
            vec2 p = uv * 2.0 - 1.0;
            float r = length(p);

            // Tighter falloff so the halo is concentrated on the block itself
            // and doesn't bleed far into neighbouring cells.
            float coreMask = smoothstep(0.90, 0.55, r);
            float haloMask = smoothstep(1.00, 0.30, r);
            float edge     = smoothstep(0.95, 0.80, r) - smoothstep(0.80, 0.55, r);

            vec3 col = u_halo * haloMask * 0.35 + u_core * coreMask;
            col += u_halo * edge * 0.9;

            float alpha = max(haloMask, coreMask);
            gl_FragColor = vec4(col, alpha);
        }
        """
        let shader = SKShader(source: source)
        shader.uniforms = [
            SKUniform(name: "u_core", vectorFloat3: vector_float3(core.x, core.y, core.z)),
            SKUniform(name: "u_halo", vectorFloat3: vector_float3(halo.x, halo.y, halo.z))
        ]
        return shader
    }

    /// Sweep shader used for a flashing wipe across cleared rows.
    static func lineClearWipe() -> SKShader {
        let source = """
        void main() {
            vec2 uv = v_tex_coord;
            float t = clamp(u_progress, 0.0, 1.0);

            // moving bright edge from left to right
            float edge = smoothstep(t - 0.10, t, uv.x) * (1.0 - smoothstep(t, t + 0.06, uv.x));
            float trail = smoothstep(0.0, t, uv.x) * (1.0 - smoothstep(t, t + 0.30, uv.x));

            vec3 hot  = vec3(1.0, 0.95, 0.85);
            vec3 warm = vec3(0.85, 0.40, 1.00);

            vec3 col = warm * trail + hot * edge * 2.4;
            float alpha = trail * 0.6 + edge;
            gl_FragColor = vec4(col, alpha);
        }
        """
        let shader = SKShader(source: source)
        shader.uniforms = [SKUniform(name: "u_progress", float: 0.0)]
        return shader
    }
}

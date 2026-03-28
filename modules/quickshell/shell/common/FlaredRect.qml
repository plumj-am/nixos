import QtQuick

Canvas {
    id: root

    property bool flareLeft: false
    property bool flareRight: false
    property bool barAtTop: true

    readonly property real r: Theme.radius.big
    readonly property real f: Config.data.bar.size

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        var w = width;
        var h = height;
        var r = root.r;
        var f = root.f;

        // Fill
        ctx.beginPath();
        fillPath(ctx, w, h, r, f);
        ctx.closePath();
        ctx.fillStyle = Theme.background;
        ctx.fill();

        // Stroke (skip bar edge)
        ctx.strokeStyle = Theme.outline;
        ctx.lineWidth = 1;
        ctx.beginPath();
        strokePath(ctx, w, h, r, f);
        ctx.stroke();
    }

    function fillPath(ctx, w, h, r, f) {
        if (root.barAtTop) {
            // Start top-left
            ctx.moveTo(root.flareLeft ? 0 : r, 0);

            // Top edge
            ctx.lineTo(root.flareRight ? w : w - r, 0);

            if (root.flareRight) {
                // Right flare: quarter-circle from (w,0) curving to (w-f,f)
                ctx.arc(w, f, f, 3 * Math.PI / 2, Math.PI, true);
            } else {
                // Top-right rounded corner
                ctx.arcTo(w, 0, w, r, r);
            }

            // Right side down to bottom-right
            ctx.lineTo(root.flareRight ? w - f : w, h - r);

            if (root.flareLeft && root.flareRight) {
                // Both flares: bottom edge between (w-f,h) and (f,h) with rounded corners
                ctx.arcTo(w - f, h, w - f, h - r, r);
                ctx.lineTo(f + r, h);
                ctx.arcTo(f, h, f, h - r, r);
            } else if (!root.flareLeft && !root.flareRight) {
                // No flares: full bottom with rounded corners
                ctx.arcTo(w, h, w - r, h, r);
                ctx.lineTo(r, h);
                ctx.arcTo(0, h, 0, h - r, r);
            } else if (root.flareLeft) {
                // Left flare only: bottom from right side to left flare column
                ctx.arcTo(w, h, w - r, h, r);
                ctx.lineTo(f + r, h);
                ctx.arcTo(f, h, f, h - r, r);
            } else {
                // Right flare only: bottom from right flare column to left side
                ctx.arcTo(w - f, h, w - f, h - r, r);
                ctx.lineTo(r, h);
                ctx.arcTo(0, h, 0, h - r, r);
            }

            // Left side up to flare
            ctx.lineTo(root.flareLeft ? f : 0, f);

            if (root.flareLeft) {
                // Left flare: quarter-circle from (f,f) curving to (0,0)
                ctx.arc(0, f, f, 0, 3 * Math.PI / 2, true);
            } else {
                // Top-left rounded corner (already handled by arcTo above)
            }
        } else {
            // Bottom bar (mirrored)
            // Start bottom-left
            ctx.moveTo(root.flareLeft ? 0 : r, h);

            // Bottom edge
            ctx.lineTo(root.flareRight ? w : w - r, h);

            if (root.flareRight) {
                ctx.arc(w, h - f, f, Math.PI / 2, 2 * Math.PI, true);
            } else {
                ctx.arcTo(w, h, w, h - r, r);
            }

            // Right side up to top-right
            ctx.lineTo(root.flareRight ? w - f : w, r);

            if (root.flareLeft && root.flareRight) {
                ctx.arcTo(w - f, 0, w - f, r, r);
                ctx.lineTo(f + r, 0);
                ctx.arcTo(f, 0, f, r, r);
            } else if (!root.flareLeft && !root.flareRight) {
                ctx.arcTo(w, 0, w - r, 0, r);
                ctx.lineTo(r, 0);
                ctx.arcTo(0, 0, 0, r, r);
            } else if (root.flareLeft) {
                ctx.arcTo(w, 0, w - r, 0, r);
                ctx.lineTo(f + r, 0);
                ctx.arcTo(f, 0, f, r, r);
            } else {
                ctx.arcTo(w - f, 0, w - f, r, r);
                ctx.lineTo(r, 0);
                ctx.arcTo(0, 0, 0, r, r);
            }

            // Left side down to flare
            ctx.lineTo(root.flareLeft ? f : 0, h - f);

            if (root.flareLeft) {
                ctx.arc(0, h - f, f, 3 * Math.PI / 2, Math.PI, false);
            }
        }
    }

    function strokePath(ctx, w, h, r, f) {
        if (root.barAtTop) {
            // Start at left side of bar edge, trace counter-clockwise (skip top edge)
            if (root.flareLeft) {
                ctx.moveTo(0, 0);
                ctx.arc(0, f, f, 3 * Math.PI / 2, 0, false);
                // Now at (f, f)
            } else {
                ctx.moveTo(0, 0);
            }

            // Down left side
            ctx.lineTo(root.flareLeft ? f : 0, h - r);

            if (root.flareLeft && root.flareRight) {
                ctx.arcTo(f, h, f, h - r, r);
                ctx.lineTo(w - f - r, h);
                ctx.arcTo(w - f, h, w - f, h - r, r);
            } else if (!root.flareLeft && !root.flareRight) {
                ctx.arcTo(0, h, 0, h - r, r);
                ctx.lineTo(w - r, h);
                ctx.arcTo(w, h, w, h - r, r);
            } else if (root.flareLeft) {
                ctx.arcTo(f, h, f, h - r, r);
                ctx.lineTo(r, h);
                ctx.arcTo(0, h, 0, h - r, r);
            } else {
                ctx.arcTo(0, h, 0, h - r, r);
                ctx.lineTo(w - f - r, h);
                ctx.arcTo(w - f, h, w - f, h - r, r);
            }

            // Right side up to flare/corner
            ctx.lineTo(root.flareRight ? w - f : w - r, root.flareRight ? f : r);

            if (root.flareRight) {
                ctx.arc(w, f, f, Math.PI, 3 * Math.PI / 2, false);
            } else {
                ctx.arcTo(w, 0, w - r, 0, r);
            }
        } else {
            // Bottom bar: skip bottom edge, trace the rest
            if (root.flareLeft) {
                ctx.moveTo(0, h);
                ctx.arc(0, h - f, f, Math.PI / 2, 0, false);
            } else {
                ctx.moveTo(0, h);
            }

            // Up left side
            ctx.lineTo(root.flareLeft ? f : 0, r);

            if (root.flareLeft && root.flareRight) {
                ctx.arcTo(f, 0, f, r, r);
                ctx.lineTo(w - f - r, 0);
                ctx.arcTo(w - f, 0, w - f, r, r);
            } else if (!root.flareLeft && !root.flareRight) {
                ctx.arcTo(0, 0, 0, r, r);
                ctx.lineTo(w - r, 0);
                ctx.arcTo(w, 0, w, r, r);
            } else if (root.flareLeft) {
                ctx.arcTo(f, 0, f, r, r);
                ctx.lineTo(r, 0);
                ctx.arcTo(0, 0, 0, r, r);
            } else {
                ctx.arcTo(0, 0, 0, r, r);
                ctx.lineTo(w - f - r, 0);
                ctx.arcTo(w - f, 0, w - f, r, r);
            }

            // Right side down to bar edge
            ctx.lineTo(root.flareRight ? w - f : w, h);

            if (root.flareRight) {
                ctx.arc(w, h - f, f, 2 * Math.PI, Math.PI / 2, false);
            }
        }
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}

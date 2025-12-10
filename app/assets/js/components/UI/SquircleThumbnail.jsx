import React, { useMemo } from "react";

export default function SquircleThumbnail({
  src,
  alt = "",
  size = 75,
  exponent = 5,
  samples = 200,
}) {
  const uid = useMemo(() => Math.random().toString(36).slice(2), []);
  const ids = {
    path: `squircle_path_${uid}`,
    mask: `squircle_mask_${uid}`,
  };

  const d = useMemo(() => {
    const n = exponent;
    const N = Math.max(60, samples);
    const r = size / 2;
    const cx0 = r,
      cy0 = r;
    const sgn = (v) => (v < 0 ? -1 : 1);
    const pwr = (v) => Math.pow(Math.abs(v), 2 / n);
    let s = "";
    for (let i = 0; i <= N; i++) {
      const t = (i / N) * Math.PI * 2;
      const x = sgn(Math.cos(t)) * pwr(Math.cos(t)) * r + cx0;
      const y = sgn(Math.sin(t)) * pwr(Math.sin(t)) * r + cy0;
      s += (i ? "L " : "M ") + x + " " + y + " ";
    }
    return s + "Z";
  }, [size, exponent, samples]);

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      role="img"
      aria-label={alt}
      style={{
        display: "inline-block",
        verticalAlign: "middle",
        overflow: "visible",
        marginBottom: "0.618rem",
      }}
    >
      <defs>
        <path id={ids.path} d={d} />
        <mask
          id={ids.mask}
          maskUnits="userSpaceOnUse"
          x="0"
          y="0"
          width={size}
          height={size}
        >
          <use href={`#${ids.path}`} fill="#fff" />
        </mask>
      </defs>
      <image
        href={src}
        x="0"
        y="0"
        width={size}
        height={size}
        preserveAspectRatio="xMidYMid slice"
        mask={`url(#${ids.mask})`}
      />
    </svg>
  );
}

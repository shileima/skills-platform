// Minimal semver: validation and major/minor/patch bumping.
// Intentionally tiny — skills use plain x.y.z versions.

const SEMVER_RE = /^(\d+)\.(\d+)\.(\d+)$/;

export function isValid(version) {
  return typeof version === "string" && SEMVER_RE.test(version.trim());
}

export function parse(version) {
  const m = SEMVER_RE.exec(String(version).trim());
  if (!m) throw new Error(`invalid semver: ${version}`);
  return { major: +m[1], minor: +m[2], patch: +m[3] };
}

// bump(current, kind) where kind is "major" | "minor" | "patch"
// or an explicit "x.y.z" version string (returned as-is after validation).
export function bump(current, kind) {
  if (isValid(kind)) return kind.trim();
  const v = parse(current);
  switch (kind) {
    case "major":
      return `${v.major + 1}.0.0`;
    case "minor":
      return `${v.major}.${v.minor + 1}.0`;
    case "patch":
      return `${v.major}.${v.minor}.${v.patch + 1}`;
    default:
      throw new Error(`invalid bump kind: ${kind} (use major|minor|patch or x.y.z)`);
  }
}

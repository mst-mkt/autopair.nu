export const pairs = [
  { open: "(", close: ")" }
  { open: "[", close: "]" }
  { open: "{", close: "}" }
  { open: '"', close: '"' }
  { open: "'", close: "'" }
  { open: "`", close: "`" }
]

export def pair-chars []: nothing -> list<string> {
  $pairs | get open | append ($pairs | get close) | uniq
}

export const grapheme_clusters = ["👨‍👩‍👧" "🇯🇵" "🫶🏻"]

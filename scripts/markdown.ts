/**
 * A markdown parser for exactly the subset `docs/*.md` uses.
 *
 * **Not a general markdown implementation, and it should never become
 * one.** It covers what DS-01 actually contains — headings, prose with
 * three inline marks, bullet and numbered lists, tables of any width,
 * blockquotes and fenced blocks — and rejects anything else loudly.
 *
 * That refusal is the feature. A parser that silently drops a
 * construct it does not understand turns a typo into missing prose on
 * a published page; this one fails the build and names the line. The
 * document and the parser are meant to stay in lockstep, so the day
 * the standard grows a construct is a day someone edits this file on
 * purpose.
 *
 * Output is consumed by `build-docs.ts`, which writes it as Elm
 * values for `src/Prose.elm` to render. Nothing here knows a class
 * name — styling is Elm's, deliberately.
 */

export type Span =
  | { t: "text"; v: string }
  | { t: "strong"; v: string }
  | { t: "em"; v: string }
  | { t: "mono"; v: string };

export type Block =
  | { t: "para"; spans: Span[] }
  | { t: "sub"; v: string }
  | { t: "bullets"; items: Span[][] }
  | { t: "numbered"; items: Span[][] }
  | { t: "grid"; headers: string[]; rows: Span[][][] }
  | { t: "why"; spans: Span[] }
  | { t: "pre"; v: string };

export type MdProblem = { line: number; message: string };

// ---------------------------------------------------------------------------
// Inline
// ---------------------------------------------------------------------------

/** `**strong**`, `*emphasis*`, `` `mono` ``. Strong is listed first so
 * the alternation never mistakes the opening `**` for an empty em. */
const INLINE = /\*\*([^*]+)\*\*|\*([^*]+)\*|`([^`]+)`/g;

export function parseSpans(text: string): Span[] {
  const spans: Span[] = [];
  let last = 0;
  INLINE.lastIndex = 0;
  let m: RegExpExecArray | null;
  while ((m = INLINE.exec(text)) !== null) {
    if (m.index > last) spans.push({ t: "text", v: text.slice(last, m.index) });
    if (m[1] !== undefined) spans.push({ t: "strong", v: m[1] });
    else if (m[2] !== undefined) spans.push({ t: "em", v: m[2] });
    else spans.push({ t: "mono", v: m[3] });
    last = m.index + m[0].length;
  }
  if (last < text.length) spans.push({ t: "text", v: text.slice(last) });
  return spans.length ? spans : [{ t: "text", v: text }];
}

/** A table cell's text, with the pipe escape undone. */
function cell(raw: string): Span[] {
  return parseSpans(raw.trim().replace(/\\\|/g, "|"));
}

function splitRow(line: string): string[] {
  // Split on unescaped pipes, then drop the empty edges a `| a | b |`
  // row produces.
  const parts = line.trim().split(/(?<!\\)\|/);
  if (parts[0].trim() === "") parts.shift();
  if (parts.length && parts[parts.length - 1].trim() === "") parts.pop();
  return parts;
}

// ---------------------------------------------------------------------------
// Blocks
// ---------------------------------------------------------------------------

/**
 * Parse a run of lines into blocks. `startLine` is the 1-based line
 * number of `lines[0]` in the original file, so every problem can
 * point at a real place in the real document.
 */
export function parseBlocks(
  lines: string[],
  startLine: number,
): { blocks: Block[]; problems: MdProblem[] } {
  const blocks: Block[] = [];
  const problems: MdProblem[] = [];
  const at = (i: number) => startLine + i;

  // Prose accumulates across lines until a blank line or a block
  // construct closes it — markdown's soft-wrap rule, and the reason
  // the standard can stay hard-wrapped at 72 columns while reading as
  // continuous paragraphs.
  let para: string[] = [];
  const flush = () => {
    if (para.length) {
      blocks.push({ t: "para", spans: parseSpans(para.join(" ")) });
      para = [];
    }
  };

  let i = 0;
  while (i < lines.length) {
    const line = lines[i];

    if (!line.trim()) {
      flush();
      i++;
      continue;
    }

    // --- fenced block ---
    if (/^```/.test(line)) {
      flush();
      const body: string[] = [];
      const opened = i;
      i++;
      while (i < lines.length && !/^```/.test(lines[i])) {
        body.push(lines[i]);
        i++;
      }
      if (i >= lines.length) {
        problems.push({ line: at(opened), message: "unclosed ``` fence" });
        break;
      }
      i++; // the closing fence
      blocks.push({ t: "pre", v: body.join("\n").replace(/\s+$/, "") });
      continue;
    }

    // --- horizontal rule: a separator between sections, not content ---
    if (/^---+\s*$/.test(line)) {
      flush();
      i++;
      continue;
    }

    // --- subhead ---
    const sub = line.match(/^###\s+(.*?)\s*$/);
    if (sub) {
      flush();
      blocks.push({ t: "sub", v: sub[1] });
      i++;
      continue;
    }

    if (/^#{1,2}\s/.test(line)) {
      problems.push({
        line: at(i),
        message:
          `\`${line.trim()}\` — a heading above \`###\` inside a section. ` +
          `Sections are \`##\`, and everything below them is \`###\`.`,
      });
      i++;
      continue;
    }

    // --- blockquote: the rationale voice ---
    if (/^>\s?/.test(line)) {
      flush();
      const quoted: string[] = [];
      while (i < lines.length && /^>\s?/.test(lines[i])) {
        quoted.push(lines[i].replace(/^>\s?/, ""));
        i++;
      }
      // A blank `>` line splits one quote into two asides rather than
      // running them together as a single unreadable paragraph.
      for (const part of quoted.join("\n").split(/\n\s*\n/)) {
        const joined = part.replace(/\s*\n\s*/g, " ").trim();
        if (joined) blocks.push({ t: "why", spans: parseSpans(joined) });
      }
      continue;
    }

    // --- table ---
    if (/^\|/.test(line)) {
      flush();
      const rows: string[][] = [];
      const opened = i;
      while (i < lines.length && /^\|/.test(lines[i])) {
        rows.push(splitRow(lines[i]));
        i++;
      }
      // Header, alignment row, then the body. The alignment row is
      // the thing that makes it a table rather than a run of pipes.
      if (rows.length < 2 || !rows[1].every((c) => /^:?-{3,}:?$/.test(c.trim()))) {
        problems.push({
          line: at(opened),
          message:
            "a table needs a header row and a `| --- |` rule beneath it.",
        });
        continue;
      }
      const headers = rows[0].map((h) => h.trim());
      const body = rows.slice(2);
      const ragged = body.findIndex((r) => r.length !== headers.length);
      if (ragged !== -1) {
        problems.push({
          line: at(opened + 2 + ragged),
          message:
            `row has ${body[ragged].length} cells but the header has ` +
            `${headers.length}. Escape a literal pipe as \`\\|\`.`,
        });
        continue;
      }
      blocks.push({ t: "grid", headers, rows: body.map((r) => r.map(cell)) });
      continue;
    }

    // --- lists ---
    const bullet = line.match(/^[-*]\s+(.*)$/);
    const numbered = line.match(/^\d+\.\s+(.*)$/);
    if (bullet || numbered) {
      flush();
      const ordered = numbered !== null;
      const marker = ordered ? /^\d+\.\s+(.*)$/ : /^[-*]\s+(.*)$/;
      const items: string[] = [];
      while (i < lines.length) {
        const m = lines[i].match(marker);
        if (m) {
          items.push(m[1].trim());
        } else if (/^\s+\S/.test(lines[i]) && items.length) {
          // An indented continuation belongs to the item above it —
          // this is what lets a list item hard-wrap.
          items[items.length - 1] += " " + lines[i].trim();
        } else if (!lines[i].trim() && items.length) {
          // A blank line inside a list is allowed; a blank line
          // followed by anything that is not an item ends it.
          const next = lines[i + 1];
          if (next === undefined || !marker.test(next)) break;
        } else {
          break;
        }
        i++;
      }
      const parsed = items.map(parseSpans);
      blocks.push(ordered ? { t: "numbered", items: parsed } : { t: "bullets", items: parsed });
      continue;
    }

    para.push(line.trim());
    i++;
  }

  flush();
  return { blocks, problems };
}

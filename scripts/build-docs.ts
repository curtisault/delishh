/**
 * Prose documents → generated Elm.
 *
 * `docs/design-standard.md` is the prose of record. This script parses
 * it and writes `src/Generated/DesignStandard.elm`, which
 * `src/Prose.elm` renders through the house chrome.
 *
 * **Why generated Elm rather than fetched JSON.** Recipes are a
 * growing corpus and are fetched at runtime; a document that ships
 * *with* the app is different. Compiling it in keeps three things the
 * runtime path would cost:
 *
 *  - `Page.DesignStandard.view` stays a pure function of chrome, so
 *    `tests/SearchTests.elm` can keep holding every search term to the
 *    rendered page. That machine-check is the reason the hand-written
 *    index has not rotted, and an HTTP fetch would end it.
 *  - No `elm/http`, no loading state, no empty flash on a document
 *    whose whole job is to be read.
 *  - The Elm compiler type-checks the content.
 *
 * `src/Generated/` is gitignored: it is a build artifact, and checking
 * it in would give two copies of the standard with no rule about which
 * one wins — the exact failure this phase exists to delete.
 */

import { parse as parseYaml } from "@std/yaml";
import { type Block, type MdProblem, parseBlocks, type Span } from "./markdown.ts";

/** Every prose document the app renders.
 *
 * Adding one is a line here and a markdown file — there is no
 * hand-written prose page left in `src/`, which is the whole point:
 * a page you can edit in two places is a page that disagrees with
 * itself eventually.
 */
const DOCUMENTS = [
  { source: "docs/design-standard.md", module: "DesignStandard" },
  { source: "docs/about.md", module: "About" },
];

type Section = {
  anchor: string;
  tocLabel: string;
  title: string;
  intent: string;
  panel: boolean;
  blocks: Block[];
};

// ---------------------------------------------------------------------------
// Directives
// ---------------------------------------------------------------------------

/**
 * A `##` heading carries only a title, but a `Doc.Section` needs four
 * more things. They ride in an HTML comment beneath the heading —
 * invisible in any markdown renderer, so the file stays a good
 * standalone document:
 *
 *   ## 04. Colour — two layers, one honesty rule
 *   <!-- doc anchor=sec-color toc=Colour intent="Where acid is allowed" -->
 *
 * `anchor` is required rather than derived from the title. Deriving it
 * would mean rewording a heading silently repoints every inbound link
 * and every `Search.index` entry; making it explicit costs one line
 * and makes that breakage a visible edit.
 */
function parseDirective(raw: string): Record<string, string> {
  const out: Record<string, string> = {};
  const re = /(\w+)=(?:"([^"]*)"|(\S+))/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(raw)) !== null) out[m[1]] = m[2] ?? m[3];
  return out;
}

// ---------------------------------------------------------------------------
// Elm emission
// ---------------------------------------------------------------------------

/** YAML resolves a bare `2026-09-19` to a Date, so anything bound for
 * an Elm string goes through here rather than assuming it arrived as
 * one. */
function str(value: unknown): string {
  const s = value instanceof Date
    ? value.toISOString().slice(0, 10)
    : String(value ?? "");
  return `"${
    s
      .replace(/\\/g, "\\\\")
      .replace(/"/g, '\\"')
      .replace(/\r/g, "\\r")
      .replace(/\n/g, "\\n")
      .replace(/\t/g, "\\t")
  }"`;
}

function emitSpan(s: Span): string {
  const ctor = { text: "Text", strong: "Strong", em: "Emph", mono: "Mono" }[s.t];
  return `${ctor} ${str(s.v)}`;
}

function emitSpans(spans: Span[], indent: string): string {
  if (spans.length === 0) return "[]";
  return `[ ${spans.map(emitSpan).join(`\n${indent}, `)}\n${indent}]`;
}

function emitBlock(b: Block, indent: string): string {
  const inner = indent + "    ";
  switch (b.t) {
    case "para":
      return `Para\n${inner}${emitSpans(b.spans, inner)}`;
    case "why":
      return `Why\n${inner}${emitSpans(b.spans, inner)}`;
    case "sub":
      return `Sub ${str(b.v)}`;
    case "pre":
      return `Pre ${str(b.v)}`;
    case "bullets":
    case "numbered": {
      const ctor = b.t === "bullets" ? "Bullets" : "Numbered";
      const items = b.items
        .map((it) => emitSpans(it, inner + "  "))
        .join(`\n${inner}, `);
      return `${ctor}\n${inner}[ ${items}\n${inner}]`;
    }
    case "grid": {
      const headers = `[ ${b.headers.map(str).join(", ")} ]`;
      const rows = b.rows
        .map((row) => {
          const cells = row
            .map((c) => emitSpans(c, inner + "      "))
            .join(`\n${inner}    , `);
          return `[ ${cells}\n${inner}    ]`;
        })
        .join(`\n${inner}  , `);
      return `Grid\n${inner}${headers}\n${inner}[ ${rows}\n${inner}]`;
    }
  }
}

function emitSection(s: Section): string {
  const blocks = s.blocks.length === 0
    ? "[]"
    : `[ ${s.blocks.map((b) => emitBlock(b, "            ")).join("\n            , ")}\n            ]`;
  return [
    `    { anchor = ${str(s.anchor)}`,
    `    , tocLabel = ${str(s.tocLabel)}`,
    `    , title = ${str(s.title)}`,
    `    , intent = ${str(s.intent)}`,
    `    , panel = ${s.panel ? "True" : "False"}`,
    `    , blocks =`,
    `            ${blocks}`,
    `    }`,
  ].join("\n");
}

// ---------------------------------------------------------------------------
// Build
// ---------------------------------------------------------------------------

export type DocProblem = { line?: number; message: string };

export function buildDoc(
  source: string,
  moduleName = "DesignStandard",
): { elm: string | null; problems: DocProblem[] } {
  const problems: DocProblem[] = [];

  const split = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!split) {
    return {
      elm: null,
      problems: [{
        line: 1,
        message:
          "no YAML frontmatter. The masthead — tag, kicker, revision, title " +
          "lines, standfirst, footnote — is carried there so the markdown is " +
          "the single source for the whole page and not merely its body.",
      }],
    };
  }
  const [, rawYaml, body] = split;
  const bodyStart = rawYaml.split("\n").length + 3;

  let fm: Record<string, unknown>;
  try {
    fm = (parseYaml(rawYaml) ?? {}) as Record<string, unknown>;
  } catch (e) {
    return { elm: null, problems: [{ line: 2, message: `YAML will not parse: ${(e as Error).message}` }] };
  }

  const needed = ["tag", "kicker", "rev", "revDate", "titleLines", "standfirst", "footNote"];
  for (const k of needed) {
    if (fm[k] === undefined) problems.push({ line: 2, message: `frontmatter is missing \`${k}\`.` });
  }
  if (fm.titleLines !== undefined && !Array.isArray(fm.titleLines)) {
    problems.push({ line: 2, message: "`titleLines` is a list, one entry per line of the masthead." });
  }

  // --- split into sections -------------------------------------------------

  const lines = body.split("\n");
  const sections: Section[] = [];
  let current: { meta: Section; start: number; lines: string[] } | null = null;

  const closeSection = () => {
    if (!current) return;
    const { blocks, problems: md } = parseBlocks(current.lines, current.start);
    problems.push(...md.map((p: MdProblem) => ({ line: p.line, message: p.message })));
    current.meta.blocks = blocks;
    sections.push(current.meta);
    current = null;
  };

  for (let i = 0; i < lines.length; i++) {
    const lineNo = bodyStart + i;
    const head = lines[i].match(/^##\s+(?:(\d+)\.\s*)?(.*?)\s*$/);
    if (!head) {
      if (current) current.lines.push(lines[i]);
      // Anything above the first `##` is the human-readable header of
      // the raw file — the h1 and the revision note. The app takes its
      // masthead from frontmatter, so that preamble is not content.
      continue;
    }
    closeSection();

    const declared = head[1];
    const title = head[2];
    const position = sections.length;

    // Section numbers are positional in `Doc`, so a heading whose
    // written number disagrees with its position means every in-prose
    // `§NN` in the document now points somewhere else. Catch it here
    // rather than discovering it as a wrong cross-reference in print.
    if (declared !== undefined && Number(declared) !== position) {
      problems.push({
        line: lineNo,
        message:
          `\`## ${declared}. ${title}\` is in position ${
            String(position).padStart(2, "0")
          }. Doc numbers sections from their order, so this heading and every ` +
          `in-prose §${declared} reference now disagree. Renumber the heading, ` +
          `or move the section back.`,
      });
    }

    const directiveLine = lines[i + 1] ?? "";
    const dm = directiveLine.match(/<!--\s*doc\s+(.*?)\s*-->/);
    if (!dm) {
      problems.push({
        line: lineNo + 1,
        message:
          `\`## ${title}\` has no \`<!-- doc ... -->\` line beneath it. A ` +
          `section needs an \`anchor\`, a \`toc\` label and an \`intent\` — ` +
          `markdown has nowhere else to put them.`,
      });
      current = {
        meta: { anchor: "", tocLabel: title, title, intent: "", panel: false, blocks: [] },
        start: lineNo + 1,
        lines: [],
      };
      continue;
    }

    const d = parseDirective(dm[1]);
    for (const k of ["anchor", "toc", "intent"]) {
      if (!d[k]) {
        problems.push({ line: lineNo + 1, message: `the \`doc\` directive is missing \`${k}\`.` });
      }
    }
    if (d.body !== undefined && d.body !== "panel" && d.body !== "clauses") {
      problems.push({
        line: lineNo + 1,
        message: "`body` is `clauses` (prose, earns §N.M clause marks) or `panel` (apparatus).",
      });
    }

    current = {
      meta: {
        anchor: d.anchor ?? "",
        tocLabel: d.toc ?? title,
        title,
        intent: d.intent ?? "",
        panel: d.body === "panel",
        blocks: [],
      },
      start: lineNo + 2,
      lines: [],
    };
    i++; // the directive line is not content
  }
  closeSection();

  if (sections.length === 0) {
    problems.push({ message: "no `##` sections found." });
  }

  const dupes = sections
    .map((s) => s.anchor)
    .filter((a, i, all) => a && all.indexOf(a) !== i);
  for (const a of new Set(dupes)) {
    problems.push({ message: `two sections claim the anchor \`${a}\`.` });
  }

  if (problems.length) return { elm: null, problems };

  // --- emit ----------------------------------------------------------------

  const titleLines = (fm.titleLines as string[]).map(str).join(", ");
  const elm = `module Generated.${moduleName} exposing (masthead, sections)

{-| GENERATED — DO NOT EDIT.

Written by \`scripts/build-docs.ts\` on every \`deno task content\`.
Edit the markdown; this file is overwritten without asking.

-}

import Prose exposing (Block(..), Masthead, Section, Span(..))


masthead : Masthead
masthead =
    { tag = ${str(fm.tag)}
    , kicker = ${str(fm.kicker)}
    , rev = ${str(fm.rev)}
    , revDate = ${str(fm.revDate)}
    , titleLines = [ ${titleLines} ]
    , standfirst = ${str(String(fm.standfirst).trim())}
    , footNote = ${str(String(fm.footNote).trim())}
    }


sections : List Section
sections =
    [ ${sections.map(emitSection).map((s) => s.trimStart()).join("\n    , ")}
    ]
`;

  return { elm, problems };
}

// ---------------------------------------------------------------------------

if (import.meta.main) {
  const red = Deno.noColor ? (s: string) => s : (s: string) => `\x1b[31m${s}\x1b[0m`;
  await Deno.mkdir("src/Generated", { recursive: true });

  let failed = 0;
  for (const doc of DOCUMENTS) {
    const { elm, problems } = buildDoc(
      await Deno.readTextFile(doc.source),
      doc.module,
    );

    if (problems.length || !elm) {
      console.error(`\n${red("✕")} ${doc.source}`);
      for (const p of problems) {
        console.error(`  ${p.line === undefined ? "" : `:${p.line} `}${p.message}`);
      }
      failed++;
      continue;
    }
    await Deno.writeTextFile(`src/Generated/${doc.module}.elm`, elm);
  }

  if (failed) {
    console.error("");
    Deno.exit(1);
  }
  console.log(`docs: ${DOCUMENTS.length} documents → src/Generated/`);
}

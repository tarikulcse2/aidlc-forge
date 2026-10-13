# Lean documents: write only what a later step reads

Read this whenever you write a CR document (`request.md`, `design.md`, `units.md`, ADRs) or a report.

- **Keep:** stories and ACs, changed ACs, decisions that change behaviour or design (one line each), contract and
  data changes, and context packs.
- **Never write:**
  - your thinking or option debates (show options in chat; files get the chosen option plus one line of why)
  - Q&A transcripts, or restated baseline text
  - intent essays, assumption lists (decisions cover them), risks or diagrams that aren't real
  - progress narratives
  - template guidance, or empty sections: delete a section that has nothing to say, and never write "N/A"
- **Optional files:**
  - `design.md` only when there's a decision, a contract change or a data change (otherwise `units.md` is enough)
  - an ADR only for decisions that are hard to reverse: a package, persistence, auth, contract versioning or a
    public pattern. Everything else is a decision row.
- **Size limits:**
  - `request.md` ≤ 80 lines (quick ≤ 25, bug-fix ≤ 20)
  - `design.md` ≤ 60 lines
  - an ADR ≤ 12 lines
  - a context pack is 4 lines; it says each thing once (format: `${CLAUDE_PLUGIN_ROOT}/templates/units.md`)
  - a Mermaid diagram only for a flow whose behaviour changes, ≤ 15 lines

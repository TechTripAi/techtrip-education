# sources.md

The subject's authoritative sources. Settled during planning, before any teaching, and
extended at any time. Lessons and quiz explanations cite sources by id.

```markdown
# AWS Solutions Architect: sources

| Id | Source | Kind | Why it is trusted | Version | Added |
|---|---|---|---|---|---|
| S1 | [Exam guide](https://example.com/guide) | primary | published by the certifying body | SAA-C04, 2026-08 | 2026-11-13, planning |
| S2 | [Well-Architected Framework](https://example.com/waf) | primary | the vendor's own documentation | 2026-06 | 2026-11-13, planning |
| S3 | A book the learner uses | secondary | added by the learner | 3rd ed. | 2026-12-01, by the learner |
```

| Column | Rule |
|---|---|
| Id | `S1`, `S2`, and so on. Never reused. A retired source is struck through (`~~S2~~`), not deleted, so earlier citations still resolve. |
| Source | Title, with a link when there is one. A file the learner supplied is named by its path under `materials/`. |
| Kind | `primary`: the owner of the subject, such as vendor documentation, a standard, the certifying body, the original text. `secondary`: a reputable book or course. `community`: practitioners' forums and the like, for questions of judgement, and treated as opinion. |
| Why it is trusted | One short reason. |
| Version | Edition, version or date. For a certification, the exam code and date, so it is clear the source is current for the exam being sat. |
| Added | The date, and whether at planning, by the learner, or accepted by the learner from an offer. |

How sources are handled:

- At planning, research the subject, show the learner the proposed list, and let them
  accept, remove or add before the plan is written.
- A source the learner adds is taken as authoritative on their word, at any time.
- A source found later is offered to the learner, and added only if they accept.
- A lesson or explanation that states something found on no listed source says so in
  place: "(from general knowledge, not on the source list)". Nothing is blocked.

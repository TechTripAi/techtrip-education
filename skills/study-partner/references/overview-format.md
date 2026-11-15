# overview.md

The one view across subjects. Rebuilt by `overview.sh` at the top of the study root; never
edit it by hand. It shows status only. It is all the study partner reads to answer "show my
subjects" or "what is suggested for review", so that no subject's lessons, sources or
quizzes are loaded for a question about everything.

```markdown
# Study overview: me

**Updated:** 2026-11-20

| Subject | Title | Status | Steps done | In progress | Suggested reviews | Target date | Last session |
|---|---|---|---|---|---|---|---|
| aws-sa | AWS Solutions Architect | active | 1 of 3 | 1 | 1 | 2027-01-15 | 2026-11-20 |
| rust | Rust | active | no plan yet | - | - | none | - |
```

| Column | Comes from |
|---|---|
| Subject | The subject directory's name |
| Title, Status, Target date | `brief.md`: the heading, `**Status:**` and `**Target date:**` |
| Steps done, In progress | `progress.md`: step rows by status. "no plan yet" when there is no `plan.md`. |
| Suggested reviews | `progress.md`: step rows whose `Next review` is today or earlier |
| Last session | `progress.md` header |

Only active subjects are listed. Closed subjects are in `archive/index.md`.

`overview.sh --stdout` prints the same thing without writing the file. `reviews.sh` lists
the suggested steps themselves, across subjects or for one with `--subject`.

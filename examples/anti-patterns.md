# Anti-patterns — what fails with Vibe

Real failures observed in production use.

---

## Anti-pattern 1: task too large

❌ **Fails:**
```
Add a full authentication system with JWT tokens, refresh tokens, rate limiting,
and update the frontend to show a login modal.
```

Why: touches 4+ files, requires coordinated multi-step logic. Vibe will attempt it,
make partial progress, saturate context around turn 10, and leave the codebase in
a half-broken state.

✅ **Fix:** decompose into 4 separate calls:
1. Add JWT utility functions in `auth.py`
2. Add `/login` and `/refresh` routes in `app.py`
3. Add rate limiting middleware
4. Add login modal in `app.js`

---

## Anti-pattern 2: vague verification

❌ **Fails:**
```
VERIFY: Read back the function and confirm the changes are present.
```

Why: Vibe reads 20–50 lines of a large file and declares "VERIFIED" — it may not
see the relevant section at all.

✅ **Fix:** always use grep:
```
VERIFY: grep for "datetime.date" in app.py and confirm it appears inside fetch_data.
```

---

## Anti-pattern 3: UTF-8 / emoji in old_string

❌ **Fails** (search_replace):
```
old_string: "  caption.textContent = `Écart vs moyenne sectorielle : ${secteurInfo.label}`;"
```

Why: the `É` (U+00C9) or typographic apostrophes cause the byte-level match to fail.
Vibe reports `SEARCH/REPLACE blocks failed` and either gives up or rewrites the whole file.

✅ **Fix:** do these edits manually with Python:
```python
with open('static/app.js', encoding='utf-8') as f:
    src = f.read()
src = src.replace('old text with É', 'new text')
with open('static/app.js', 'w', encoding='utf-8') as f:
    f.write(src)
```

---

## Anti-pattern 4: prompt with colons in code examples

❌ **Fails** (prompt gets truncated):
```bash
~/tools/vibe-delegate "/path/to/project" "
LABEL_MAP = {
  'en:fair-trade': {'label': 'Fair Trade', 'icon': '🤝'},
  'en:organic':    {'label': 'Organic',    'icon': '🌿'},
}
"
```

Why: the `:` after `en` followed by a space can interfere with shell parsing in some
contexts; the emoji characters add UTF-8 complexity. The prompt may be silently truncated.

✅ **Fix:** the `vibe-delegate` script now writes the prompt to a temp file via
`printf '%q'`. This covers most cases. For very long prompts with embedded code,
verify the first `[vibe]` output matches your expectations before trusting the result.

---

## Anti-pattern 5: "also" in the task

❌ **Fails:**
```
TASK: Add the fetch_pappers() function. Also update the scan() route to call it,
and add the new fields to build_response(), and update the frontend to display them.
```

Why: 4 independent changes in 1 prompt. Vibe typically does the first one well,
makes a partial attempt at the second, and ignores the rest.

✅ **Fix:** one prompt per change. Use the diff check between each.

---

## Anti-pattern 6: no stack/file context

❌ **Fails:**
```
Add a history endpoint that returns the last 200 scans.
```

Why: Vibe doesn't know the stack, the DB pattern, the existing route structure,
or the response format. It will invent something plausible but wrong.

✅ **Fix:**
```
Stack: Python/Flask, SQLite.
Key file: app.py — uses get_cache_db() to open data/cache.sqlite.
Existing route pattern: @app.route("/scan/<ean>") returns jsonify(dict).

TASK: Add route GET /history that queries the scan_history table
(columns: id, ean, nom, marque, confidence_score, scanned_at)
and returns {"scans": [...]} ordered by scanned_at DESC, limit 200.
```

---

## Anti-pattern 7: relaunching without reading the diff

❌ **Fails:**
If Vibe completed 50% and crashed, relaunching with the same prompt will likely
**double the partial work** — inserting duplicate functions, duplicate routes, etc.

✅ **Fix:** always `git diff` before relaunching. If Vibe wrote partial code,
either complete it manually or write a new prompt that picks up from where it stopped.

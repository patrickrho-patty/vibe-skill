# Good Vibe prompts — patterns that work

These prompts consistently produce correct results in 5–10 turns.

---

## Pattern: add a function

```
Stack: Python/Flask. File: app.py

TASK: Add function fetch_company(name: str) -> dict after fetch_user():
  - GET https://api.example.com/companies?q={name}
  - Use existing HEADERS and TIMEOUT constants
  - If status 200 and response has "results" list with at least 1 item:
    c = response["results"][0]
    Return {"id": c.get("id",""), "name": c.get("name",""), "country": c.get("country","")}
  - Return {} on any error (wrap entire function in try/except: pass)

VERIFY: grep for "def fetch_company" in app.py and confirm it exists.
```

**Why it works:**
- Single function, single file
- Exact signature provided
- Return structure defined explicitly
- Error handling specified
- Grep verify — not a re-read

---

## Pattern: add a route

```
Stack: Python/Flask. File: app.py

TASK: Add route GET /stats that returns JSON:
  {"total_scans": N, "unique_eans": M}
  where N = total rows in scan_history table and M = distinct ean count.
  Use existing get_cache_db() pattern: conn = get_cache_db(), row_factory already set.

CONSTRAINTS:
- Do not modify existing routes
- Use jsonify() for the response

VERIFY: grep for "@app.route.*stats" in app.py and confirm it exists.
```

---

## Pattern: update a mapping dict

```
Stack: Python. File: app.py

TASK: In the MAPPING list inside map_categories_to_sector(), add these entries
BEFORE the line ("en:snacks", "snacks", None):

  ("en:viennoiseries",           "bakery", None),
  ("en:brioches",                "bakery", None),
  ("en:sweet-pastries-and-pies", "bakery", None),

The entries must be inserted as a block, preserving existing indentation (8 spaces).

VERIFY: grep for "en:viennoiseries" in app.py and confirm it appears before "en:snacks".
```

**Why it works:**
- Exact strings to insert
- Exact insertion point specified
- Relative ordering verified

---

## Pattern: update async JS function

```
Stack: Vanilla JS. File: static/app.js

TASK: Make renderHistory() async. It should:
  a. Set list.innerHTML to a loading placeholder
  b. Fetch GET /history from API_BASE
  c. If fetch fails, fall back to loadHistory() (localStorage) silently
  d. Render each item: .hi-name = nom, .hi-ean = ean
  e. Click still calls lookupEan(h.ean)
  f. If no items: show "No scans recorded"

CONSTRAINTS:
- Do not change the HTML class names (hi-name, hi-ean)
- Keep click-to-rescan behavior
- escapeHtml() is available in the file

VERIFY: grep for "async function renderHistory" in static/app.js and confirm it exists.
```

---

## Pattern: docstrings only

```
Stack: Python. File: app.py. Task: docstrings only, no logic changes.

Add or replace docstrings on these 3 functions:

1. fetch_product():
   "EAN resolution cascade: OFF → OBF → OPF → UPCitemdb. Returns (product_dict, source_label)."

2. fetch_gleif():
   "GLEIF — Global LEI index. Returns lei, country, legal_name, ultimate_parent. Free, unlimited."

3. fetch_opencorporates():
   "OpenCorporates — free, no auth for basic search. Returns jurisdiction, incorporation_date."

CONSTRAINTS:
- Do not modify any function logic
- If a function already has a docstring, replace it

VERIFY: grep for "EAN resolution cascade" in app.py and confirm it exists.
```

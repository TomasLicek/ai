#!/usr/bin/env bash
# Append a bug to a project's pm/backlog (two-part convention).
#
#   1. Writes a standalone `bug-<slug>.md` file.
#   2. Inserts a linked one-line bullet under the `## Bugs` section of
#      `backlog.md` (created before `## Decisions` if the section is missing).
#
# Pure shell + awk. The only optional non-determinism is --polish, which shells
# to `claude -p --model haiku` to clean up a rough freeform note; if that is
# unavailable it silently falls back to deterministic derivation, so the script
# never hard-depends on a model. `jq` is needed only for --json and --polish.
#
# Failure policy: writes are checked; on any failure the script prints to stderr
# and exits non-zero (never a false "✓"). It does NOT lock backlog.md — two
# simultaneous runs in the same repo can race (a non-issue for solo/sequential
# use; documented rather than locked to avoid stale-lock failure modes).
set -uo pipefail

usage() {
  cat <<'EOF'
usage: bug.sh [text] [options]

  text                 freeform bug note (the lazy path)
  --title T            explicit title
  --summary S          one-line index summary
  --problem P          problem body (markdown ok)
  --repro R            repro steps, newline-separated
  --notes N            optional ## Notes (likely culprit file/line, links)
  --status S           default: open  (e.g. monitoring)
  --source S           default: manual
  --slug S             override the generated slug
  --backlog-dir DIR    explicit pm/backlog path (else walks up from cwd)
  --polish             distill freeform text via `claude -p --model haiku`
  --dry-run            print what would happen, write nothing
  --json               emit machine-readable result (needs jq)
EOF
}

# ----------------------------------------------------------------- args ---
TEXT=""; TITLE=""; SUMMARY=""; PROBLEM=""; REPRO=""; NOTES=""
STATUS="open"; SOURCE="manual"; SLUG_OVERRIDE=""; BACKLOG_DIR=""
POLISH=0; DRYRUN=0; JSON=0

while [[ $# -gt 0 ]]; do
  opt="$1"
  case "$opt" in
    --title|--summary|--problem|--repro|--notes|--status|--source|--slug|--backlog-dir)
      # A value-taking flag with no following value used to wedge the loop
      # (shift 2 with $#==1 is a no-op, so $1 never advanced -> infinite loop).
      [[ $# -ge 2 ]] || { echo "error: $opt requires a value" >&2; exit 2; }
      val="$2"; shift 2
      case "$opt" in
        --title)       TITLE="$val";;
        --summary)     SUMMARY="$val";;
        --problem)     PROBLEM="$val";;
        --repro)       REPRO="$val";;
        --notes)       NOTES="$val";;
        --status)      STATUS="$val";;
        --source)      SOURCE="$val";;
        --slug)        SLUG_OVERRIDE="$val";;
        --backlog-dir) BACKLOG_DIR="$val";;
      esac;;
    --polish)  POLISH=1; shift;;
    --dry-run) DRYRUN=1; shift;;
    --json)    JSON=1; shift;;
    -h|--help) usage; exit 0;;
    --*)       echo "error: unknown option $opt" >&2; exit 2;;
    *)         TEXT="$opt"; shift;;
  esac
done

if [[ -z "$TITLE" && -z "$TEXT" && -z "$PROBLEM" ]]; then
  echo "error: need a title, freeform text, or --problem" >&2
  exit 2
fi

# Fail fast if --json was requested but jq is missing, BEFORE any writes
# (otherwise we'd write the files then error out, tempting the caller to retry).
if [[ $JSON -eq 1 ]] && ! command -v jq >/dev/null 2>&1; then
  echo "error: --json needs jq" >&2; exit 1
fi

# ------------------------------------------------------------- helpers ---
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
oneline() { printf '%s' "$1" | tr '\n\r\t' '   '; }  # collapse to single line

first_sentence() {
  printf '%s' "$1" | awk '{
    p=0
    for(i=1;i<=length($0);i++){ c=substr($0,i,1); if(c=="."||c=="!"||c=="?"){ p=i-1; break } }
    if(p>0) print substr($0,1,p); else print $0
    exit
  }'
}

truncate_words() { # text limit
  local text="$1" limit="$2"
  if [[ ${#text} -le $limit ]]; then printf '%s' "$text"; return; fi
  local cut="${text:0:$limit}"
  if [[ "$cut" == *" "* ]]; then printf '%s' "${cut% *}"; else printf '%s' "$cut"; fi
}

capitalize_first() {
  local s="$1"; [[ -z "$s" ]] && return
  printf '%s%s' "$(printf '%s' "${s:0:1}" | tr '[:lower:]' '[:upper:]')" "${s:1}"
}

slugify() { # strips apostrophes + stopwords, keeps first 6 meaningful words
  local t="${1//\'/}"
  printf '%s' "$t" | awk '
  BEGIN{
    split("a an the of to in on at for and or is are be do does did with by from into after before that this it its as has have no not", a, " ")
    for(i in a) stop[a[i]]=1
    out=""
  }
  {
    s=tolower($0); gsub(/[^a-z0-9]+/," ",s); n=split(s,w," "); mk=0
    for(i=1;i<=n;i++) if(w[i]!="" && !(w[i] in stop)) kept[++mk]=w[i]
    if(mk==0) for(i=1;i<=n;i++) if(w[i]!="") kept[++mk]=w[i]
    lim=(mk<6?mk:6)
    for(i=1;i<=lim;i++) out=(out==""?kept[i]:out"-"kept[i])
  }
  END{ print out }'   # END so empty input still yields a line (bash then falls back to untitled)
}

sanitize_slug() { # lighter: lowercase, non-alnum -> -, no stopword stripping
  printf '%s' "${1//\'/}" | awk '{ s=tolower($0); gsub(/[^a-z0-9]+/,"-",s); gsub(/-+/,"-",s); gsub(/^-|-$/,"",s); out=s } END{ print out }'
}

format_repro() {
  printf '%s\n' "$1" | awk '{
    line=$0; sub(/^[[:space:]]+/,"",line); sub(/[[:space:]]+$/,"",line)
    if(line=="") next
    sub(/^([0-9]+\.|[-*])[[:space:]]*/,"",line)
    print "- " line
  }'
}

polish() { # sets TITLE/SUMMARY/PROBLEM/REPRO from TEXT via claude haiku; 0 ok / 1 fail
  [[ -n "${CLAUDE_BUG_POLISHING:-}" ]] && return 1
  command -v claude >/dev/null 2>&1 || return 1
  command -v jq >/dev/null 2>&1 || return 1
  local prompt out json
  prompt="Convert this rough bug note into structured fields. Return ONLY a minified JSON object, no prose, no code fences, with keys: title, summary, problem, repro.
- title: <=70 chars, no trailing period, names the defect.
- summary: one line <=120 chars, for a backlog index bullet.
- problem: 1-3 plain sentences describing the bug.
- repro: reproduction steps as newline-separated lines if the note implies any, else an empty string.
Do not invent specifics that are not implied by the note.

NOTE:
$TEXT"
  # Bound the model call so a stalled request can't hang the session.
  local runner=(claude -p "$prompt" --model haiku)
  if command -v timeout >/dev/null 2>&1; then runner=(timeout 90 "${runner[@]}")
  elif command -v gtimeout >/dev/null 2>&1; then runner=(gtimeout 90 "${runner[@]}"); fi
  out="$(CLAUDE_BUG_POLISHING=1 "${runner[@]}" 2>/dev/null)" || return 1
  json="$(printf '%s' "$out" | awk '{ buf=buf $0 "\n" } END{
    start=index(buf,"{"); last=0
    for(i=1;i<=length(buf);i++) if(substr(buf,i,1)=="}") last=i
    if(start>0 && last>start) printf "%s", substr(buf,start,last-start+1)
  }')"
  [[ -z "$json" ]] && return 1
  printf '%s' "$json" | jq -e . >/dev/null 2>&1 || return 1
  local pt; pt="$(printf '%s' "$json" | jq -r '.title // empty')"
  [[ -z "$pt" ]] && return 1
  [[ -z "$TITLE"   ]] && TITLE="$pt"
  [[ -z "$SUMMARY" ]] && SUMMARY="$(printf '%s' "$json" | jq -r '.summary // empty')"
  [[ -z "$PROBLEM" ]] && PROBLEM="$(printf '%s' "$json" | jq -r '.problem // empty')"
  [[ -z "$REPRO"   ]] && REPRO="$(printf '%s' "$json" | jq -r '.repro // empty')"
  return 0
}

# --------------------------------------------------------- locate backlog ---
if [[ -n "$BACKLOG_DIR" ]]; then
  [[ -d "$BACKLOG_DIR" ]] || { echo "error: --backlog-dir $BACKLOG_DIR is not a directory" >&2; exit 1; }
else
  d="$(pwd -P)"
  while :; do
    if [[ -d "$d/pm/backlog" ]]; then BACKLOG_DIR="$d/pm/backlog"; break; fi
    [[ "$d" == "/" ]] && break
    d="$(dirname "$d")"
  done
  [[ -n "$BACKLOG_DIR" ]] || { echo "error: no pm/backlog/ found walking up from $(pwd). Pass --backlog-dir." >&2; exit 1; }
fi
BACKLOG_MD="$BACKLOG_DIR/backlog.md"

# ----------------------------------------------------- resolve the fields ---
POLISHED=false
if [[ $POLISH -eq 1 && -n "$TEXT" ]]; then
  if polish; then POLISHED=true; else echo "warning: --polish unavailable, using raw text" >&2; fi
fi

if [[ -z "$TITLE" ]]; then
  t="$(first_sentence "$TEXT")"; t="$(truncate_words "$t" 70)"; t="${t%.}"
  TITLE="$(capitalize_first "$t")"
fi
if [[ -z "$SUMMARY" ]]; then
  s="$(first_sentence "$TEXT")"; s="$(truncate_words "$s" 120)"; s="${s%.}"
  SUMMARY="$(capitalize_first "$s")"
fi
[[ -z "$PROBLEM" ]] && PROBLEM="$TEXT"

# Single-line + trimmed for everything that lands on one line. A newline in
# SUMMARY/STATUS would otherwise inject extra lines (even fake bullets/headers)
# straight into backlog.md's index.
TITLE="$(trim "$(oneline "$TITLE")")"
SUMMARY="$(trim "$(oneline "$SUMMARY")")"
STATUS="$(trim "$(oneline "$STATUS")")"
SOURCE="$(trim "$(oneline "$SOURCE")")"
PROBLEM="$(trim "$PROBLEM")"; NOTES="$(trim "$NOTES")"

[[ -z "$TITLE" ]] && TITLE="Untitled bug"
[[ -z "$SUMMARY" ]] && SUMMARY="$TITLE"
[[ -z "$STATUS" ]] && STATUS="open"

# ------------------------------------------------------------- slug + file ---
if [[ -n "$SLUG_OVERRIDE" ]]; then BASE="$(sanitize_slug "$SLUG_OVERRIDE")"; else BASE="$(slugify "$TITLE")"; fi
[[ -z "$BASE" ]] && BASE="untitled"
SLUG="$BASE"; n=2
while [[ -e "$BACKLOG_DIR/bug-$SLUG.md" ]]; do SLUG="$BASE-$n"; n=$((n+1)); done
BUG_FILENAME="bug-$SLUG.md"
BUG_PATH="$BACKLOG_DIR/$BUG_FILENAME"

BULLET="- [$BUG_FILENAME]($BUG_FILENAME) — $SUMMARY _(${STATUS})_"
REPRO_FMT=""; [[ -n "$REPRO" ]] && REPRO_FMT="$(format_repro "$REPRO")"

emit_json() { # $1 = dry_run true/false
  jq -n --arg slug "$SLUG" --arg title "$TITLE" --arg summary "$SUMMARY" \
        --arg status "$STATUS" --arg file "$BUG_PATH" --arg bullet "$BULLET" \
        --arg backlog "$BACKLOG_MD" --argjson polished "$POLISHED" --argjson dry_run "$1" \
        '{dry_run:$dry_run,slug:$slug,title:$title,summary:$summary,status:$status,file:$file,bullet:$bullet,backlog:$backlog,polished:$polished}'
}

if [[ $DRYRUN -eq 1 ]]; then
  if [[ $JSON -eq 1 ]]; then emit_json true
  else
    echo "[dry-run] would write $BUG_PATH"
    echo "[dry-run] bullet: $BULLET"
  fi
  exit 0
fi

# ------------------------------------------------------------ write it out ---
# Order matters for crash-safety: build the new index into a temp file FIRST
# (no side effects), then write the bug file, then atomically swap the index.
# Every step is checked; any failure aborts with a non-zero exit and no false
# success. mktemp inside the backlog dir both fails fast on a read-only dir and
# keeps the final `mv` an atomic same-filesystem rename.
TMP="$(mktemp "$BACKLOG_DIR/.backlog.XXXXXX" 2>/dev/null)" || {
  echo "error: cannot create a temp file in $BACKLOG_DIR (read-only?)" >&2; exit 1; }
trap '[ -n "${TMP:-}" ] && rm -f "$TMP"' EXIT

if [[ ! -s "$BACKLOG_MD" ]]; then
  printf '# Backlog\n' > "$BACKLOG_MD" || { echo "error: cannot write $BACKLOG_MD" >&2; exit 1; }
fi

if ! BULLET="$BULLET" TARGET="$BUG_FILENAME" awk '
function is_h2(l){ return (l ~ /^[[:space:]]*##[[:space:]]+/) }
{ lines[NR]=$0 }
END{
  total=NR; bullet=ENVIRON["BULLET"]; target=ENVIRON["TARGET"]
  # Idempotency: match the actual markdown link form, not a bare substring, so a
  # stray "(bug-x.md)" mention in prose cannot suppress a real bullet insert.
  link="["target"](" target ")"
  for(i=1;i<=total;i++){ if(index(lines[i],link)>0){ for(j=1;j<=total;j++) print lines[j]; exit } }
  bugs=0
  for(i=1;i<=total;i++){ if(lines[i] ~ /^[[:space:]]*##[[:space:]]+[Bb]ugs([[:space:]].*)?$/){ bugs=i; break } }
  if(bugs==0){
    dec=0
    for(i=1;i<=total;i++){ if(lines[i] ~ /^[[:space:]]*##[[:space:]]+[Dd]ecisions([[:space:]].*)?$/){ dec=i; break } }
    if(dec>0){
      for(i=1;i<dec;i++) print lines[i]
      print "## Bugs"; print ""; print bullet; print ""
      for(i=dec;i<=total;i++) print lines[i]
    } else {
      for(i=1;i<=total;i++) print lines[i]
      if(total>0 && lines[total] !~ /^[[:space:]]*$/) print ""
      print "## Bugs"; print ""; print bullet
    }
    exit
  }
  endp=total+1
  for(i=bugs+1;i<=total;i++){ if(is_h2(lines[i])){ endp=i; break } }
  insert_after=bugs
  for(i=bugs+1;i<endp;i++){ if(lines[i] ~ /^[[:space:]]*[-*][[:space:]]/) insert_after=i }
  for(i=1;i<=insert_after;i++) print lines[i]
  print bullet
  for(i=insert_after+1;i<=total;i++) print lines[i]
}
' "$BACKLOG_MD" > "$TMP"; then
  echo "error: failed to build updated backlog index" >&2; exit 1
fi

# Build the body in a command substitution so the conditional Repro/Notes
# printfs (which evaluate to false when empty) can't set the exit status of the
# checked write. Then a SINGLE redirect we actually test for success.
BODY="$(
  printf '# %s\n\n' "$TITLE"
  printf '**Type:** bug  **Status:** %s  **Source:** %s\n\n' "$STATUS" "$SOURCE"
  printf '## Problem\n\n'
  printf '%s\n' "${PROBLEM:-_(describe the problem)_}"
  [[ -n "$REPRO_FMT" ]] && printf '\n## Repro\n\n%s\n' "$REPRO_FMT"
  [[ -n "$NOTES" ]] && printf '\n## Notes\n\n%s\n' "$NOTES"
)"
if ! printf '%s\n' "$BODY" > "$BUG_PATH"; then
  echo "error: failed to write $BUG_PATH" >&2; exit 1
fi

if ! mv "$TMP" "$BACKLOG_MD"; then
  echo "error: failed to update $BACKLOG_MD" >&2
  rm -f "$BUG_PATH"   # don't leave a bug file with no index bullet
  exit 1
fi
TMP=""  # consumed by mv; stop the EXIT trap from chasing it

if [[ $JSON -eq 1 ]]; then
  emit_json false
else
  echo "✓ wrote $BUG_PATH"
  echo "✓ indexed in $BACKLOG_MD: $BULLET"
fi

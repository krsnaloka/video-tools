#!/bin/bash
# ==============================================================
# 🎬 VIDEO TOOLS – Playlist Maker, Cleaner, Sorter & Organizer
# Version: 3.8 (Improved move-videos with file listing)
# Author: Gemini & You 😎
# ==============================================================
set -uo pipefail

# Globale Variable für Verbose-Modus
VERBOSE=0
# Automatische Erkennung der CPU-Kerne für parallele Prozesse
CORES=$(nproc 2>/dev/null || echo 4)

# Abhängigkeiten prüfen
for cmd in ffprobe ffmpeg md5sum filetype; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "⚠️  Warnung: $cmd ist nicht installiert. Einige Funktionen werden fehlschlagen."
    fi
done

# ==============================================================
# 📢 Logging Funktionen
# ==============================================================
log_info() { echo -e "💡 $1" >&2; }
log_success() { echo -e "✅ $1" >&2; }
log_warn() { echo -e "⚠️  $1" >&2; }
log_err() { echo -e "❌ $1" >&2; }

log_verbose() {
    if [[ "${VERBOSE:-0}" -eq 1 ]]; then
        echo -e "🔍 $1" >&2
    fi
}
export -f log_verbose

# ==============================================================
# 🔍 Metadaten Extraktion (Exportiert für xargs Subshells)
# ==============================================================
get_video_stats() {
    local file="$1"
    ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height,codec_name,bit_rate:format=duration,size:format_tags=title \
        -of csv=p=0 "$file" 2>/dev/null || echo "0,0,unknown,0,0,0,unknown"
}
export -f get_video_stats

get_video_metadata_string() {
    local file="$1"
    local stats
    stats=$(get_video_stats "$file")
    
    local width height codec duration size bit_rate internal_title
    IFS=',' read -r width height codec duration size bit_rate internal_title <<< "$stats"
    
    local human_size="?"
    human_size=$(du -h "$file" 2>/dev/null | cut -f1 || echo "0")
    local date="?"
    date=$(stat -c '%y' "$file" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
    local dur_fmt
    dur_fmt=$(awk -v s="$duration" 'BEGIN {printf "%02d:%02d:%02d", s/3600, (s%3600)/60, s%60}')
    
    local output=""
    output+="# Datei: $(basename "$file")\n"
    if [[ -n "$internal_title" && "$internal_title" != "unknown" ]]; then
        output+="# Interner Titel: $internal_title\n"
    fi
    output+="# Größe: $human_size | Auflösung: ${width}x${height} (${height}p) | Bitrate: $((bit_rate/1000)) kbps\n"
    output+="# Codec: $codec | Dauer: $dur_fmt | Geändert: $date"
    echo -e "$output"
}
export -f get_video_metadata_string

# ==============================================================
# 🖥 Hilfe
# ==============================================================
show_help() {
cat <<EOF
🎞️  video-tools.sh - Multifunktionales Bash-Tool für Videodateien
System: Nutzt aktuell $CORES CPU-Kerne für parallele Aufgaben.

NUTZUNG:
  video-tools.sh [BEFEHL] [ARGUMENTE] [OPTIONEN]

BEFEHLE:
  make-m3u <verzeichnis> [out.m3u]
      Erstellt eine M3U-Playlist mittels filetype Speed-Pipeline.

  move-videos <quelle> <ziel>
      Sucht Videos in <quelle> und verschiebt sie nach <ziel>.
      Listet gefundene Dateien vor dem Verschieben auf.

  sort-by-words <in.m3u> [out.m3u]
      Gruppiert Dateien mit ähnlichen Wörtern in der Playlist zusammen.

  clean-m3u <in.m3u> [out.m3u] [--annotate]
      Bereinigt eine M3U-Playlist (ungültige Pfade, MD5-Duplikate).

  sort-m3u <in.m3u> [--by=res|size|duration|date] [--asc|--desc] [--annotate]
      Sortiert eine Playlist nach technischen Kriterien.

  scan-tags <verzeichnis>
      Zeigt interne Metadaten-Titel von Videos an.

  find-dupes <verzeichnis>
      Sucht nach identischen Videos via MD5 mit Qualitätsvergleich.

  export-json <in.m3u> [out.json]
      Erstellt eine JSON-Datei aus einer M3U-Playlist.

EOF
}

# ==============================================================
# 🎞️ M3U Creator (filetype Speed-Pipeline)
# ==============================================================
make_m3u() {
    local dir="${1:-.}"
    local output="${2:-found-videos.m3u}"

    [[ ! -d "$dir" ]] && { log_err "Verzeichnis '$dir' nicht gefunden."; return 1; }
    
    log_info "Erstelle Playlist mit filetype Speed-Pipeline (Parallel: -P$CORES)..."
    echo "#EXTM3U" > "$output"
    
    find "$dir" -type f -print0 | xargs -0 -P "$CORES" filetype -f | grep -i "(video/" | cut -d: -f1 >> "$output"
    
    local count=$(grep -c -v "^#" "$output")
    log_success "Playlist mit $count Videos erstellt: $output"
}

# ==============================================================
# 🚚 Video Organizer (Move Function)
# ==============================================================
move_videos() {
    local src="${1:-}"
    local dest="${2:-}"

    [[ -z "$src" || ! -d "$src" ]] && { log_err "Quellverzeichnis ungültig."; return 1; }
    [[ -z "$dest" ]] && { log_err "Zielverzeichnis fehlt."; return 1; }
    
    mkdir -p "$dest"

    log_info "Suche Videos in $src (filetype Speed-Check)..."
    
    # Files in Variable speichern (verwende Array-Simulation via Newlines)
    local files_to_move=$(find "$src" -maxdepth 2 -type f -print0 | xargs -0 -P "$CORES" filetype -f | grep -i "(video/" | cut -d: -f1 |grep -vi "dezemberfa" |grep -vi "harehare")
    local count=$(echo "$files_to_move" | grep -c . || echo 0)

    if [ "$count" -eq 0 ]; then
        log_info "Keine Videos zum Verschieben gefunden."
        return 0
    fi

    # Dateien auflisten
    echo -e "\n📂 Folgende Videos wurden gefunden:"
    echo "------------------------------------------------------------"
    echo "$files_to_move" | sed 's/^/  - /'
    echo "------------------------------------------------------------"
    
    log_warn "$count Videos gefunden. Verschieben nach '$dest' starten? (y/n)"
    read -p "> " confirm
    [[ "$confirm" != "y" ]] && { log_info "Abgebrochen."; return 0; }

    # Die Move-Pipeline
    echo "$files_to_move" | tr '\n' '\0' | xargs -0 -P "$CORES" -I {} mv -v "{}" "$dest/"
    
    log_success "Verschieben von $count Dateien abgeschlossen."
}

# ==============================================================
# 📝 Sort by Words (Grouping Logic)
# ==============================================================
sort_by_words() {
    local input="${1:-}"
    local output="${2:-word_sorted_$input}"
    
    [[ ! -f "$input" ]] && { log_err "Eingabedatei '$input' fehlt."; return 1; }
    
    log_info "Analysiere Wort-Häufigkeiten für Gruppierung..."
    local tmp_data=$(mktemp)
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^# || -z "$line" ]] && continue
        local filename=$(basename "$line")
        local clean_name=$(echo "${filename%.*}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/ /g')
        echo -e "$clean_name\t$line" >> "$tmp_data"
    done < "$input"

    echo "#EXTM3U" > "$output"
    sort -k1,1 "$tmp_data" | cut -f2 >> "$output"
    rm "$tmp_data"
    log_success "Wort-Sortierung abgeschlossen: $output"
}

# ==============================================================
# 🧹 M3U Cleaner & Annotator Core
# ==============================================================
clean_m3u() {
    local input="" output="" annotate_flag=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose) export VERBOSE=1 ;;
            --annotate) annotate_flag=1 ;;
            *) if [[ -z "$input" ]]; then input="$1"; elif [[ -z "$output" ]]; then output="$1"; fi ;;
        esac
        shift
    done

    [[ -z "$input" || ! -f "$input" ]] && { log_err "Gültige M3U Eingabedatei fehlt."; return 1; }
    output="${output:-clean_$input}"
    local search_root=$(realpath "$(dirname "$input")")

    log_info "Phase 1: Validierung & De-Duplizierung (MD5)..."
    local tmp_list=$(mktemp)
    declare -A seen_md5

    while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
        local line=$(echo "$raw_line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ "$line" =~ ^# || -z "$line" ]] && continue
        
        local current_path="$line"
        if [[ ! -f "$current_path" ]]; then
            local bname=$(basename "$current_path")
            local found=$(find "$search_root" -type f -name "$bname" 2>/dev/null | head -n 1 || true)
            if [[ -n "$found" ]]; then 
                current_path="$found"
            else 
                continue 
            fi
        fi

        local hash=$(md5sum "$current_path" 2>/dev/null | cut -d' ' -f1 || echo "$current_path")
        if [[ -z "${seen_md5["$hash"]+x}" ]]; then
            echo "$current_path" >> "$tmp_list"
            seen_md5["$hash"]=1
        fi
    done < "$input"

    echo "#EXTM3U" > "$output"
    if [[ $annotate_flag -eq 1 ]]; then
        cat "$tmp_list" | tr '\n' '\0' | xargs -0 -P "$CORES" -I {} bash -c '
            get_video_metadata_string "{}"
            echo "{}"
        ' >> "$output"
    else
        cat "$tmp_list" >> "$output"
    fi
    rm "$tmp_list"
    log_success "Playlist erstellt: $output"
}

# ==============================================================
# 🔍 Tag Scanner Utility
# ==============================================================
scan_tags() {
    local dir="${1:-.}"
    [[ ! -d "$dir" ]] && { log_err "Verzeichnis ungültig."; return 1; }
    log_info "Scanne Video-Titel parallel (-P $CORES) in: $dir"
    find "$dir" -type f -print0 | xargs -0 filetype -f | grep -i "(video/" | cut -d: -f1 | tr '\n' '\0' | xargs -0 -P "$CORES" -I {} bash -c '
        title=$(ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "{}" 2>/dev/null)
        [ -n "$title" ] && printf "✅ \033[1m%s\033[0m -> Title: \033[32m%s\033[0m\n" "$(basename "{}")" "$title"
    '
}

# ==============================================================
# 📊 M3U Sorter
# ==============================================================
sort_m3u() {
    local input="" mode="--by=size" direction="desc" annotate=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --by=*) mode="$1" ;;
            --asc) direction="asc" ;;
            --desc) direction="desc" ;;
            --annotate) annotate=1 ;;
            -v|--verbose) export VERBOSE=1 ;;
            *) input="$1" ;;
        esac
        shift
    done

    [[ ! -f "$input" ]] && { log_err "M3U Datei nicht gefunden."; return 1; }
    local criteria=$(echo "$mode" | sed 's/^--by=//')
    local tmp=$(mktemp)

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | tr -d '\r' | xargs)
        [[ "$line" =~ ^# || -z "$line" || ! -f "$line" ]] && continue
        local s=$(get_video_stats "$line")
        local w h c d sz b t
        IFS=',' read -r w h c d sz b t <<< "$s"
        echo -e "$h\t$sz\t$(stat -c %Y "$line")\t${d%.*}\t$line" >> "$tmp"
    done < "$input"

    local col=2; [[ "$criteria" == "res"* ]] && col=1; [[ "$criteria" == "date"* ]] && col=3; [[ "$criteria" == "dur"* ]] && col=4
    local sort_flag="-k${col},${col}n"; [[ "$direction" == "desc" ]] && sort_flag="-k${col},${col}nr"
    
    local out="sorted_$input"
    echo "#EXTM3U" > "$out"
    if [[ $annotate -eq 1 ]]; then
        sort -t$'\t' $sort_flag "$tmp" | cut -f5 | tr '\n' '\0' | xargs -0 -P "$CORES" -I {} bash -c '
            get_video_metadata_string "{}"
            echo "{}"
        ' >> "$out"
    else
        sort -t$'\t' $sort_flag "$tmp" | cut -f5 >> "$out"
    fi
    rm "$tmp"
    log_success "Sortierung abgeschlossen -> $out"
}

# ==============================================================
# 🏆 Qualitäts-Vergleich & Duplikate
# ==============================================================
compare_quality() {
    local f1="${1:-}" f2="${2:-}"
    [[ ! -f "$f1" || ! -f "$f2" ]] && { log_err "Zwei gültige Dateien benötigt."; return 1; }
    local s1=$(get_video_stats "$f1") s2=$(get_video_stats "$f2")
    local w1 h1 c1 d1 sz1 b1 t1 w2 h2 c2 d2 sz2 b2 t2
    IFS=',' read -r w1 h1 c1 d1 sz1 b1 t1 <<< "$s1"
    IFS=',' read -r w2 h2 c2 d2 sz2 b2 t2 <<< "$s2"

    echo -e "\n📊 VERGLEICH:\n1. $f1\n2. $f2\n"
    printf "%-15s | %-25s | %-25s\n" "Attribut" "Datei 1" "Datei 2"
    printf "%-15s | %-25s | %-25s\n" "---------------" "-------------------------" "-------------------------"
    printf "%-15s | %-25s | %-25s\n" "Auflösung" "${w1}x${h1}" "${w2}x${h2}"
    printf "%-15s | %-25s | %-25s\n" "Bitrate" "$((b1/1000)) kbps" "$((b2/1000)) kbps"
    printf "%-15s | %-25s | %-25s\n" "Größe" "$(du -h "$f1" | cut -f1)" "$(du -h "$f2" | cut -f1)"
    printf "%-15s | %-25s | %-25s\n" "Codec" "$c1" "$c2"
}

find_dupes() {
    local dir="${1:-.}"
    declare -A hashes
    log_info "Suche MD5-Duplikate in $dir (filetype Speed-Check)..."
    
    local video_files=$(find "$dir" -type f -print0 | xargs -0 -P "$CORES" filetype -f | grep -i "(video/" | cut -d: -f1)
    
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local h=$(md5sum "$file" | cut -d' ' -f1)
        if [[ -n "${hashes["$h"]+x}" ]]; then
            log_warn "Duplikat entdeckt: $(basename "$file")"
            compare_quality "${hashes["$h"]}" "$file"
            echo -e "\nWelche Datei soll BEHALTEN werden? (1) Datei 1, (2) Datei 2, (s) Überspringen:"
            read -p "> " choice
            [[ "$choice" == "1" ]] && rm -v "$file"
            [[ "$choice" == "2" ]] && rm -v "${hashes["$h"]}" && hashes["$h"]="$file"
        else
            hashes["$h"]="$file"
        fi
    done <<< "$video_files"
}

# ==============================================================
# 🚀 Dispatcher
# ==============================================================
cmd="${1:-help}"
shift || true
case "$cmd" in
    make-m3u)        make_m3u "$@" ;;
    move-videos)     move_videos "$@" ;;
    sort-by-words)   sort_by_words "$@" ;;
    clean-m3u)       clean_m3u "$@" ;;
    annotate-m3u)    clean_m3u "$@" --annotate ;;
    sort-m3u)        sort_m3u "$@" ;;
    scan-tags)       scan_tags "$@" ;;
    find-dupes)      find_dupes "$@" ;;
    compare-quality) compare_quality "$@" ;;
    help|--help|-h)  show_help ;;
    *) log_err "Unbekannter Befehl: $cmd"; show_help; exit 1 ;;
esac

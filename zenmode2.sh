#!/bin/bash
set -e

# zenmode2.sh:
# 1. Force-installs required extensions via Flatpak Enterprise Policy (no website/about blocks).
# 2. Injects comprehensive SocialFocus anti-distraction settings (YouTube, Twitter/X, Reddit, Twitch, LinkedIn)
#    directly into its IndexedDB database.
# 3. Permanently locks the SocialFocus UI with an unrecoverable random token and disables resets.
#
# Note: Zen MUST be closed before running this script so IndexedDB can be safely updated.

! pgrep -f '^/app/zen/zen --name' >/dev/null 2>&1 || { echo "Error: Close Zen completely first!"; exit 1; }

POLICY_DIR="$HOME/.local/share/flatpak/extension/app.zen_browser.zen.systemconfig/x86_64/stable/policies"
POLICY_FILE="$POLICY_DIR/policies.json"
AMO="https://addons.mozilla.org/firefox/downloads/latest"

mkdir -p "$POLICY_DIR"
[ -f "$POLICY_FILE" ] && sudo chattr -i "$POLICY_FILE" 2>/dev/null || true

cat > "$POLICY_FILE" <<EOF
{
  "policies": {
    "ExtensionSettings": {
      "{26b4f076-089c-4c69-8497-44b7e5c9faef}": {"installation_mode": "force_installed", "install_url": "$AMO/socialfocus/latest.xpi"},
      "tab-stash@condordes.net": {"installation_mode": "force_installed", "install_url": "$AMO/tab-stash/latest.xpi"},
      "{446900e4-71c2-419f-a6a7-df9c091e268b}": {"installation_mode": "force_installed", "install_url": "$AMO/bitwarden-password-manager/latest.xpi"},
      "uBlock0@raymondhill.net": {"installation_mode": "force_installed", "install_url": "$AMO/ublock-origin/latest.xpi"},
      "{74e326aa-c645-4495-9287-b6febc5565a7}": {"installation_mode": "force_installed", "install_url": "$AMO/competitive-companion/latest.xpi"},
      "contact@alphaxiv.org": {"installation_mode": "force_installed", "install_url": "$AMO/alphaxiv/latest.xpi"}
    }
  }
}
EOF

sudo chattr +i "$POLICY_FILE" 2>/dev/null || true
echo "[✓] Zen extension policies written and locked."

python3 - <<'EOF'
import glob, json, os, re, secrets, shutil, sqlite3, struct

PROFILE = os.path.expanduser("~/.var/app/app.zen_browser.zen/.zen/0b1mhmxk.Default (release)")
EXTENSION_ID = "{26b4f076-089c-4c69-8497-44b7e5c9faef}"

SETTINGS = {
    "youtube": {
        "socialFocus_youtube_hide_video_page_sidebar": True,
        "socialFocus_youtube_hide_related_videos": True,
        "socialFocus_youtube_hide_shorts": True,
        "socialFocus_youtube_hide_comments": True,
        "socialFocus_youtube_hide_explore": True,
        "socialFocus_youtube_hide_video_endscreen": True,
        "socialFocus_youtube_hide_thumbnails": True,
        "socialFocus_youtube_hide_banner_ads": True,
    },
    "reddit": {
        "socialFocus_reddit_home_feed_hide_home_feed": True,
        "socialFocus_reddit_home_feed_hide_related_posts": True,
        "socialFocus_reddit_hide_trending_today": True,
        "socialFocus_reddit_rightBar_hide_reddit_premium_box": True,
        "socialFocus_reddit_rightBar_hide_recent_posts_box": True,
        "socialFocus_reddit_rightBar_hide_hide_block_popular_communities": True,
        "socialFocus_reddit_subreddit_hide_subreddit_feed": True,
        "socialFocus_reddit_subreddit_hide_create_post_button": True,
        "socialFocus_reddit_subreddit_hide_header_buttons": True,
        "socialFocus_reddit_subreddit_rightBar_hide_flair_box": True,
        "socialFocus_reddit_subreddit_rightBar_hide_rules_box": True,
        "socialFocus_reddit_subreddit_rightBar_hide_moderators_box": True,
        "socialFocus_reddit_leftSidebar_hide_left_sidebar": True,
    },
    "twitter": {
        "socialFocus_twitter_feed_hide_home_timeline_for_you": True,
        "socialFocus_twitter_feed_hide_button_timeline_settings": True,
        "socialFocus_twitter_feed_hide_show_new_post_button": True,
        "socialFocus_twitter_hide_post_profile_pictures": True,
        "socialFocus_twitter_hide_post_videos": True,
        "socialFocus_twitter_hide_post_metrics": True,
        "socialFocus_twitter_navigationBar_hide_button_home": True,
        "socialFocus_twitter_navigationBar_hide_home_notifications_dot": True,
        "socialFocus_twitter_navigationBar_hide_button_explore": True,
        "socialFocus_twitter_navigationBar_hide_notifications_counter": True,
        "socialFocus_twitter_navigationBar_hide_jobs_button": True,
        "socialFocus_twitter_navigationBar_hide_button_communities": True,
        "socialFocus_twitter_navigationBar_hide_button_verified": True,
        "socialFocus_twitter_navigationBar_hide_verified_orgs_button": True,
        "socialFocus_twitter_navigationBar_hide_button_profile": True,
        "socialFocus_twitter_rightBar_hide_premium_ads": True,
        "socialFocus_twitter_rightBar_hide_trends_for_you": True,
        "socialFocus_twitter_rightBar_hide_who_to_follow": True,
        "socialFocus_twitter_rightBar_hide_footer": True,
        "socialFocus_twitter_rightBar_hide_live_on_x": True,
    },
    "twitch": {
        "socialFocus_twitch_hide_front_page": True,
        "socialFocus_twitch_hide_recommended_channels": True,
        "socialFocus_twitch_hide_watch_page_suggestions": True,
        "socialFocus_twitch_hide_chat": True,
        "socialFocus_twitch_hide_end_suggestions": True,
        "socialFocus_twitch_hide_left_sidebar": True,
        "socialFocus_twitch_hide_channel_panels": True,
        "socialFocus_twitch_hide_browse": True,
        "socialFocus_twitch_hide_following": True,
        "socialFocus_twitch_hide_notifications": True,
        "socialFocus_twitch_hide_prime_loot": True,
        "socialFocus_twitch_hide_get_bits": True,
        "socialFocus_twitch_hide_subscribe_button": True,
        "socialFocus_twitch_hide_search_recommended": True,
    },
    "linkedin": {
        "socialFocus_linkedin_home_feed_hide_home_feed": True,
        "socialFocus_linkedin_home_feed_hide_home_feed_promoted_posts": True,
        "socialFocus_linkedin_home_feed_hide_post_metrics": True,
        "socialFocus_linkedin_home_page_suggested_posts": True,
        "socialFocus_linkedin_rightBar_hide_sidebar_follows_list": True,
        "socialFocus_linkedin_rightBar_hide_sidebar_ad_banner": True,
        "socialFocus_linkedin_rightBar_hide_footer": True,
        "socialFocus_linkedin_header_hide_button_home": True,
        "socialFocus_linkedin_header_hide_button_my_network": True,
        "socialFocus_linkedin_header_hide_button_notifications": True,
        "socialFocus_linkedin_header_hide_button_for_business": True,
        "socialFocus_linkedin_other_hide_premium_ads": True,
        "socialFocus_linkedin_gray_mode": True,
        "socialFocus_linkedin_header_hide_button_jobs": False,
        "socialFocus_linkedin_header_hide_button_messaging": False,
        "socialFocus_linkedin_header_hide_button_me": False,
        "socialFocus_linkedin_other_hide_messaging_popup": False,
    }
}

def snappy_decompress(b):
    i = n = shift = 0
    while True:
        c = b[i]; i += 1
        n |= (c & 0x7F) << shift; shift += 7
        if not c & 0x80: break
    out = bytearray()
    while i < len(b):
        t = b[i]; i += 1
        kind = t & 3
        if kind == 0:
            length = t >> 2
            if length >= 60:
                nb = length - 59
                length = int.from_bytes(b[i:i + nb], "little"); i += nb
            length += 1
            out += b[i:i + length]; i += length
        else:
            if kind == 1:
                length = ((t >> 2) & 7) + 4; offset = ((t >> 5) << 8) | b[i]; i += 1
            elif kind == 2:
                length = (t >> 2) + 1; offset = int.from_bytes(b[i:i + 2], "little"); i += 2
            else:
                length = (t >> 2) + 1; offset = int.from_bytes(b[i:i + 4], "little"); i += 4
            for _ in range(length):
                out.append(out[-offset])
    assert len(out) == n
    return bytes(out)

def snappy_compress(d):
    out = bytearray()
    n = len(d)
    while True:
        c = n & 0x7F; n >>= 7
        out.append(c | (0x80 if n else 0))
        if not n: break
    for i in range(0, len(d), 65536):
        chunk = d[i:i + 65536]
        length = len(chunk)
        if length <= 60:
            out.append((length - 1) << 2)
        elif length <= 256:
            out += bytes([60 << 2, length - 1])
        else:
            out += bytes([61 << 2]) + (length - 1).to_bytes(2, "little")
        out += chunk
    return bytes(out)

NULL, BOOLEAN, INT32, STRING, OBJECT, END = 0xFFFF0000, 0xFFFF0002, 0xFFFF0003, 0xFFFF0004, 0xFFFF0008, 0xFFFF0013
LATIN1 = 0x80000000

def sc_decode(raw):
    pos = 8
    def word():
        nonlocal pos
        data, tag = struct.unpack_from("<II", raw, pos)
        pos += 8
        return tag, data
    def string(length):
        nonlocal pos
        s = raw[pos:pos + length].decode("latin-1")
        pos += (length + 7) & ~7
        return s
    def value():
        nonlocal pos
        tag, data = word()
        if tag == BOOLEAN: return bool(data)
        if tag == INT32: return struct.unpack("<i", struct.pack("<I", data))[0]
        if tag == STRING:
            assert data & LATIN1
            return string(data & ~LATIN1)
        if tag == NULL: return None
        assert tag == OBJECT, hex(tag)
        obj = {}
        while True:
            tag, data = word()
            if tag == END: return obj
            assert tag == STRING and data & LATIN1
            key = string(data & ~LATIN1)
            obj[key] = value()
    res = value()
    assert pos == len(raw)
    return res

def sc_encode(obj):
    out = bytearray(struct.pack("<II", 3, 0xFFF10000))
    def word(tag, data): out.extend(struct.pack("<II", data, tag))
    def string(s):
        b = s.encode("latin-1")
        word(STRING, len(b) | LATIN1)
        out.extend(b + b"\0" * (-len(b) % 8))
    def value(v):
        if v is None: word(NULL, 0)
        elif isinstance(v, bool): word(BOOLEAN, int(v))
        elif isinstance(v, int): word(INT32, v & 0xFFFFFFFF)
        elif isinstance(v, str): string(v)
        else:
            word(OBJECT, 0)
            for k, x in v.items():
                string(k)
                value(x)
            word(END, 0)
    value(obj)
    return bytes(out)

def idb_key(name):
    return b"0" + bytes(c + 1 for c in name.encode())

# Find extension UUID
pref_text = open(f"{PROFILE}/prefs.js").read()
match = re.search(r'user_pref\("extensions\.webextensions\.uuids", "(.*)"\);', pref_text)
if not match:
    raise RuntimeError("Could not find webextensions.uuids in prefs.js")
uuids = json.loads(match.group(1).encode().decode("unicode_escape"))
uuid = uuids.get(EXTENSION_ID)
if not uuid:
    raise RuntimeError("SocialFocus is not installed in this profile.")

db_matches = glob.glob(f"{PROFILE}/storage/default/moz-extension+++{uuid}^userContextId=4294967295/idb/*.sqlite")
if not db_matches:
    raise RuntimeError("Could not find SocialFocus IndexedDB database.")
db_path = db_matches[0]

os.makedirs(os.path.expanduser("~/.cache/social_focus"), exist_ok=True)
shutil.copy(db_path, os.path.expanduser("~/.cache/social_focus/backup.sqlite"))

con = sqlite3.connect(db_path)
con.create_function("update_refcount", 2, lambda old, new: None)

def read(name):
    row = con.execute("SELECT data FROM object_data WHERE object_store_id=1 AND key=?", (idb_key(name),)).fetchone()
    if not row: return {}
    return sc_decode(snappy_decompress(row[0]))

def write(name, value):
    con.execute("UPDATE object_data SET data=? WHERE object_store_id=1 AND key=?", (snappy_compress(sc_encode(value)), idb_key(name)))

# 1. Update options
options = read("socialFocus_options_state")
for platform, opts in SETTINGS.items():
    options.setdefault(platform, {})
    options[platform].update(opts)
write("socialFocus_options_state", options)

# 2. Lock UI permanently
system = read("socialFocus_system_config")
system["socialFocus_extension_ui_state"] = {
    "socialFocus_passwordLockingIsActiveData": True,
    "socialFocus_passwordLockingPasswordData": secrets.token_urlsafe(32),
    "socialFocus_passwordLockingPromptData": "",
    "socialFocus_passwordLockingResetIsActiveData": False,
    "socialFocus_passwordLockingResetPeriodData": 99,
}
write("socialFocus_system_config", system)

# 3. Clear runtime snapshot so CSS compiles fresh on next launch
con.execute("DELETE FROM object_data WHERE object_store_id=1 AND key=?", (idb_key("socialFocus_runtime_snapshot"),))
con.commit()
con.execute("PRAGMA wal_checkpoint(truncate)")
con.close()

print("[✓] SocialFocus settings applied and permanently locked.")
print("[✓] Restart Zen to activate.")
EOF
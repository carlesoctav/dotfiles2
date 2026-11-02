#!/bin/bash
set -e

# Closes nothing: Zen must already be closed. Writes SocialFocus settings straight into its
# IndexedDB: hides most of LinkedIn except Jobs and Messaging, and sets a random password lock
# that is never printed or stored anywhere. Restart Zen afterwards.
# Backup of the original database is kept in ~/.cache/social_focus/.

! pgrep -f '^/app/zen/zen --name' || { echo "Close Zen first"; exit 1; }

python3 - <<'EOF'
import glob, json, re, secrets, shutil, sqlite3, struct, os

PROFILE = os.path.expanduser("~/.var/app/app.zen_browser.zen/.zen/0b1mhmxk.Default (release)")
EXTENSION_ID = "{26b4f076-089c-4c69-8497-44b7e5c9faef}"

LINKEDIN_HIDE = [
    "socialFocus_linkedin_home_feed_hide_home_feed",
    "socialFocus_linkedin_home_feed_hide_home_feed_promoted_posts",
    "socialFocus_linkedin_home_feed_hide_post_metrics",
    "socialFocus_linkedin_home_page_suggested_posts",
    "socialFocus_linkedin_rightBar_hide_sidebar_follows_list",
    "socialFocus_linkedin_rightBar_hide_sidebar_ad_banner",
    "socialFocus_linkedin_rightBar_hide_footer",
    "socialFocus_linkedin_header_hide_button_home",
    "socialFocus_linkedin_header_hide_button_my_network",
    "socialFocus_linkedin_header_hide_button_notifications",
    "socialFocus_linkedin_header_hide_button_for_business",
    "socialFocus_linkedin_other_hide_premium_ads",
    "socialFocus_linkedin_gray_mode",
]
LINKEDIN_SHOW = [
    "socialFocus_linkedin_header_hide_button_jobs",
    "socialFocus_linkedin_header_hide_button_messaging",
    "socialFocus_linkedin_header_hide_button_me",
    "socialFocus_linkedin_other_hide_messaging_popup",
]


# Snappy (raw format, as used by Firefox IndexedDB); compression emits literals only.
def snappy_decompress(b):
    i = n = shift = 0
    while True:
        c = b[i]; i += 1
        n |= (c & 0x7F) << shift; shift += 7
        if not c & 0x80:
            break
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
        if not n:
            break
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


# Firefox/SpiderMonkey structured clone: little-endian u64 words, (tag << 32) | data.
NULL, BOOLEAN, INT32, STRING, OBJECT, END = 0xFFFF0000, 0xFFFF0002, 0xFFFF0003, 0xFFFF0004, 0xFFFF0008, 0xFFFF0013
LATIN1 = 0x80000000


def sc_decode(raw):
    pos = 8  # header word

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
        tag, data = word()
        if tag == BOOLEAN:
            return bool(data)
        if tag == INT32:
            return struct.unpack("<i", struct.pack("<I", data))[0]
        if tag == STRING:
            assert data & LATIN1
            return string(data & ~LATIN1)
        if tag == NULL:
            return None
        assert tag == OBJECT, hex(tag)
        obj = {}
        while True:
            tag, data = word()
            if tag == END:
                return obj
            assert tag == STRING and data & LATIN1
            key = string(data & ~LATIN1)
            obj[key] = value()

    result = value()
    assert pos == len(raw)
    return result


def sc_encode(obj):
    out = bytearray(struct.pack("<II", 3, 0xFFF10000))

    def word(tag, data):
        out.extend(struct.pack("<II", data, tag))

    def string(s):
        b = s.encode("latin-1")
        word(STRING, len(b) | LATIN1)
        out.extend(b + b"\0" * (-len(b) % 8))

    def value(v):
        if v is None:
            word(NULL, 0)
        elif isinstance(v, bool):
            word(BOOLEAN, int(v))
        elif isinstance(v, int):
            word(INT32, v & 0xFFFFFFFF)
        elif isinstance(v, str):
            string(v)
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


uuids = json.loads(re.search(r'user_pref\("extensions.webextensions.uuids", "(.*)"\);', open(f"{PROFILE}/prefs.js").read()).group(1).encode().decode("unicode_escape"))
uuid = uuids[EXTENSION_ID]
db_path = glob.glob(f"{PROFILE}/storage/default/moz-extension+++{uuid}^userContextId=4294967295/idb/*.sqlite")[0]

os.makedirs(os.path.expanduser("~/.cache/social_focus"), exist_ok=True)
shutil.copy(db_path, os.path.expanduser("~/.cache/social_focus/backup.sqlite"))

con = sqlite3.connect(db_path)
# Firefox triggers call this to track blob files; none of our rows reference files.
con.create_function("update_refcount", 2, lambda old, new: None)


def read(name):
    (data,) = con.execute("select data from object_data where object_store_id=1 and key=?", (idb_key(name),)).fetchone()
    return sc_decode(snappy_decompress(data))


def write(name, value):
    con.execute("update object_data set data=? where object_store_id=1 and key=?", (snappy_compress(sc_encode(value)), idb_key(name)))


options = read("socialFocus_options_state")
for option in LINKEDIN_HIDE:
    assert option in options["linkedin"]
    options["linkedin"][option] = True
for option in LINKEDIN_SHOW:
    assert option in options["linkedin"]
    options["linkedin"][option] = False
write("socialFocus_options_state", options)

system = read("socialFocus_system_config")
system["socialFocus_extension_ui_state"] = {
    "socialFocus_passwordLockingIsActiveData": True,
    "socialFocus_passwordLockingPasswordData": secrets.token_urlsafe(32),
    "socialFocus_passwordLockingPromptData": "",
    "socialFocus_passwordLockingResetIsActiveData": False,
    # Not one of SocialFocus's 16 reset durations, so its "Reset password" button can never schedule a reset.
    "socialFocus_passwordLockingResetPeriodData": 99,
}
write("socialFocus_system_config", system)

# Forces SocialFocus to rebuild its runtime snapshot (hiding CSS) from the new options on startup.
con.execute("delete from object_data where object_store_id=1 and key=?", (idb_key("socialFocus_runtime_snapshot"),))
con.commit()
con.execute("pragma wal_checkpoint(truncate)")
con.close()
print("SocialFocus configured. Start Zen.")
EOF

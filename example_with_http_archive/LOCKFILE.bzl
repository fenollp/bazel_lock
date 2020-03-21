locked = {
    "version": "zero",
    "targets": {
        "bazel_skylib": {
            "kind": "http_archive",
            "sha256": "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
            # Also lock pin + pinned_url? ("pinned": {...})
            # Keep all deps that were once locked? (for downgrading)
        },
    },
}

#!/usr/bin/env python3
"""Post-process project.pbxproj to add .lproj localization files."""

import json, subprocess, sys, hashlib
from pathlib import Path

PROJECT = "JianDan.xcodeproj/project.pbxproj"
LPROJ_ROOT = "JianDan/Resources"

LANGUAGES = [
    ("zh-Hans", "zh-Hans.lproj"),
    ("en", "en.lproj"),
    ("ja", "ja.lproj"),
]

LOCALIZED_FILES = [
    ("InfoPlist.strings", "text.plist.strings"),
    ("Localizable.strings", "text.plist.strings"),
]


def short_hash(s: str) -> str:
    return hashlib.md5(s.encode()).hexdigest()[:24].upper()


def run():
    json_path = "/tmp/pbxproj.json"
    subprocess.run(["plutil", "-convert", "json", PROJECT, "-o", json_path], check=True)

    with open(json_path, "r") as f:
        pbx = json.load(f)

    objects = pbx["objects"]

    # Find target, resources phase, and Resources group
    target_id = resources_phase_id = resources_group_id = None

    for oid, obj in objects.items():
        if not isinstance(obj, dict):
            continue
        if obj.get("isa") == "PBXNativeTarget" and obj.get("name") == "JianDan":
            target_id = oid
        if obj.get("isa") == "PBXResourcesBuildPhase":
            resources_phase_id = oid
        if obj.get("isa") == "PBXGroup" and obj.get("path") == "Resources" and obj.get("name") is None:
            resources_group_id = oid

    if not all([target_id, resources_phase_id, resources_group_id]):
        print(f"ERROR: target={target_id} phase={resources_phase_id} group={resources_group_id}", file=sys.stderr)
        sys.exit(1)

    print(f"Target: {target_id}")
    print(f"Resources phase: {resources_phase_id}")
    print(f"Resources group: {resources_group_id}")

    # Add file references, variant groups, build files for each localized file
    for base_name, file_type in LOCALIZED_FILES:
        variant_id = short_hash(f"variant_{base_name}")
        children = []

        for lang_code, lproj_dir in LANGUAGES:
            file_path = f"{LPROJ_ROOT}/{lproj_dir}/{base_name}"
            if not Path(file_path).exists():
                print(f"WARNING: {file_path} not found, skipping")
                continue

            fid = short_hash(f"ref_{base_name}_{lang_code}")
            rel_path = f"{lproj_dir}/{base_name}"
            objects[fid] = {
                "isa": "PBXFileReference",
                "lastKnownFileType": file_type,
                "name": base_name,
                "path": rel_path,
                "sourceTree": "<group>",
            }
            children.append(fid)

        if not children:
            continue

        # PBXVariantGroup
        objects[variant_id] = {
            "isa": "PBXVariantGroup",
            "children": children,
            "name": base_name,
            "sourceTree": "<group>",
        }

        # PBXBuildFile
        build_id = short_hash(f"build_{base_name}")
        objects[build_id] = {
            "isa": "PBXBuildFile",
            "fileRef": variant_id,
        }

        # Add to resources build phase
        rp = objects[resources_phase_id]
        if build_id not in rp.get("files", []):
            rp["files"].append(build_id)

        # Add variant group to Resources group
        rg = objects[resources_group_id]
        if variant_id not in rg.get("children", []):
            rg["children"].append(variant_id)

        print(f"  {base_name} ({len(children)} languages)")

    # Update knownRegions in rootObject
    root_oid = pbx.get("rootObject")
    if root_oid and root_oid in objects:
        root_obj = objects[root_oid]
        known = root_obj.get("knownRegions", ["Base"])
        for lang_code, _ in LANGUAGES:
            if lang_code not in known:
                known.append(lang_code)
        root_obj["knownRegions"] = known
        print(f"knownRegions: {known}")

    # Write back
    with open(json_path, "w") as f:
        json.dump(pbx, f, indent=2, ensure_ascii=False)

    subprocess.run(["plutil", "-convert", "xml1", json_path, "-o", PROJECT], check=True)
    print(f"Updated {PROJECT}")


if __name__ == "__main__":
    run()

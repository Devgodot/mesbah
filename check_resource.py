import os
import json
import re
import sys

# مسیر پروژه
PROJECT_DIR = "/home/pachim/messbah403.ir"
RESOURCE_MAP_FILE = os.path.join(PROJECT_DIR, "resource_usages.json")

# فایل صحنه که تغییر کرده
if len(sys.argv) < 2:
    print("Usage: python update_resource_map.py <changed_scene.tscn>")
    sys.exit(1)

changed_scene_file = sys.argv[1]
scene_name = os.path.basename(changed_scene_file)

# بارگذاری JSON موجود
if os.path.exists(RESOURCE_MAP_FILE):
    with open(RESOURCE_MAP_FILE, "r", encoding="utf-8") as f:
        resource_map = json.load(f)
else:
    resource_map = {}

# --- مرحله 1: ساخت mapping ext_resource ---
ext_resources = {}  # id -> res://path
ext_res_pattern = re.compile(r'\[ext_resource.*?id="([^"]+)".*?path="([^"]+)"')

# --- مرحله 2: پیدا کردن propertyهای نود ---
prop_pattern = re.compile(r'(\w+)\s*=\s*ExtResource\("([^"]+)"\)')

current_node = None
scene_usages = {}
current_resources = set()

with open(changed_scene_file, "r", encoding="utf-8") as f:
    for line in f:
        # ext_resource
        ext_match = ext_res_pattern.match(line)
        if ext_match:
            res_id, res_path = ext_match.groups()
            ext_resources[res_id] = res_path
            continue

        # node
        node_match = re.match(r'\[node name="([^"]+)" type="([^"]+)"', line)
        if node_match:
            current_node = node_match.group(1)
            continue

        # property با ExtResource
        for prop_name, res_id in prop_pattern.findall(line):
            if res_id not in ext_resources:
                continue
            res_path = ext_resources[res_id]
            current_resources.add(res_path)
            usage = {"scene": scene_name, "node": current_node, "property": prop_name}
            scene_usages.setdefault(res_path, []).append(usage)

# --- مرحله 3: آپدیت resource_map ---
for res_path in current_resources:
    full_path = os.path.join(PROJECT_DIR, res_path.replace("res://", "static/files/resource/"))
    mtime = int(os.path.getmtime(full_path) * 1000) if os.path.exists(full_path) else None

    if res_path not in resource_map:
        resource_map[res_path] = {"mtime": mtime, "usages": scene_usages[res_path]}
    else:
        resource_map[res_path]["mtime"] = mtime
        # حذف usageهای قبلی مربوط به این صحنه
        resource_map[res_path]["usages"] = [u for u in resource_map[res_path]["usages"] if u["scene"] != scene_name]
        # اضافه کردن usage‌های جدید
        resource_map[res_path]["usages"].extend(scene_usages[res_path])

# حذف ریسورس‌هایی که قبلاً در این صحنه بودند اما الان حذف شده
for res_path, info in resource_map.items():
    if res_path not in current_resources:
        info["usages"] = [u for u in info["usages"] if u["scene"] != scene_name]

# ذخیره JSON نهایی
with open(RESOURCE_MAP_FILE, "w", encoding="utf-8") as f:
    json.dump(resource_map, f, indent=2, ensure_ascii=False)

print(f"✅ Resource map updated for scene: {scene_name}")

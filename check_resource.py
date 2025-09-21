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

# regex برای پیدا کردن ریسورس‌ها و property
RESOURCE_PATTERN = re.compile(r'(\w+)\s*=\s*ExtResource\("([^"]+)"\)')

# خواندن ریسورس‌های موجود در صحنه
current_resources = set()
scene_usages = {}

with open(changed_scene_file, "r", encoding="utf-8") as f:
    current_node = None
    for line in f:
        # پیدا کردن نود
        node_match = re.match(r'\[node name="([^"]+)" type="([^"]+)"\]', line)
        if node_match:
            current_node = node_match.group(1)
        # پیدا کردن property و ریسورس
        for prop_name, res_name in RESOURCE_PATTERN.findall(line):
            current_resources.add(res_name)
            usage = {"scene": scene_name, "node": current_node, "property": prop_name}
            scene_usages.setdefault(res_name, []).append(usage)

# آپدیت resource_map
for res_name in current_resources:
    full_path = os.path.join(PROJECT_DIR, res_name.replace("res://", "static/files/resource/"))
    mtime = int(os.path.getmtime(full_path) * 1000) if os.path.exists(full_path) else None

    if res_name not in resource_map:
        resource_map[res_name] = {"mtime": mtime, "usages": scene_usages[res_name]}
    else:
        resource_map[res_name]["mtime"] = mtime
        # حذف usageهای قبلی مربوط به این صحنه
        resource_map[res_name]["usages"] = [u for u in resource_map[res_name]["usages"] if u["scene"] != scene_name]
        # اضافه کردن usage‌های جدید
        resource_map[res_name]["usages"].extend(scene_usages[res_name])

# حذف ریسورس‌هایی که قبلاً در این صحنه بودند اما الان حذف شده
for res_name, info in resource_map.items():
    if res_name not in current_resources:
        info["usages"] = [u for u in info["usages"] if u["scene"] != scene_name]

# ذخیره JSON نهایی
with open(RESOURCE_MAP_FILE, "w", encoding="utf-8") as f:
    json.dump(resource_map, f, indent=2, ensure_ascii=False)

print(f"✅ Resource map updated for scene: {scene_name}")

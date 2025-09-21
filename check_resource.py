from git import Repo
import os
import re
import json

# مسیر ریپو و مسیر ریسورس‌ها
PROJECT_DIR = "/home/pachim/messbah403.ir"
RESOURCE_DIR = os.path.join(PROJECT_DIR, "static/files/resource")
repo = Repo(PROJECT_DIR)

# گرفتن تغییرات آخرین commit
diff = repo.head.commit.diff("HEAD~1")

# فایل JSON مقصد
OUTPUT_FILE = os.path.join(PROJECT_DIR, "resource_usages.json")

# بارگذاری JSON موجود یا ایجاد دیکشنری جدید
if os.path.exists(OUTPUT_FILE):
    with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
        resource_map = json.load(f)
else:
    resource_map = {}

# regex برای پیدا کردن ریسورس‌ها و property
RESOURCE_PATTERN = re.compile(r'(\w+)\s*=\s*ExtResource\("([^"]+)"\)')

def parse_scene(file_path):
    usages = []
    current_node = None
    with open(file_path, "r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            # پیدا کردن نود
            node_match = re.match(r'\[node name="([^"]+)" type="([^"]+)"\]', line)
            if node_match:
                current_node = node_match.group(1)
            # پیدا کردن property با ریسورس
            for prop_match in RESOURCE_PATTERN.findall(line):
                prop_name, resource_path = prop_match
                # فقط ریسورس‌هایی که داخل مسیر RESOURCE_DIR هستند را ثبت کنیم
                full_resource_path = os.path.join(PROJECT_DIR, resource_path.replace("res://", ""))
                if full_resource_path.startswith(RESOURCE_DIR):
                    usages.append({
                        "scene": os.path.basename(file_path),
                        "node": current_node,
                        "property": prop_name,
                        "resource": resource_path
                    })
    return usages

# بررسی تغییرات فقط روی فایل‌های .tscn/.scn
for change in diff:
    if change.change_type in ("A", "M"):
        if change.b_path.endswith(".tscn") or change.b_path.endswith(".scn"):
            scene_path = os.path.join(PROJECT_DIR, change.b_path)
            if os.path.exists(scene_path):
                usages = parse_scene(scene_path)
                for usage in usages:
                    resource = usage["resource"]
                    full_resource_path = os.path.join(PROJECT_DIR, resource.replace("res://", ""))

                    # گرفتن timestamp جدید
                    if os.path.exists(full_resource_path):
                        mtime = int(os.path.getmtime(full_resource_path) * 1000)
                    else:
                        mtime = None

                    # اگر ریسورس قبلا وجود نداشته یا mtime تغییر کرده، آپدیت کن
                    if resource not in resource_map or resource_map[resource].get("mtime") != mtime:
                        resource_map[resource] = {
                            "mtime": mtime,
                            "usages": []
                        }
                    # اضافه کردن usage جدید فقط اگر قبلا ثبت نشده
                    usage_entry = {
                        "scene": usage["scene"],
                        "node": usage["node"],
                        "property": usage["property"]
                    }
                    if usage_entry not in resource_map[resource]["usages"]:
                        resource_map[resource]["usages"].append(usage_entry)

# ذخیره JSON نهایی
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    json.dump(resource_map, f, indent=2, ensure_ascii=False)

print(f"✅ Resource usage map updated (incremental) at {OUTPUT_FILE}")

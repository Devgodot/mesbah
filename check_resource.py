import json
import re
import os
import sys
from pathlib import Path
from collections import defaultdict
import datetime

# <<< changed: لاگ فایل و debug_print به‌روزرسانی شدند
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_PATH = os.path.join(SCRIPT_DIR, "check_resource.log")

def debug_print(message):
    """برای چاپ دیباگ — هم stdout هم فایل لاگ"""
    ts = datetime.datetime.now().isoformat(sep=' ', timespec='seconds')
    line = f"🔍 {ts} {message}"
    try:
        print(line)
    except Exception:
        pass
    try:
        with open(LOG_PATH, "a", encoding="utf-8") as lf:
            lf.write(line + "\n")
    except Exception:
        # fallback: ساکت باشیم اگر لاگ نوشتن شکست خورد
        pass

def update_resource_usages(tscn_file_path, output_file="resource_usages.json"):
    """لیست منابع را update می‌کند."""
    
    # خواندن فایل موجود (اگر وجود دارد)
    existing_data = {}
    if os.path.exists(output_file):
        try:
            # <<< changed: اگر فایل خالی باشد یا JSON نامعتبر، از دیکشنری خالی استفاده کن
            if os.path.getsize(output_file) == 0:
                debug_print("فایل موجود خالی است، از داده‌ی خالی استفاده می‌کنیم")
                existing_data = {}
            else:
                with open(output_file, 'r', encoding='utf-8') as f:
                    existing_data = json.load(f)
                debug_print("فایل موجود خوانده شد")
        except json.JSONDecodeError:
            debug_print("فایل موجود نامعتبر JSON است، از داده‌ی خالی استفاده می‌کنیم")
            existing_data = {}
        except Exception as e:
            debug_print(f"خطا در خواندن فایل موجود: {e}")
            existing_data = {}
    
    # پردازش فایل جدید
    scene_name = os.path.basename(tscn_file_path)
    resources, usages = parse_tscn_file(tscn_file_path)
    
    new_usages_count = 0
    
    # update کردن داده‌ها
    for res_id, node_path, prop_name in usages:
        if res_id in resources:
            resource_path = resources[res_id]
            
            debug_print(f"پردازش استفاده: {resource_path} -> {node_path}.{prop_name}")
            
            if resource_path not in existing_data:
                existing_data[resource_path] = {
                    "mtime": 0,
                    "usages": []
                }
                debug_print(f"منبع جدید اضافه شد: {resource_path}")
            
            # بررسی آیا این usage قبلاً ثبت شده است
            usage_exists = False
            for existing_usage in existing_data[resource_path]["usages"]:
                if (existing_usage["scene"] == scene_name and 
                    existing_usage["node"] == node_path and 
                    existing_usage["property"] == prop_name):
                    usage_exists = True
                    break
            
            # اگر usage جدید است، اضافه شود
            if not usage_exists:
                usage_info = {
                    "scene": scene_name,
                    "node": node_path,
                    "property": prop_name
                }
                existing_data[resource_path]["usages"].append(usage_info)
                new_usages_count += 1
                debug_print(f"استفاده جدید اضافه شد: {node_path}.{prop_name}")
            
            # به روزرسانی mtime
            try:
                # اگر مسیر با res:// شروع شود، آن را به مسیر فیزیکی تبدیل کنید
                if resource_path.startswith("res://"):
                    project_root = os.path.dirname(os.path.dirname(tscn_file_path))
                    resource_full_path = os.path.join(project_root, resource_path[6:])
                else:
                    resource_full_path = os.path.join(os.path.dirname(tscn_file_path), resource_path)
                
                if os.path.exists(resource_full_path):
                    existing_data[resource_path]["mtime"] = int(os.path.getmtime(resource_full_path) * 1000)
            except Exception as e:
                debug_print(f"خطا در به روزرسانی mtime: {e}")
    
    # ذخیره داده‌های updated
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(existing_data, f, ensure_ascii=False, indent=2)
        debug_print("فایل ذخیره شد")
    except Exception as e:
        debug_print(f"خطا در ذخیره فایل: {e}")
    
    return existing_data, new_usages_count

def parse_tscn_file(file_path):
    """پارسِ بهتر .tscn — بازگشت: (resources_dict, usages_list)
    resources: ext_id -> res://... path
    usages: list of (ext_id, node_path, property_path)
    """
    resources = {}
    sub_resources = {}   # id -> {"type": type, "lines": [...], "body": str}
    nodes = []           # {"name":..., "parent":..., "props": {k: v}}
    usages = []

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        debug_print(f"حجم فایل: {len(content)} کاراکتر")

        # 1) تمام ext_resource ها
        for m in re.finditer(r'^\[ext_resource\b([^\]]*)\]', content, re.MULTILINE | re.IGNORECASE):
            attrs = m.group(1)
            id_m = re.search(r'\bid\s*=\s*["\']([^"\']+)["\']', attrs)
            path_m = re.search(r'\bpath\s*=\s*["\']([^"\']+)["\']', attrs)
            if id_m and path_m:
                rid = id_m.group(1)
                rpath = path_m.group(1)
                resources[rid] = rpath
                debug_print(f"  ✅ ext_resource: id={rid} -> path={rpath}")
            else:
                debug_print(f"  ❌ ext_resource بدون id/path: {attrs[:80]}")

        debug_print(f"تعداد ext_resource پیدا شده: {len(resources)}")

        # 2) بخش‌بندی همه بلاک‌ها (sub_resource/resource) — نگه داشتن subresourceها
        block_pattern = re.compile(
            r'^\[(sub_resource|resource)\b([^\]]*)\]\s*((?:.*?))(?:^\[|\Z)',
            re.MULTILINE | re.DOTALL | re.IGNORECASE
        )
        for bm in block_pattern.finditer(content):
            btype = bm.group(1).lower()
            header = bm.group(2)
            body = bm.group(3).rstrip()
            idm = re.search(r'\bid\s*=\s*["\']([^"\']+)["\']', header)
            sid = idm.group(1) if idm else None
            sub_resources[sid] = {
                "type": btype,
                "body": body,
                "lines": [ln.rstrip() for ln in body.splitlines() if ln.strip()]
            }
            debug_print(f"  ⬩ ثبت {btype} id={sid} lines={len(sub_resources[sid]['lines'])}")

        # جداگانه: پاس صریح برای تمام بلاک‌های node تا هیچ نودی از دست نرود
        node_pattern = re.compile(r'^\[node\b([^\]]*)\]\s*((?:.*?))(?:^\[|\Z)', re.MULTILINE | re.DOTALL | re.IGNORECASE)
        for nm in node_pattern.finditer(content):
            header = nm.group(1)
            body = nm.group(2).rstrip()
            name_m = re.search(r'\bname\s*=\s*["\']([^"\']+)["\']', header)
            parent_m = re.search(r'\bparent\s*=\s*["\']([^"\']+)["\']', header)
            name = name_m.group(1) if name_m else "node_unknown"
            parent_val = parent_m.group(1) if parent_m else "."
            # جمع‌آوری پراپرتی‌ها با پشتیبانی از مقادیر چندخطی
            props = {}
            lines = body.splitlines()
            i = 0
            while i < len(lines):
                line = lines[i].rstrip()
                if not line.strip() or '=' not in line:
                    i += 1
                    continue
                key, val = line.split('=', 1)
                key = key.strip()
                val = val.rstrip()
                j = i + 1
                while j < len(lines) and not re.match(r'^[^\s=]+\s*=', lines[j]):
                    val += '\n' + lines[j].rstrip()
                    j += 1
                props[key] = val.strip()
                i = j
            nodes.append({"name": name, "parent": parent_val, "props": props})
            debug_print(f"  ▣ node ثبت شد: {name}, parent={parent_val}, props={len(props)}")

        # توابع کمکی یک‌بار
        def extract_ext_ids(text):
            return re.findall(r'(?:ExtResource|Resource)\(\s*["\']([^"\']+)["\']\s*\)', text or '')

        # بهبود: SubResource یا Resource را به‌عنوان مرجع زیرریسورس هم در نظر بگیر
        def extract_sub_ids(text):
            # قبلاً فقط SubResource را می‌گرفت؛ حالا Resource(...) هم می‌گیرد چون بعضی فایل‌ها از این فرم استفاده می‌کنند
            return re.findall(r'(?:SubResource|Resource)\(\s*["\']([^"\']+)["\']\s*\)', text or '')

        def expand_subresource(sub_id, prefix, node_path, visited, from_theme=False):
            """بازپخش یک sub_resource.
            تغییر: برای theme هم از prefix + '/' + key استفاده می‌کنیم تا property دقیق‌تری ساخته شود.
            همچنین اگر subresource پیدا نشد لاگ می‌زنیم.
            """
            if not sub_id or sub_id in visited:
                return
            visited.add(sub_id)
            info = sub_resources.get(sub_id)
            if not info:
                debug_print(f"❗ subresource پیدا نشد: {sub_id}")
                return
            for ln in info.get("lines", []):
                if '=' not in ln:
                    continue
                key, val = ln.split('=', 1)
                key = key.strip()
                val = val.strip()
                # مستقیم ExtResource/Resource
                for rid in extract_ext_ids(val):
                    # همیشه مسیر دقیق بساز: اگر prefix هست از prefix/{key} استفاده کن
                    if prefix:
                        prop = f"{prefix}/{key}"
                    else:
                        prop = key
                    usages.append((rid, node_path, prop))
                    debug_print(f"  ✅ expand: ExtResource({rid}) -> {node_path}.{prop}")
                # بازپخش SubResource (همیشه new_prefix = prefix/{key} اگر prefix موجود باشد)
                for subchild in extract_sub_ids(val):
                    new_prefix = f"{prefix}/{key}" if prefix else key
                    expand_subresource(subchild, new_prefix, node_path, visited, from_theme)

        # 3) بررسی نودها: ExtResource مستقیم و SubResourceها را بازپخش کن
        for n in nodes:
            node_path = n["name"] if n["parent"] == "." else f"{n['parent']}/{n['name']}"
            for key, val in n["props"].items():
                for rid in extract_ext_ids(val):
                    usages.append((rid, node_path, key))
                    debug_print(f"  ✅ usage مستقیم: ExtResource({rid}) in {node_path} property={key}")
                for subid in extract_sub_ids(val):
                    # اگر این property اسمش "theme" بود از منظر theme بازپخش کن
                    expand_subresource(subid, key, node_path, set(), from_theme=(key == "theme"))

        # 4) اگر Theme-like sub_resource تعریف شده ولی هیچ نودی آن را ارجاع نکرده، 
        # آن را به ریشه اعمال کن (prefix = "theme") تا propertyهایی شبیه theme/Button/... بشوند
        # build subresource-reference graph (sub -> children)
        sub_graph = {}
        for sid, info in sub_resources.items():
            children = []
            for ln in info.get("lines", []):
                children += extract_sub_ids(ln)
            sub_graph[sid] = children

        # find all subresource ids that are directly referenced by node properties
        referenced_direct = set()
        for n in nodes:
            for val in n["props"].values():
                for subid in extract_sub_ids(val):
                    referenced_direct.add(subid)

        # mark all subresources reachable from any directly referenced subresource
        reachable = set()
        stack = list(referenced_direct)
        while stack:
            cur = stack.pop()
            if cur in reachable:
                continue
            reachable.add(cur)
            for ch in sub_graph.get(cur, []):
                if ch not in reachable:
                    stack.append(ch)

        # If a subresource looks like a theme (contains nested keys with '/')
        # but is not referenced (directly or indirectly) from nodes, apply it to root.
        root = next((n for n in nodes if n["parent"] == "."), None)
        if root:
            root_name = root["name"]
            for sid, info in sub_resources.items():
                lines = info.get("lines", [])
                looks_like_theme = any('=' in ln and '/' in ln.split('=',1)[0] for ln in lines)
                referenced = (sid in reachable) or (sid in referenced_direct)
                if looks_like_theme and not referenced:
                    debug_print(f"↪ اعمال خودکار Theme subresource {sid} به ریشه بعنوان theme")
                    expand_subresource(sid, "theme", root_name, set(), from_theme=True)

        # <<< تغییر مهم: اول fallback را اجرا کن تا همه prop = ExtResource(...) به نودها نسبت داده شوند
        prop_ext_pattern = re.compile(r'([^\n\r=]+)\s*=\s*(?:ExtResource|Resource)\(\s*["\']([^"\']+)["\']\s*\)')
        for m in prop_ext_pattern.finditer(content):
            prop_name = m.group(1).strip()
            rid = m.group(2)
            if any(u[0] == rid and u[2] == prop_name for u in usages):
                continue
            pos = m.start()
            idx = content.rfind('[node', 0, pos)
            node_path = "file_level"
            if idx != -1:
                header_end = content.find(']', idx)
                header = content[idx+5:header_end] if header_end != -1 else ''
                nm = re.search(r'\bname\s*=\s*["\']([^"\']+)["\']', header)
                parent = re.search(r'\bparent\s*=\s*["\']([^"\']+)["\']', header)
                name = nm.group(1) if nm else "node_unknown"
                parent_val = parent.group(1) if parent else "."
                node_path = name if parent_val == "." else f"{parent_val}/{name}"
            usages.append((rid, node_path, prop_name))
            debug_print(f"↪ fallback اضافه شد: ExtResource({rid}) -> {node_path}.{prop_name}")

        # حالا ثبت file_level فقط برای ریسورس‌هایی که واقعاً هنوز بدون mapping مانده‌اند
        recorded_exts = {u[0] for u in usages}
        for sid, info in sub_resources.items():
            for ln in info.get("lines", []):
                for rid in extract_ext_ids(ln):
                    if rid not in recorded_exts:
                        usages.append((rid, "file_level", sid))
                        debug_print(f"  ✅ file_level: ExtResource({rid}) in subresource {sid}")


        # حذف file_level اضافی: اگر برای یک ext_id حداقل یک mapping غیر-file_level وجود دارد،
        # entryهای file_level همان ext_id را حذف کن.
        from collections import defaultdict
        usages_by_ext = defaultdict(list)
        for rid, node_path, prop_name in usages:
            usages_by_ext[rid].append((node_path, prop_name))

        cleaned = []
        for rid, lst in usages_by_ext.items():
            non_file = [u for u in lst if u[0] != "file_level"]
            if non_file:
                for node_path, prop_name in non_file:
                    cleaned.append((rid, node_path, prop_name))
            else:
                for node_path, prop_name in lst:
                    cleaned.append((rid, node_path, prop_name))

        usages = cleaned
        debug_print(f"بعد از پاکسازی file_level‌های اضافی: تعداد usage = {len(usages)}")

        debug_print(f"تعداد ext: {len(resources)}, تعداد usage استخراج‌شده: {len(usages)}")

        # <<< added: تولید فایل تشخیصی برای بررسی دقیق
        try:
            scene_base = os.path.splitext(os.path.basename(file_path))[0]
            debug_json_path = os.path.join(SCRIPT_DIR, f"{scene_base}.debug.json")
            # لیست ext_id هایی که فقط file_level دارند
            uses_by_ext = defaultdict(list)
            for rid, node_path, prop_name in usages:
                uses_by_ext[rid].append({"node": node_path, "property": prop_name})
            file_level_only = [rid for rid, lst in uses_by_ext.items() if all(u["node"] == "file_level" for u in lst)]
            dump = {
                "scene": os.path.basename(file_path),
                "resources": resources,
                "sub_resources": {k: v.get("lines") for k, v in sub_resources.items()},
                "nodes_count": len(nodes),
                "nodes_sample": nodes[:10],
                "usages": [{"ext_id": r, "node": n, "property": p} for r,n,p in usages],
                "file_level_only_ext_ids": file_level_only
            }
            with open(debug_json_path, "w", encoding="utf-8") as df:
                json.dump(dump, df, ensure_ascii=False, indent=2)
            debug_print(f"فایل تشخیصی نوشته شد: {debug_json_path}")
        except Exception as e:
            debug_print(f"خطا در نوشتن فایل تشخیصی: {e}")

        return resources, usages

    except Exception as e:
        debug_print(f"خطا در parse_tscn_file: {e}")
        import traceback
        traceback.print_exc()
        return {}, []

def rebuild_scene_usages(tscn_file_path, output_file="resource_usages.json"):
    """برای یک صحنه، تمام استفاده‌ها در resource_usages.json را بازسازی و جایگزین می‌کند."""
    scene_name = os.path.basename(tscn_file_path)

    # خواندن json موجود
    existing_data = {}
    if os.path.exists(output_file):
        try:
            with open(output_file, 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
            debug_print("فایل resource_usages.json خوانده شد")
        except Exception as e:
            debug_print(f"خطا در خواندن فایل موجود: {e}")
            existing_data = {}

    resources, usages = parse_tscn_file(tscn_file_path)

    # حذف همه استفاده‌های قبلی مربوط به این صحنه
    for rp, data in list(existing_data.items()):
        data['usages'] = [u for u in data.get('usages', []) if u.get('scene') != scene_name]

    # اضافه کردن استفاده‌های جدید طبق parse
    added = 0
    for rid, node_path, prop_name in usages:
        if rid not in resources:
            continue
        resource_path = resources[rid]
        if resource_path not in existing_data:
            existing_data[resource_path] = {"mtime": 0, "usages": []}
        usage_info = {"scene": scene_name, "node": node_path, "property": prop_name}
        existing_data[resource_path]["usages"].append(usage_info)
        added += 1
        debug_print(f"استفاده جدید (rebuild) اضافه شد: {resource_path} <- {node_path}.{prop_name}")

    # ذخیره
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(existing_data, f, ensure_ascii=False, indent=2)
        debug_print(f"resource_usages.json به‌روزرسانی شد ({added} مورد اضافه شد)")
    except Exception as e:
        debug_print(f"خطا در ذخیره فایل: {e}")

    return existing_data, added

def main():
    # پشتیبانی از دو حالت: معمولی یا --rebuild
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python check_resource.py path/to/file.tscn [--rebuild]")
        sys.exit(1)

    tscn_file_path = sys.argv[1]
    do_rebuild = len(sys.argv) == 3 and sys.argv[2] == "--rebuild"

    if not os.path.exists(tscn_file_path):
        print(f"فایل {tscn_file_path} پیدا نشد!")
        sys.exit(1)

    if not tscn_file_path.endswith('.tscn'):
        print("لطفاً یک فایل .tscn وارد کنید!")
        sys.exit(1)

    print(f"📁 در حال پردازش: {tscn_file_path}")
    if do_rebuild:
        result, new_count = rebuild_scene_usages(tscn_file_path)
    else:
        result, new_count = update_resource_usages(tscn_file_path)

    print(f"\n📊 نتایج:")
    print(f"   منابع کل: {len(result)}")
    print(f"   تغییرات جدید: {new_count}")
    print(f"📝 نتایج در resource_usages.json ذخیره شد.")
# ...existing code...


if __name__ == "__main__":
    main()
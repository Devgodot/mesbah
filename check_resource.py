import json
import re
import os
import sys
from pathlib import Path
from collections import defaultdict

def debug_print(message):
    """برای چاپ دیباگ"""
    print(f"🔍 {message}")

def parse_tscn_file(file_path):
    """فایل .tscn را پردازش می‌کند و منابع استفاده شده را برمی‌گرداند."""
    
    resources = {}
    usages = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        debug_print(f"حجم فایل: {len(content)} کاراکتر")
        
        # الگوی جدید برای ext_resource - همه اطلاعات در یک خط
        ext_pattern = r'\[ext_resource(.*?)\]'
        ext_matches = re.findall(ext_pattern, content)
        
        debug_print(f"تعداد ext_resource پیدا شده: {len(ext_matches)}")
        
        for i, ext_line in enumerate(ext_matches):
            debug_print(f"ext_resource {i+1}: {ext_line[:100]}...")
            
            # استخراج id
            id_match = re.search(r'id\s*=\s*["\']?([^"\'\s]+)["\']?', ext_line)
            if not id_match:
                debug_print("  ❌ id پیدا نشد")
                continue
            
            # استخراج path
            path_match = re.search(r'path\s*=\s*["\']?([^"\']+)["\']?', ext_line)
            if not path_match:
                debug_print("  ❌ path پیدا نشد")
                continue
            
            resource_id = id_match.group(1)
            resource_path = path_match.group(1).strip('"\'')
            resources[resource_id] = resource_path
            debug_print(f"  ✅ منبع: id={resource_id}, path={resource_path}")
        
        # پیدا کردن تمام استفاده‌های ExtResource در کل فایل
        ext_usage_patterns = [
            r'(\w+)\s*=\s*ExtResource\(\s*["\']?([^"\']+)["\']?\s*\)',  # property = ExtResource("id")
            r'instance\s*=\s*ExtResource\(\s*["\']?([^"\']+)["\']?\s*\)'  # instance=ExtResource("id")
        ]
        
        for pattern in ext_usage_patterns:
            ext_usage_matches = re.findall(pattern, content)
            debug_print(f"الگوی {pattern}: {len(ext_usage_matches)} مورد پیدا شد")
            
            for match in ext_usage_matches:
                if len(match) == 2:
                    prop_name, res_id = match
                    usages.append((res_id, "Unknown", prop_name))
                    debug_print(f"  ✅ استفاده: {prop_name} = ExtResource({res_id})")
                else:
                    res_id = match[0]
                    usages.append((res_id, "Unknown", "instance"))
                    debug_print(f"  ✅ استفاده: instance = ExtResource({res_id})")
        
        # حالا nodeها را برای پیدا کردن مسیر دقیق پردازش می‌کنیم
        node_pattern = r'\[node(.*?)\](.*?)(?=\n\[|\n$|\Z)'
        node_matches = re.findall(node_pattern, content, re.DOTALL)
        
        debug_print(f"تعداد node پیدا شده: {len(node_matches)}")
        
        node_paths = {}  # ذخیره مسیر nodeها بر اساس نام
        
        for header, body in node_matches:
            # نام node
            name_match = re.search(r'name\s*=\s*["\']?([^"\'\s]+)["\']?', header)
            if not name_match:
                continue
            
            node_name = name_match.group(1)
            
            # parent (اگر وجود دارد)
            parent_match = re.search(r'parent\s*=\s*["\']?([^"\'\s]+)["\']?', header)
            node_path = node_name
            
            if parent_match:
                parent_path = parent_match.group(1)
                # اگر parent با "." شروع شود، مسیر نسبی است
                if parent_path.startswith('."'):
                    parent_path = parent_path[2:-1] if parent_path.endswith('"') else parent_path[2:]
                node_path = f"{parent_path}/{node_name}"
            
            # ذخیره مسیر node
            node_paths[node_name] = node_path
            debug_print(f"  ✅ node: {node_name} -> {node_path}")
        
        # به روزرسانی مسیر nodeها در usageها
        final_usages = []
        for res_id, node_name, prop_name in usages:
            if node_name in node_paths:
                final_usages.append((res_id, node_paths[node_name], prop_name))
            else:
                final_usages.append((res_id, node_name, prop_name))
        
        debug_print(f"تعداد منابع: {len(resources)}, تعداد استفاده‌ها: {len(final_usages)}")
        return resources, final_usages
        
    except Exception as e:
        debug_print(f"خطا در پردازش فایل: {str(e)}")
        import traceback
        traceback.print_exc()
        return {}, []

def update_resource_usages(tscn_file_path, output_file="resource_usages.json"):
    """لیست منابع را update می‌کند."""
    
    # خواندن فایل موجود (اگر وجود دارد)
    existing_data = {}
    if os.path.exists(output_file):
        try:
            with open(output_file, 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
            debug_print("فایل موجود خوانده شد")
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

def main():
    # بررسی آرگومان‌های command-line
    if len(sys.argv) != 2:
        print("Usage: python check_resource.py path/to/file.tscn")
        print("مثال: python check_resource.py scenes/level1.tscn")
        sys.exit(1)
    
    tscn_file_path = sys.argv[1]
    
    # بررسی وجود فایل
    if not os.path.exists(tscn_file_path):
        print(f"فایل {tscn_file_path} پیدا نشد!")
        sys.exit(1)
    
    if not tscn_file_path.endswith('.tscn'):
        print("لطفاً یک فایل .tscn وارد کنید!")
        sys.exit(1)
    
    # پردازش فایل
    print(f"📁 در حال پردازش: {tscn_file_path}")
    result, new_count = update_resource_usages(tscn_file_path)
    
    # نمایش خلاصه
    print(f"\n📊 نتایج:")
    print(f"   منابع کل: {len(result)}")
    print(f"   استفاده‌های جدید: {new_count}")
    
    if new_count > 0:
        print(f"✅ {new_count} usage جدید اضافه شد!")
        
        # نمایش برخی از استفاده‌های جدید
        print("\n📋 نمونه‌ای از استفاده‌های جدید:")
        count = 0
        for resource_path, data in result.items():
            for usage in data["usages"]:
                if usage["scene"] == os.path.basename(tscn_file_path):
                    print(f"   {usage['node']}.{usage['property']} -> {resource_path}")
                    count += 1
                    if count >= 5:  # فقط 5 مورد نمایش داده شود
                        break
            if count >= 5:
                break
                
    else:
        print("ℹ️ هیچ usage جدیدی پیدا نشد.")
    
    print(f"📝 نتایج در resource_usages.json ذخیره شد.")

if __name__ == "__main__":
    main()
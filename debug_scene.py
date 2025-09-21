# debug_tscn.py
import sys

def analyze_tscn_structure(file_path):
    """ساختار فایل .tscn را تحلیل می‌کند."""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("=" * 50)
    print(f"تحلیل فایل: {file_path}")
    print("=" * 50)
    
    lines = content.split('\n')
    
    # نمایش 20 خط اول
    print("\n۲۰ خط اول:")
    for i, line in enumerate(lines[:20]):
        print(f"{i+1:2d}: {line}")
    
    # بررسی وجود ext_resource
    ext_resources = [line for line in lines if 'ext_resource' in line.lower()]
    print(f"\nتعداد ext_resource: {len(ext_resources)}")
    for ext in ext_resources:
        print(f"  {ext}")
    
    # بررسی وجود ExtResource(
    ext_usage = [line for line in lines if 'ExtResource(' in line]
    print(f"\nتعداد ExtResource usage: {len(ext_usage)}")
    for usage in ext_usage:
        print(f"  {usage}")
    
    # بررسی ساختار کلی
    sections = []
    current_section = None
    
    for line in lines:
        line = line.strip()
        if line.startswith('[') and line.endswith(']'):
            current_section = line
            sections.append(current_section)
        elif current_section and '=' in line:
            pass
    
    print(f"\nبخش‌های فایل: {len(sections)}")
    for section in sections[:10]:  # فقط 10 بخش اول
        print(f"  {section}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python debug_tscn.py path/to/file.tscn")
        sys.exit(1)
    
    analyze_tscn_structure(sys.argv[1])
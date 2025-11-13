from waitress import serve
from main import app   # یا از فایل و اسم اپلیکیشن توی پروژه‌ات استفاده کن

if __name__ == "__main__":
    serve(app, host="127.0.0.1", port=5000)

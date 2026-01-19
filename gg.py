import os
import time
import subprocess
import json

# ===========================
# ⚙️ ตั้งค่า (CONFIG)
# ===========================
DEFAULT_PLACE_ID = "121864768012064"
CONFIG_FILE = "/sdcard/roblox_layout.json"
SEARCH_KEYWORDS = ["roblox", "arceus", "hydrogen", "fluxus"]

# ===========================
# 🛠️ ฟังก์ชันระบบ
# ===========================

def run_cmd(cmd):
    os.system(cmd)

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except:
            return None
    return None

def save_config(data):
    with open(CONFIG_FILE, "w") as f:
        json.dump(data, f, indent=4)

def scan_packages():
    print("🔍 กำลังสแกนหา Roblox...")
    found_apps = []
    try:
        cmd_output = subprocess.check_output(["pm", "list", "packages"], text=True)
        lines = cmd_output.strip().splitlines()
        
        count = 0
        for line in lines:
            pkg_name = line.replace("package:", "").strip()
            for keyword in SEARCH_KEYWORDS:
                if keyword in pkg_name.lower():
                    # บังคับ Activity เป็นตัวหลักเสมอ
                    activity = "com.roblox.client.Activity"
                    
                    print(f"   👉 เจอ: {pkg_name}")
                    
                    found_apps.append({
                        "name": f"Account {count+1}",
                        "package": pkg_name,
                        "activity": activity,
                        "place_id": DEFAULT_PLACE_ID
                    })
                    count += 1
                    break
    except Exception as e:
        print(f"❌ Error scanning: {e}")
    return found_apps

def launch_app(app):
    pkg = app['package']
    act = app['activity']
    place = app['place_id']
    
    print(f"🚀 Launching: {pkg}...")
    
    # 1. ปิดเกมเก่า
    run_cmd(f"am force-stop {pkg}")
    time.sleep(1)
    
    # 2. เปิดเกม (ตัด --bounds ออกแล้ว)
    # --windowingMode 5 : สั่งให้เปิดเป็นหน้าต่างลอย
    cmd = (
        f"am start -n {pkg}/{act} "
        f"--windowingMode 5 "
        f"-a android.intent.action.VIEW "
        f"-d roblox://placeId={place}"
    )
    run_cmd(cmd)

def main():
    print("--- ROBLOX BOT (NO BOUNDS) ---")
    
    # ลบ Config เก่าทิ้งก่อน เพื่อสแกนใหม่ให้สะอาด
    if os.path.exists(CONFIG_FILE):
        os.remove(CONFIG_FILE)
        
    apps = scan_packages()
    save_config(apps)

    print("\n🏁 เริ่มระบบ... (กด Ctrl+C เพื่อหยุด)")
    
    while True:
        for app in apps:
            launch_app(app)
            print("⏳ รอ 15 วินาที...")
            time.sleep(15)
        
        print("\n💤 รอ 20 นาที...")
        time.sleep(1200)

if __name__ == "__main__":
    main()

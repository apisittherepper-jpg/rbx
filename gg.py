import os
import time
import subprocess
import json

# ===========================
# ⚙️ ตั้งค่า (CONFIG)
# ===========================
DEFAULT_PLACE_ID = "121864768012064"
WIN_WIDTH = 450
WIN_HEIGHT = 700
OFFSET_STEP = 80 
CONFIG_FILE = "/sdcard/roblox_layout.json"
SEARCH_KEYWORDS = ["roblox", "arceus", "hydrogen", "fluxus"]

# ===========================
# 🛠️ ฟังก์ชันระบบ (ไม่มี sudo)
# ===========================

def run_cmd(cmd):
    # รันคำสั่งตรงๆ เพราะเราอยู่ในโหมด su แล้ว
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
        # ใช้ pm list packages ตรงๆ
        cmd_output = subprocess.check_output(["pm", "list", "packages"], text=True)
        lines = cmd_output.strip().splitlines()
        
        count = 0
        for line in lines:
            pkg_name = line.replace("package:", "").strip()
            for keyword in SEARCH_KEYWORDS:
                if keyword in pkg_name.lower():
                    start_x = count * OFFSET_STEP
                    start_y = count * OFFSET_STEP
                    bounds = f"{start_x},{start_y},{start_x + WIN_WIDTH},{start_y + WIN_HEIGHT}"
                    
                    # บังคับ Activity
                    activity = "com.roblox.client.Activity"

                    print(f"   👉 เจอ: {pkg_name}")
                    
                    found_apps.append({
                        "name": f"Account {count+1}",
                        "package": pkg_name,
                        "activity": activity,
                        "place_id": DEFAULT_PLACE_ID,
                        "bounds": bounds
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
    bounds = app['bounds']
    
    print(f"🚀 Launching: {pkg}...")
    
    run_cmd(f"am force-stop {pkg}")
    time.sleep(1)
    
    cmd = (
        f"am start -n {pkg}/{act} "
        f"--windowingMode 5 "
        f"--bounds {bounds} "
        f"-a android.intent.action.VIEW "
        f"-d roblox://placeId={place}"
    )
    run_cmd(cmd)

def main():
    print("--- ROBLOX BOT (ROOT MODE) ---")
    
    # เช็คว่า Config มีไหม
    apps = load_config()
    if not apps:
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

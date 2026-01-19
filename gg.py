import os
import time
import subprocess
import json

# ===========================
# ⚙️ ตั้งค่า (CONFIG)
# ===========================
DEFAULT_PLACE_ID = "121864768012064"

# ขนาดหน้าต่าง
WIN_WIDTH = 450
WIN_HEIGHT = 700
OFFSET_STEP = 80 

# ใช้ /sdcard/ เพื่อแก้ปัญหา Read-only file system
CONFIG_FILE = "/sdcard/roblox_layout.json"

# คำค้นหา
SEARCH_KEYWORDS = ["roblox", "arceus", "hydrogen", "fluxus"]

# ===========================
# 🛠️ ฟังก์ชันระบบ
# ===========================

def run_root(cmd):
    # ถ้าขึ้น Error "No superuser" ให้ลองลบ sudo ออกเหลือแค่ cmd
    # แต่ปกติใส่ไว้ชัวร์กว่า
    os.system(f"sudo {cmd}")

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
    print("🔍 กำลังสแกนหา Roblox และ Mod ในเครื่อง...")
    found_apps = []
    try:
        cmd_output = subprocess.check_output(["pm", "list", "packages"], text=True)
        lines = cmd_output.strip().splitlines()
        
        count = 0
        for line in lines:
            pkg_name = line.replace("package:", "").strip()
            for keyword in SEARCH_KEYWORDS:
                if keyword in pkg_name.lower():
                    # คำนวณตำแหน่ง
                    start_x = count * OFFSET_STEP
                    start_y = count * OFFSET_STEP
                    bounds = f"{start_x},{start_y},{start_x + WIN_WIDTH},{start_y + WIN_HEIGHT}"
                    
                    # --- จุดที่แก้ใหม่ (สำคัญ) ---
                    # บังคับให้ใช้ Activity นี้เสมอ ไม่ว่าชื่อ App จะเป็น clientb หรืออะไรก็ตาม
                    activity = "com.roblox.client.Activity"

                    print(f"   👉 เจอตัวที่ {count+1}: {pkg_name} (Pos: {start_x},{start_y})")
                    
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

def launch_app_staggered(app):
    pkg = app['package']
    act = app['activity']
    place = app['place_id']
    bounds = app['bounds']
    
    print(f"🚀 Launching: {pkg}...")
    
    # 1. ฆ่าโปรเซสเก่า
    run_root(f"am force-stop {pkg}")
    time.sleep(1)
    
    # 2. เปิดเกม
    cmd = (
        f"am start -n {pkg}/{act} "
        f"--windowingMode 5 "
        f"--bounds {bounds} "
        f"-a android.intent.action.VIEW "
        f"-d roblox://placeId={place}"
    )
    run_root(cmd)

def main():
    print("--- ROBLOX AUTO STACKER BOT (FIXED) ---")
    run_root("ls > /dev/null") 

    # 1. โหลดหรือสแกนใหม่
    apps = load_config()
    
    # ถ้าไม่เจอ หรือ อยากสแกนใหม่ (เช็คไฟล์ว่างเปล่า)
    if not apps:
        print("⚠️ ไม่พบ Config เริ่มสแกนใหม่...")
        apps = scan_packages()
        save_config(apps)
    else:
        print(f"✅ โหลดข้อมูลเดิม ({len(apps)} แอพ)")

    # 2. เริ่มรัน
    print("\n🏁 เริ่มเปิดแอพ... (กด Ctrl+C เพื่อหยุด)")
    
    while True:
        for app in apps:
            launch_app_staggered(app)
            print("⏳ รอ 15 วินาทีก่อนเปิดตัวถัดไป...")
            time.sleep(15)
        
        print("\n💤 เปิดครบแล้ว... รอ 20 นาที")
        time.sleep(1200)

if __name__ == "__main__":
    main()

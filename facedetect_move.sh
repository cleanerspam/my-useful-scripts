#!/bin/bash
set -e

trap "echo -e '\n❌ Script interrupted by user (Ctrl+C). Exiting cleanly.'; exit 1" SIGINT
echo "📢 You can press Ctrl+C at any time to cancel this process."

# ========== Filesystem & WSL Check ==========
OSREL=$(cat /proc/sys/kernel/osrelease)
MOUNT_TYPE=$(df -T . | awk 'NR==2 {print $2}')
echo "📁 Filesystem type detected: $MOUNT_TYPE"

IS_WSL=false
if [[ "$OSREL" =~ [Mm]icrosoft ]]; then
    IS_WSL=true
    echo "🧠 Detected: Running inside Windows Subsystem for Linux (WSL)"
fi

if [[ "$MOUNT_TYPE" == "ntfs" || "$MOUNT_TYPE" == "9p" || "$IS_WSL" == true ]]; then
    echo "⚠️ Current directory is on a slow or Windows-mounted filesystem (type: $MOUNT_TYPE)"
    echo -e "\n🚨 Python operations (e.g., pip installs, venv creation) are extremely slow or may fail on:"
    echo "   ➤ /mnt/c, /mnt/d, etc. — these are Windows-mounted drives inside WSL"
    echo "   ➤ NTFS/9p filesystems used by shared folders or network mounts"
    echo
    echo "💡 Your WSL home directory (e.g., /home/$(whoami)) is on a native Linux ext4 partition."
    echo "   It provides stable, fast performance for Python and virtual environments."

    if [ -d "$HOME/facedetect" ]; then
        echo "✅ Found existing virtual environment at \$HOME/facedetect — reusing it."
        VENV_PATH="$HOME/facedetect"
    else
        read -p "👉 Install virtual environment in your WSL home directory (~)? [Y/n]: " use_home
        use_home=${use_home:-y}
        if [[ "$use_home" =~ ^[Yy]$ ]]; then
            VENV_PATH="$HOME/facedetect"
        else
            VENV_PATH="./facedetect"
        fi
    fi
else
    echo "✅ Filesystem is Linux-native ($MOUNT_TYPE) — proceeding normally."
    VENV_PATH="./facedetect"
fi

# ========== Distro Package Manager Detection ==========
source /etc/os-release
case "$ID" in
    ubuntu|debian) PM="apt"; INSTALL="sudo apt update && sudo apt install -y";;
    arch) PM="pacman"; INSTALL="sudo pacman -Sy --noconfirm";;
    fedora) PM="dnf"; INSTALL="sudo dnf install -y";;
    opensuse*|suse) PM="zypper"; INSTALL="sudo zypper install -y";;
    *) echo "⚠️ Unsupported distro '$ID'. Please install Python 3.10+ manually."; exit 1;;
esac

# ========== Preferred Python Detection ==========
PREFERRED_PYTHONS=("python3.10" "python3.12" "python3.11" "python3")
for candidate in "${PREFERRED_PYTHONS[@]}"; do
    if command -v $candidate >/dev/null 2>&1; then
        PY=$candidate
        break
    fi
done
if [ -z "$PY" ] && command -v python >/dev/null 2>&1; then
    PY=python
fi
if [ -z "$PY" ]; then
    echo "❌ No suitable Python interpreter found. Install Python 3.10 or newer."
    exit 1
fi

PY_VER=$($PY -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
PY_MAJOR=$($PY -c 'import sys; print(sys.version_info[0])')
PY_MINOR=$($PY -c 'import sys; print(sys.version_info[1])')

if [ "$PY_MAJOR" -lt 3 ] || ( [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ] ); then
    echo "❌ Detected Python $PY_VER — Python 3.10 or newer is required."
    exit 1
fi

echo "✅ Using Python $PY_VER ($PY)"

# ========== Ensure pip and venv ==========
check_install() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "📦 '$1' not found. Install it? [Y/n]"
        read -r ans
        if [[ "$ans" =~ ^[Yy]?$ ]]; then
            $INSTALL "$2"
        else
            echo "❌ Cannot continue without '$1'."; exit 1
        fi
    fi
}
check_install pip3 python3-pip

if ! $PY -m venv --help >/dev/null 2>&1; then
    echo "📦 Python venv module not available. Install it? [Y/n]"
    read -r ans
    if [[ "$ans" =~ ^[Yy]?$ ]]; then
        case "$PM" in
            apt) $INSTALL python3-venv;;
            pacman) $INSTALL python-virtualenv;;
            dnf) $INSTALL python3-virtualenv;;
            zypper) $INSTALL python3-virtualenv;;
        esac
    else
        echo "❌ Cannot continue without venv."; exit 1
    fi
fi

# ========== GPU Detection ==========
GPU_VENDOR=""
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_VENDOR="nvidia"
elif command -v lspci >/dev/null 2>&1; then
    if lspci | grep -i 'nvidia' >/dev/null 2>&1; then
        GPU_VENDOR="nvidia"
    elif lspci | grep -i 'amd' >/dev/null 2>&1; then
        GPU_VENDOR="amd"
    fi
fi

echo -e "\n🖥️ Detected GPU: ${GPU_VENDOR:-none}"
if [[ "$GPU_VENDOR" == "nvidia" ]]; then
    echo "✅ NVIDIA GPU detected. You can use ONNX GPU acceleration (faster)."
    echo "⚠️ Requires CUDA Toolkit and NVIDIA drivers."
    read -p "👉 Use GPU (fast)? [y/N]: " USE_GPU
    MODE=$([[ "$USE_GPU" =~ ^[Yy]$ ]] && echo "1" || echo "2")
elif [[ "$GPU_VENDOR" == "amd" ]]; then
    echo "⚠️ AMD GPU detected — not supported by ONNX Runtime on Linux. Using CPU."
    MODE="2"
else
    echo "ℹ️ No supported GPU found. Using CPU mode."
    MODE="2"
fi

# ========== Virtual Environment Setup ==========
if [ ! -d "$VENV_PATH" ]; then
    echo "📦 Creating virtual environment at $VENV_PATH..."
    $PY -m venv "$VENV_PATH"
else
    echo "🔁 Reusing existing virtual environment at $VENV_PATH"
fi

source "$VENV_PATH/bin/activate"
echo "🔄 Upgrading pip..."
pip install --upgrade pip -q

# ========== Install Required Packages (quiet with progress) ==========
REQUIRED_PKGS=(opencv-python-headless tqdm insightface)
[[ "$MODE" == "1" ]] && REQUIRED_PKGS+=(onnxruntime-gpu) || REQUIRED_PKGS+=(onnxruntime)

echo -e "\n📦 Installing required packages (${#REQUIRED_PKGS[@]} total):"
i=1
for pkg in "${REQUIRED_PKGS[@]}"; do
    if python -c "import $pkg" >/dev/null 2>&1; then
        echo "[$i/${#REQUIRED_PKGS[@]}] ✅ $pkg already installed"
    else
        echo -n "[$i/${#REQUIRED_PKGS[@]}] 🛠️ Installing $pkg... "
        if pip install "$pkg" -q; then
            echo "✅ done"
        else
            echo "❌ failed"
            echo "⚠️ Error installing $pkg — please check your internet or package availability"
            exit 1
        fi
    fi
    ((i++))
done

# ========== Run Face Detection (suppress ONNX logs) ==========
echo -e "\n🚀 Running face detection..."
python - <<EOF | grep -vE '^Applied providers|^find model|^set det-size'
import os, cv2, shutil
from tqdm import tqdm
from insightface.app import FaceAnalysis

def init_app(mode):
    provs = ['CUDAExecutionProvider', 'CPUExecutionProvider'] if mode == '1' else ['CPUExecutionProvider']
    for p in provs:
        try:
            app = FaceAnalysis(providers=[p])
            app.prepare(ctx_id=0, det_size=(640,640))
            print(f"✅ Using {p}")
            return app
        except Exception as e:
            print(f"⚠️ Failed with {p}: {e}")
    raise SystemExit("❌ Could not initialize any provider.")

app = init_app("$MODE")
os.makedirs('noface', exist_ok=True)
imgs = [f for f in os.listdir() if f.lower().endswith(('.jpg','.jpeg','.png'))]
if not imgs:
    print("⚠️ No image files found.")
else:
    for f in tqdm(imgs, desc="🔍 Scanning"):
        try:
            img = cv2.imread(f)
            if img is None: raise ValueError("Unreadable")
            if not app.get(img):
                shutil.move(f, os.path.join('noface', f))
        except Exception as e:
            print(f"⚠️ Error on {f}: {e}")
EOF

echo "✅ Done. Images without faces moved to ./noface"

# ========== Show venv Size ==========
if [ -d "$VENV_PATH" ]; then
    VENV_SIZE=$(du -sh "$VENV_PATH" 2>/dev/null | awk '{print $1}')
    echo -e "\n📦 Virtual environment size: $VENV_SIZE"
fi

# ========== Prompt to Delete ==========
echo -e "\n🧹 Do you want to delete the virtual environment at $VENV_PATH?"
echo "   ➤ This will free ~${VENV_SIZE:-some} space."
echo "   ➤ BUT you'll need to reinstall everything if you run this script again."
read -p "❓ Delete venv? [y/N]: " DELETE_VENV
if [[ "$DELETE_VENV" =~ ^[Yy]$ ]]; then
    deactivate
    rm -rf "$VENV_PATH"
    echo "🗑️ Virtual environment deleted."
else
    echo "📁 Keeping virtual environment at $VENV_PATH."
fi

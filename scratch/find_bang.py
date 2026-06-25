import os
import re

lib_dir = "c:/Users/Savi Aby/Desktop/New folder (2)/Aswenna Agricultural Marketplace/frontend/lib"

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    lines = f.readlines()
                for i, line in enumerate(lines, 1):
                    match = re.search(r'\w+!', line)
                    match2 = re.search(r'[\])]!', line)
                    if (match or match2) and "!=" not in line and not line.strip().startswith("//"):
                        # print relative path
                        rel_path = os.path.relpath(filepath, lib_dir)
                        print(f"{rel_path}:{i}: {line.strip()}")
            except Exception as e:
                pass

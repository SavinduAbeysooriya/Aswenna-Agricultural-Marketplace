import os

lib_dir = "c:/Users/Savi Aby/Desktop/New folder (2)/Aswenna Agricultural Marketplace/frontend/lib"

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                
                if "Colors.grey[300]!" in content:
                    print(f"Fixing Colors.grey[300]! in {filepath}")
                    new_content = content.replace("Colors.grey[300]!", "Colors.grey[300] ?? Colors.grey")
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(new_content)
                
                if "Colors.grey[200]!" in content:
                    print(f"Fixing Colors.grey[200]! in {filepath}")
                    new_content = content.replace("Colors.grey[200]!", "Colors.grey[200] ?? Colors.grey")
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(new_content)

                if "Colors.grey[500]!" in content:
                    print(f"Fixing Colors.grey[500]! in {filepath}")
                    new_content = content.replace("Colors.grey[500]!", "Colors.grey[500] ?? Colors.grey")
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(new_content)
            except Exception as e:
                print(f"Error on {file}: {e}")

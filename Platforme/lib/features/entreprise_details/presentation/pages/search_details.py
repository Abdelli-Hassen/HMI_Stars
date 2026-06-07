import re

with open(r"c:\Users\yassine\Desktop\Flutter\hmi_stars\Platforme\lib\features\entreprise_details\presentation\pages\entreprise_details_page.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "salarie" in line.lower() or "employe" in line.lower() or "tab" in line.lower():
        if any(keyword in line for keyword in ["widget", "class", "void", "List", "final", "return", "tab", "Tab"]):
            print(f"{i+1}: {line.strip()}")

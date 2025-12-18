import os

# Configuration
UNITS_DIR = r"d:\Luchadores-Blitz-Reloaded-main\resources\units"

# Mapping Strings to Logic Integers (Enums)
# Faction: INDEPENDENT=0, OGS=1, TECHNICOS=2, LUCHADORES_UNIDOS=3, LOS_RUDOS=4, LOS_BANDITOS=5
FACTION_MAP = {
    'faction = "Independent"': 'faction = 0',
    'faction = "OG\'s"': 'faction = 1',
    'faction = "Technicos"': 'faction = 2',
    'faction = "Luchadores Unidos"': 'faction = 3',
    'faction = "Los Rudos"': 'faction = 4',
    'faction = "Rudos"': 'faction = 4', # Handle alias
    'faction = "Los Banditos"': 'faction = 5'
}

# UnitClass: LUCHADOR=0, STRIKER=1, TECHNICIAN=2, HIGH_FLYER=3, POWER_HOUSE=4, BRAWLER=5, FAN=6
CLASS_MAP = {
    'unit_class = "Luchador"': 'unit_class = 0',
    'unit_class = "Striker"': 'unit_class = 1',
    'unit_class = "Technician"': 'unit_class = 2',
    'unit_class = "High Flyer"': 'unit_class = 3',
    'unit_class = "Power House"': 'unit_class = 4',
    'unit_class = "Brawler"': 'unit_class = 5',
    'unit_class = "Fan"': 'unit_class = 6'
}

def migrate_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        new_lines = []
        changed = False
        
        for line in lines:
            original_line = line
            stripped = line.strip()
            
            # Check Faction
            for key, val in FACTION_MAP.items():
                if stripped == key:
                    line = line.replace(key, val)
                    changed = True
                    break
            
            # Check Class
            for key, val in CLASS_MAP.items():
                if stripped == key:
                    line = line.replace(key, val)
                    changed = True
                    break
                    
            new_lines.append(line)
            
        if changed:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            print(f"[UPDATED] {os.path.basename(filepath)}")
        else:
            print(f"[SKIPPED] {os.path.basename(filepath)} - No changes needed")
            
    except Exception as e:
        print(f"[ERROR] Failed to process {filepath}: {e}")

def main():
    if not os.path.exists(UNITS_DIR):
        print(f"Error: Directory not found: {UNITS_DIR}")
        return

    print("--- Starting Migration ---")
    files = [f for f in os.listdir(UNITS_DIR) if f.endswith('.tres')]
    
    for filename in files:
        full_path = os.path.join(UNITS_DIR, filename)
        migrate_file(full_path)
        
    print("--- Migration Complete ---")

if __name__ == "__main__":
    main()

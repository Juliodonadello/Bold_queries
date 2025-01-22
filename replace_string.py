import os

# Variables
folder_path = 'c:/Users/julio/OneDrive/Documents/Sage/repos/Bold_queries/Others_Reports/GreenHawk'
search_string = ['"public"."leases_units_units"', '"public"."lease_units"."unitsId"', '"public"."lease_units"."leasesId"']
replace_string = ['"public"."lease_units"', '"public"."lease_units"."unit_id"', '"public"."lease_units"."lease_id"']

for root, dirs, files in os.walk(folder_path):
    for file in files:
        if file.endswith(".sql"):
            file_path = os.path.join(root, file)
            print(f"Processing file: {file_path}")

            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()

                for i in range(len(search_string)):
                    content = content.replace(search_string[i], replace_string[i])

                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"Replacement completed in {file_path}")

            except Exception as e:
                print(f"Error processing {file_path}: {e}")

print("Replacement completed in all .sql files.")
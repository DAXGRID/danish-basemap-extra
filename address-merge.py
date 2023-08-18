import sys

# Required to handle decimal numbers.
import simplejson as json

# We need ijson to be able stream the big JSON files.
import ijson

def load_geojson(filePath):
    geojson_file_content = None
    with open(filePath, 'r') as file:
        geojson_file_content = file.read()

    return json.loads(geojson_file_content)

def create_navngivenvej_lookup(navngivenvej_kommunedele):
    navngivenvej_lookup = {}
    for navngivenvej_kommunedel in navngivenvej_kommunedele:
        properties = navngivenvej_kommunedel["properties"]
        unique_key = f"{properties['kommune']}-{properties['vejkode']}"
        navngivenvej_lookup[unique_key] = properties['navngivenvej_id']

    return navngivenvej_lookup

def create_vej_lookup(veje):
    vej_lookup = {}
    for vej in veje:
        properties = vej['properties']
        vej_lookup[properties['id']] = properties['navn']

    return vej_lookup;

def main():
    if len(sys.argv) != 2:
        print("Please specify a directory path to the files.")
        sys.exit(1)

    files_directory_path = sys.argv[1]

    vej_file_path = f"{files_directory_path}/vej.geojson"
    navngivenvej_file_path = f"{files_directory_path}/navngivenvejkommunedel.geojson"
    vejmidte_file_path = f"{files_directory_path}/vejmidte.geojson"
    out_path = f"{files_directory_path}/vejmidte_with_vejnavn.geojson"

    navngivenvej_lookup = create_navngivenvej_lookup(
        load_geojson(navngivenvej_file_path)["features"])

    vej_lookup = create_vej_lookup(
        load_geojson(vej_file_path)["features"])

    with open(vejmidte_file_path, "rb") as json_file:
        features = ijson.items(json_file, "features.item")

        with open(out_path, 'a', encoding='utf8') as json_out_file:
            for feature in features:
                feature_properties = feature['properties']
                vejkode = feature_properties['vejkode']
                kommunekode = feature_properties['kommunekode']

                if vejkode is not None and kommunekode is not None:
                    try:
                        vejnavn = vej_lookup[navngivenvej_lookup[f"{kommunekode}-{vejkode}"]]
                        feature_properties['vejnavn'] = vejnavn
                        json_string = json.dumps(feature, ensure_ascii=False)
                        json_out_file.write(json_string + "\n")
                    except KeyError:
                        print(f"Could not lookup {kommunekode}-{vejkode}")

main()

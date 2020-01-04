COUNTRY="IN"
STATE="Tamilnadu"
LOCATION="Coimbatore"
ORGANIZATION="Devil7 Softwares"
ORGANIZATION_UNIT="Android Development"
COMMON_NAME="Devil7DK"
EMAIL="devil7dk@devil7softwares.in"

KEY_TYPES=(releasekey media platform shared testkey verity)
TEMP_KEY="$PWD/temp.pem"
RED='\033[0;31m'
NC='\033[0m'

set -e

if [[ -f "$TEMP_KEY" ]]; then
	echo -e "${RED}Temp key found. Deleting...${NC}"
	shred --remove "$TEMP_KEY"
fi

RAND_FILE="$HOME/.rnd"
if [[ ! -f "$RAND_FILE" ]]; then
	echo -e "${RED}Random values file doesn't exist... Creating one...${NC}"
	openssl rand -writerand "$RAND_FILE"
fi

for KEY_TYPE in "${KEY_TYPES[@]}"; do
	KEY_BASE_PATH="$PWD/$KEY_TYPE"
	KEY_PEM_PATH="$KEY_BASE_PATH.x509.pem"
	KEY_PK8_PATH="$KEY_BASE_PATH.pk8"

	echo -e "${RED}Generating $KEY_TYPE...${NC}"
	openssl genrsa -3 -out "$TEMP_KEY" 2048 &> /dev/null
	openssl req -new -x509 -key "$TEMP_KEY" -out "$KEY_PEM_PATH" -days 10950 -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL"
	openssl pkcs8 -in "$TEMP_KEY" -topk8 -outform DER -out "$KEY_PK8_PATH" -nocrypt
	shred --remove "$TEMP_KEY"
done

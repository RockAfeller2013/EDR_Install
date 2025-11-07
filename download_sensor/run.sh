# To run the script directly from GitHub without caching, use this single line:


curl -sSL "https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/download_sensor/all.sh?$(date +%s)" | bash -s -- 192.168.1.30 YOUR_API_TOKEN 1

# Using a random number:

curl -sSL "https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/download_sensor/all.sh?nocache=$RANDOM" | bash -s -- 192.168.1.30 YOUR_API_TOKEN 1

# Using cache-control header:

curl -sSL -H "Cache-Control: no-cache" "https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/download_sensor/all.sh" | bash -s -- 192.168.1.30 YOUR_API_TOKEN 1

# Force refresh with -H pragma:

curl -sSL -H "Pragma: no-cache" -H "Cache-Control: no-cache, no-store, must-revalidate" "https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/download_sensor/all.sh" | bash -s -- 192.168.1.30 YOUR_API_TOKEN 1

# Recommended (simplest and most reliable):

curl -sSL "https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/download_sensor/all.sh?t=$(date +%s)" | bash -s -- 192.168.1.30 YOUR_API_TOKEN 1

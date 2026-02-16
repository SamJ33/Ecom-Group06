# Install dependencies if needed:
# pip install kaggle pandas

from kaggle.api.kaggle_api_extended import KaggleApi
import os
import pandas as pd

# -----------------------------
# Step 1: Authenticate Kaggle API
# -----------------------------
api = KaggleApi()
api.authenticate()  # Reads C:\Users\jwsam\.kaggle\kaggle.json

# -----------------------------
# Step 2: Define dataset and local folder
# -----------------------------
dataset_name = "olistbr/brazilian-ecommerce"
download_dir = "C:/Users/jwsam/Desktop/Ecom/kaggle_datasets"
os.makedirs(download_dir, exist_ok=True)

# -----------------------------
# Step 3: Download all files and unzip automatically
# -----------------------------
print("Downloading and unzipping all files...")
api.dataset_download_files(
    dataset_name,
    path=download_dir,
    unzip=True,
    force=True  # overwrite if already exists
)
print("All files downloaded and unzipped!")

# -----------------------------
# Step 4: Load all CSV files into Pandas
# -----------------------------
datasets = {}
for f in os.listdir(download_dir):
    if f.endswith(".csv"):
        file_path = os.path.join(download_dir, f)
        try:
            datasets[f] = pd.read_csv(
                file_path,
                encoding="latin-1",   # handle accents
                on_bad_lines='skip'   # skip malformed rows
            )
            print(f"Loaded {f} ({len(datasets[f])} rows)")
        except Exception as e:
            print(f"Failed to load {f}: {e}")

# -----------------------------
# Step 5: Example usage
# -----------------------------
df_customers = datasets.get("olist_customers_dataset.csv")
if df_customers is not None:
    print("\nFirst 5 rows of customers dataset:")
    print(df_customers.head())

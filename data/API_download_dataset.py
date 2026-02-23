import os
from kaggle.api.kaggle_api_extended import KaggleApi


def download_dataset():
    api = KaggleApi()
    api.authenticate()

    dataset = "olistbr/brazilian-ecommerce"
    raw_path = "data/raw"

    os.makedirs(raw_path, exist_ok=True)

    print("Downloading dataset...")
    api.dataset_download_files(dataset, path=raw_path, unzip=True)

    print("Download completed. Files extracted to data/raw/")


if __name__ == "__main__":
    download_dataset()

"""Başlangıç Python ETL kodu.

Bu dosya bilinçli olarak tamamlanmamıştır. Beklenen davranış ve teslim
kanıtları için aynı klasördeki README.md dosyasını inceleyin.
"""

import requests
import os
from pymongo import MongoClient

response = requests.get("https://api.github.com")
print(response)
print(response.json())

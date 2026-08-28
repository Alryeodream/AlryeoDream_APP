import os
import requests
import urllib.parse
import xml.etree.ElementTree as ET
from dotenv import load_dotenv

load_dotenv()
service_key_encoded = os.environ.get('DATA_API_KEY')
service_key_decoded = urllib.parse.unquote(service_key_encoded)
url = "https://apis.data.go.kr/B554287/NationalWelfareInformationsV001/NationalWelfarelistV001"

params = {
    'serviceKey': service_key_decoded,
    'callTp': 'L',
    'pageNo': '1',
    'numOfRows': '2',
    'srchKeyCode': '003',
}
res = requests.get(url, params=params)
print(res.text)

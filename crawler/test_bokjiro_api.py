import requests
import urllib.parse
from bs4 import BeautifulSoup
import xml.etree.ElementTree as ET

service_key = 'qdpFjYZh6fHr8fFQmb+dZ6/Zl+2dgQE89VcadfLpDouyBzRhmmwmsVTSw3ce1fc0ABHWzqFsBw4LNzUZFwM6OA=='
# requests module URL-encodes params, so we provide the DECODED key, OR we use string concatenation

decoded_key = urllib.parse.unquote('qdpFjYZh6fHr8fFQmb%2BdZ6%2FZl%2B2dgQE89VcadfLpDouyBzRhmmwmsVTSw3ce1fc0ABHWzqFsBw4LNzUZFwM6OA%3D%3D')

url = 'https://apis.data.go.kr/B554287/LocalGovernmentWelfareInformations/LocalGovernmentWelfarelist'
params = {
    'serviceKey': decoded_key,
    'callTp': 'L',
    'pageNo': '1',
    'numOfRows': '10',
     'srchKeyCode': '001',
}

try:
    res = requests.get(url, params=params, verify=False)
    print(f"Status Code: {res.status_code}")
    print(res.text[:1000])
except Exception as e:
    print(e)

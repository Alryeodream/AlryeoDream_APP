import requests
from bs4 import BeautifulSoup
import json

urls = {
    'inhatc': 'https://www.inhatc.ac.kr/kr/460/subview.do?enc=Zm5jdDF8QEB8JTJGY29tYkJicyUyRmtyJTJGMiUyRmxpc3QuZG8lM0Y%3D',
    'incheon': 'https://youth.incheon.go.kr/policy/search_incheon.jsp',
    'youthcenter': 'https://www.youthcenter.go.kr/go/ythip/getPlcy',
    'bokjiro': 'https://www.bokjiro.go.kr/ssis-tbu/twataa/wlfareInfo/moveTWAT52005M.do'
}

for name, url in urls.items():
    try:
        r = requests.get(url, timeout=5, verify=False)
        print(f"[{name}] Status: {r.status_code}, Length: {len(r.text)}")
    except Exception as e:
        print(f"[{name}] Error: {e}")

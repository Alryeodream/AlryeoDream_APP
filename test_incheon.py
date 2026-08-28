import requests
from bs4 import BeautifulSoup
url = "https://youth.incheon.go.kr/policy/search_incheon.jsp"
headers = {'User-Agent': 'Mozilla/5.0'}
res = requests.get(url, headers=headers)
print(res.text[:1000])

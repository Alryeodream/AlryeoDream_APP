import requests
from bs4 import BeautifulSoup
url = "https://www.youthcenter.go.kr/youthPlcy/searchYouthPlcy.do"
headers = {'User-Agent': 'Mozilla/5.0'}
res = requests.get(url, headers=headers)
soup = BeautifulSoup(res.text, 'html.parser')
for item in soup.select('.result-list li')[:5]:
    title_tag = item.select_one('.tit')
    if title_tag:
        print("Title:", title_tag.text.strip())

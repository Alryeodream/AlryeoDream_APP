import json
import os
import uuid
import datetime
import requests
import time
import re
import urllib.parse
import base64
from bs4 import BeautifulSoup

import hashlib
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import concurrent.futures
from dotenv import load_dotenv

# 로컬 환경인 경우 .env 파일에서 환경변수 로드
load_dotenv()

# --- 기본 설정 ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_OUTPUT_PATH = os.path.join(BASE_DIR, "assets", "data", "benefits_data.json")

# 수집할 키워드 필터링 (게시물 제목에 아래 단어가 포함된 것만 추출)
TARGET_KEYWORDS = ['장학', '지원', '근로', '대출', '취업', '모집', '혜택', '프로그램']

headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'
}

def map_category(title, original_category):
    text = f"{title} {original_category}".replace(" ", "")
    
    if any(k in text for k in ['대출', '금융', '적금', '저축', '이자', '펀드', '보증', '자산']):
        return "금융/대출"
    if any(k in text for k in ['주거', '월세', '전세', '임대', '주택', '이사', '보증금', '부동산']):
        return "주거/자립"
    if any(k in text for k in ['취업', '창업', '일자리', '근로', '인턴', '면접', '구직', '이력서']):
        return "취업/창업"
    if any(k in text for k in ['장학', '교육', '학자금', '멘토링', '등록금', '수업', '학습']):
        return "장학/교육"
    if any(k in text for k in ['복지', '건강', '의료', '저소득', '장애인', '출산', '심리', '마음', '상담', '의료비']):
        return "복지/건강"
    if any(k in text for k in ['문화', '예술', '공연', '참여', '네트워크', '커뮤니티', '활동', '동아리']):
        return "문화/예술"
    
    return "기타/공통"

def generate_benefit(title, provider, category_name, url, region_name='전국', end_date=None):
    """앱의 Benefit 모델에 맞는 JSON 객체를 생성합니다."""
    regions = [] if region_name == '전국' else [{"sido": {"name": region_name}}]
    
    clean_category = map_category(title, category_name)
    
    
    # 고유 ID 생성 (제목+제공처 기반 해시)
    unique_str = f"{title.strip()}_{provider}".encode('utf-8')
    benefit_id = f"scraped_{hashlib.md5(unique_str).hexdigest()[:12]}"
    
    benefit_dict = {
        "benefit_id": benefit_id,

        "title": title.strip(),
        "provider": provider,
        "category": { "name": clean_category },
        "benefit_regions": regions,
        "site_url": url,
        "min_age": 19,
        "max_age": 34,
        "target_gender": "ALL",
        "description": f"{provider}에서 제공하는 자동 수집된 {title} 혜택 정보입니다.",
        "end_date": end_date
    }
    return benefit_dict

def contains_keyword(title):
    return any(keyword in title for keyword in TARGET_KEYWORDS)

def scrape_inhatc_notice():
    """1. 인하공전 공지사항 크롤링 (키워드 필터링)"""
    results = []
    url = "https://www.inhatc.ac.kr/kr/460/subview.do?enc=Zm5jdDF8QEB8JTJGY29tYkJicyUyRmtyJTJGMiUyRmxpc3QuZG8lM0Y%3D"
    print(f"[{datetime.datetime.now()}] 인하공전 공지사항 크롤링 시작...")
    
    try:
        res = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(res.text, 'html.parser')
        
        # <tbody> 안의 <tr> 태그 탐색 (공지사항 목록)
        rows = soup.select('tbody tr')
        for row in rows:
            title_tag = row.select_one('td.td-subject a')
            if not title_tag:
                continue
            
            title = title_tag.text.strip()
            # "새글" 같은 아이콘 텍스트 제거
            title = title.replace('새글', '').strip()
            
            link = title_tag.get('href', '')
            if link.startswith('javascript:'):
                # 자바스크립트 함수로 되어있는 경우 (예: javascript:jf_combBbs_view('kr','2','18','109554');)
                match = re.search(r"jf_combBbs_view\('([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)'\)", link)
                if match:
                    site_id, bbs_id, cate_id, article_id = match.groups()
                    path = f"/combBbs/{site_id}/{bbs_id}/{cate_id}/{article_id}/view.do?findWord=&page=1&findType=&"
                    inner_str = "fnct1|@@|" + urllib.parse.quote(path, safe='')
                    enc_str = base64.b64encode(inner_str.encode('utf-8')).decode('utf-8')
                    link = f"https://www.inhatc.ac.kr/kr/460/subview.do?enc={urllib.parse.quote(enc_str)}"
                else:
                    link = url # 정규식 매칭 실패 시 메인 게시판 링크로 대체
            elif link.startswith('?'):
                link = "https://www.inhatc.ac.kr/kr/460/subview.do" + link
            elif link.startswith('/'):
                link = "https://www.inhatc.ac.kr" + link
                
            # 키워드 필터링 적용
            if contains_keyword(title):
                results.append(generate_benefit(
                    title=title.strip(),
                    provider="인하공전",
                    category_name="교육/장학",
                    url=link,
                    region_name="인천"
                ))
    except Exception as e:
        print(f"인하공전 크롤링 에러: {e}")
        
    return results

def scrape_incheon_youth():
    """2. 인천 청년 포털 정책 크롤링"""
    results = []
    url = "https://youth.incheon.go.kr/policy/search_incheon.jsp"
    print(f"[{datetime.datetime.now()}] 인천 청년 포털 크롤링 시작...")
    
    try:
        res = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(res.text, 'html.parser')
        
        # 게시물 제목을 포함하는 a 태그나 리스트 탐색 (예상되는 일반적인 구조)
        items = soup.select('.list_policy li, table tbody tr')
        for item in items:
            title_tag = item.select_one('a')
            if not title_tag:
                continue
            
            title = title_tag.text.strip()
            link = title_tag.get('href', '')
            if link and not link.startswith('http'):
                link = "https://youth.incheon.go.kr" + link
            
            if title and contains_keyword(title):
                results.append(generate_benefit(
                    title=title.strip(),
                    provider="인천시",
                    category_name="주거/복지",
                    url=link,
                    region_name="인천"
                ))
    except Exception as e:
        print(f"인천 청년포털 크롤링 에러: {e}")
        
    return results

def scrape_youth_center():
    """3. 온통청년(YouthCenter) API/웹 파싱"""
    results = []
    # 온통청년 API는 보통 xml이나 json 요청이 필요하지만, 여기서는 URL을 그대로 호출해봅니다.
    url = "https://www.youthcenter.go.kr/go/ythip/getPlcy"
    print(f"[{datetime.datetime.now()}] 온통청년 크롤링 시작...")
    
    try:
        # getPlcy는 잘못된 파라미터 시 400 에러를 반환하므로, 일단 예외 처리하고 빈 배열을 반환하도록 처리
        res = requests.get(url, headers=headers, timeout=10)
        if res.status_code == 200:
            soup = BeautifulSoup(res.text, 'html.parser')
            for a_tag in soup.find_all('a'):
                title = a_tag.text.strip()
                if contains_keyword(title):
                    results.append(generate_benefit(
                        title=title.strip(),
                        provider="온통청년",
                        category_name="취업/금융",
                        url=url,
                        region_name="전국"
                    ))
        else:
            print(f"온통청년 접속 실패: {res.status_code} (파라미터/API키 필요 예상)")
    except Exception as e:
        print(f"온통청년 크롤링 에러: {e}")
        
    return results

def scrape_bokjiro():
    """4. 복지로 OpenAPI 연동"""
    results = []
    print(f"[{datetime.datetime.now()}] 복지로 OpenAPI 크롤링 시작...")
    
    # 환경변수에서 API 키 로드 (보안 취약점 조치)
    service_key_encoded = os.environ.get('DATA_API_KEY')
    if not service_key_encoded:
        print("경고: DATA_API_KEY 환경변수가 설정되지 않아 복지로 데이터를 가져올 수 없습니다.")
        return []
    import urllib.parse
    import defusedxml.ElementTree as ET
    
    service_key_decoded = urllib.parse.unquote(service_key_encoded)
    url = "https://apis.data.go.kr/B554287/NationalWelfareInformationsV001/NationalWelfarelistV001"
    
    params = {
        'serviceKey': service_key_decoded,
        'callTp': 'L',
        'pageNo': '1',
        'numOfRows': '500', # 최대 500개까지 가져와서 필터링
        'srchKeyCode': '003', # 필수 파라미터 추가
    }
    
    try:
        res = requests.get(url, params=params, timeout=10)
        
        # XML 파싱
        root = ET.fromstring(res.text)
        for servList in root.findall('.//servList'):
            title = servList.findtext('servNm')
            link = servList.findtext('servDtlLink')
            category = servList.findtext('intrsThemaArray') or '복지'
            life_array = servList.findtext('lifeArray') or ''
            
            # 혜택 제목에 키워드가 있거나, 대상자(lifeArray)에 '청년'이 포함된 경우 추출
            if title and (contains_keyword(title) or '청년' in life_array):
                # 카테고리 첫 번째 값만 추출 (예: '생활지원,일자리,서민금융' -> '생활지원')
                cat_name = category.split(',')[0]
                
                results.append(generate_benefit(
                    title=title.strip(),
                    provider="복지로(국가복지)",
                    category_name=f"복지/{cat_name}",
                    url=link,
                    region_name="전국"
                ))
    except Exception as e:
        print(f"복지로 OpenAPI 크롤링 에러: {e}")
        
    return results

def scrape_kosaf():
    """5. 한국장학재단 OpenAPI 연동"""
    results = []
    print(f"[{datetime.datetime.now()}] 한국장학재단 OpenAPI 크롤링 시작 (모든 하위 API 탐색)...")
    
    import urllib.parse
    service_key_encoded = os.environ.get('DATA_API_KEY')
    if not service_key_encoded:
        print("경고: DATA_API_KEY 환경변수가 설정되지 않아 한국장학재단 데이터를 가져올 수 없습니다.")
        return []
    service_key_decoded = urllib.parse.unquote(service_key_encoded)
    
    try:
        # 1. Swagger 정의서에서 모든 UUID 추출
        swagger_url = "https://infuser.odcloud.kr/oas/docs?namespace=15028252/v1"
        res_swagger = requests.get(swagger_url, timeout=10)
        swagger_data = res_swagger.json()
        
        # '_api'로 끝나는 key들에서 UUID 추출
        uuids = [k.replace('_api', '') for k in swagger_data.get('definitions', {}).keys() if k.endswith('_api')]
        print(f"발견된 한국장학재단 데이터셋(UUID) 개수: {len(uuids)}개")
        
        today_str = datetime.datetime.now().strftime('%Y-%m-%d')
        
        def fetch_kosaf_uuid(uuid_str):
            sub_results = []
            url = f"https://api.odcloud.kr/api/15028252/v1/{uuid_str}"
            params = {
                'page': 1,
                'perPage': 1000,
                'serviceKey': service_key_decoded
            }
            try:
                res = requests.get(url, params=params, timeout=10)
                data = res.json()
                if 'data' in data:
                    for item in data['data']:
                        title = item.get('상품명', '')
                        provider = item.get('운영기관명', '한국장학재단')
                        category = item.get('상품구분', '장학금')
                        link = item.get('홈페이지 주소', 'https://www.kosaf.go.kr')
                        start_date = item.get('모집시작일', '')
                        end_date = item.get('모집종료일', '')
                        
                        is_valid = True
                        if end_date and end_date != '해당없음':
                            if len(end_date) == 10 and end_date.count('-') == 2:
                                if end_date < today_str:
                                    is_valid = False
                            else:
                                is_valid = False
                        
                        if start_date and start_date != '해당없음':
                            if len(start_date) == 10 and start_date.count('-') == 2:
                                if start_date > today_str:
                                    is_valid = False
                        
                        if not is_valid:
                            continue
                                
                        if title:
                            sub_results.append(generate_benefit(
                                title=title.strip(),
                                provider=provider,
                                category_name=f"장학/{category}",
                                url=link,
                                region_name="전국",
                                end_date=end_date if len(end_date) == 10 else None
                            ))
            except Exception:
                pass
            return sub_results

        # 2. 모든 UUID에 대해 병렬 데이터 요청
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(fetch_kosaf_uuid, uuid_str) for uuid_str in uuids]
            for future in concurrent.futures.as_completed(futures):
                results.extend(future.result())
                
    except Exception as e:
        print(f"한국장학재단 OpenAPI 크롤링 에러: {e}")
        
    return results

def main():
    print(f"========== 멀티 크롤러 봇 실행 ==========")
    all_benefits = []
    
    # 병렬로 모든 소스 크롤링
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        f1 = executor.submit(scrape_inhatc_notice)
        f2 = executor.submit(scrape_incheon_youth)
        f3 = executor.submit(scrape_youth_center)
        f4 = executor.submit(scrape_bokjiro)
        f5 = executor.submit(scrape_kosaf)
        
        for future in concurrent.futures.as_completed([f1, f2, f3, f4, f5]):
            all_benefits.extend(future.result())
    
    # 중복 제거 (정규화된 제목 기준)
    import re
    unique_benefits_dict = {}
    for benefit in all_benefits:
        # [출처] 제거 및 공백, 특수기호 최소화하여 비교용 키 생성
        raw_title = re.sub(r'^\[.*?\]\s*', '', benefit['title'])
        normalized_key = re.sub(r'\s+', '', raw_title)
        
        # 만약 동일한 장학금이 이미 존재한다면, 나중에 들어온 것(또는 선호도에 따라) 덮어쓰거나 무시
        # (여기서는 먼저 발견된 항목을 우선으로 유지)
        if normalized_key not in unique_benefits_dict:
            unique_benefits_dict[normalized_key] = benefit
            
    final_list = list(unique_benefits_dict.values())
    
    print(f"========== 크롤링 종료 ==========")
    print(f"중복 제거 전: {len(all_benefits)}건 -> 중복 제거 후: {len(final_list)}건")
    
    
    # JSON으로 저장 (백업/로컬테스트용)
    os.makedirs(os.path.dirname(DATA_OUTPUT_PATH), exist_ok=True)
    with open(DATA_OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(final_list, f, ensure_ascii=False, indent=2)
    print(f"데이터 로컬 저장 완료: {DATA_OUTPUT_PATH}")
    
    # Firestore에 저장
    cred_path = os.path.join(BASE_DIR, 'crawler', 'firebase_credentials.json')
    if os.path.exists(cred_path):
        try:
            print("Firestore 업로드 시작...")
            cred = credentials.Certificate(cred_path)
            if not firebase_admin._apps:
                firebase_admin.initialize_app(cred)
            db = firestore.client()
            
            # Batch write for efficiency (Firestore limits 500 ops per batch)
            batch = db.batch()
            count = 0
            uploaded = 0
            
            for benefit in final_list:
                doc_ref = db.collection('benefits').document(benefit['benefit_id'])
                batch.set(doc_ref, benefit, merge=True)
                count += 1
                uploaded += 1
                
                if count >= 450:
                    batch.commit()
                    print(f"{uploaded}건 업로드 완료...")
                    batch = db.batch()
                    count = 0
            
            if count > 0:
                batch.commit()
                print(f"총 {uploaded}건 Firestore 업로드 완료!")
                
        except Exception as e:
            print(f"Firestore 업로드 실패: {e}")
    else:
        print(f"Firestore 업로드 건너뜀 (크리덴셜 파일 없음: {cred_path})")


if __name__ == "__main__":
    main()

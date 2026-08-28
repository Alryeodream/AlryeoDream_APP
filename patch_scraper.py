import re

with open('crawler/scraper.py', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update imports
import_section = """
import hashlib
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
"""
content = content.replace("from bs4 import BeautifulSoup", "from bs4 import BeautifulSoup\n" + import_section)

# 2. Update generate_benefit to use deterministic ID based on title+provider
deterministic_id_logic = """
    # 고유 ID 생성 (제목+제공처 기반 해시)
    unique_str = f"{title.strip()}_{provider}".encode('utf-8')
    benefit_id = f"scraped_{hashlib.md5(unique_str).hexdigest()[:12]}"
    
    benefit_dict = {
        "benefit_id": benefit_id,
"""
content = re.sub(r'benefit_dict = {\s*"benefit_id": f"scraped_\{uuid.uuid4\(\)\.hex\[:8\]\}",', deterministic_id_logic, content)

# 3. Add save_to_firestore logic at the end of main()
save_logic = """
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
"""
content = re.sub(r'# JSON으로 저장\s*os\.makedirs.*?print\(f"데이터 저장 완료: \{DATA_OUTPUT_PATH\}"\)', save_logic, content, flags=re.DOTALL)

with open('crawler/scraper.py', 'w', encoding='utf-8') as f:
    f.write(content)

#!/usr/bin/env python3
"""Upload localized description/keywords/whatsNew for new locales."""

import json, time, os
import jwt, httpx

KEY_ID = "83RP2C955C"
ISSUER_ID = "00f77d2c-067d-40f9-a27a-42325d6b760f"
KEY_PATH = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_83RP2C955C.p8")
VERSION_ID = "7cd34420-8192-45b6-9de1-88898151a252"

def get_token():
    with open(KEY_PATH) as f:
        key = f.read()
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, key, algorithm="ES256", headers={"kid": KEY_ID})

def api(method, path, token, json_data=None):
    url = f"https://api.appstoreconnect.apple.com/v1/{path}"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    r = httpx.request(method, url, headers=headers, json=json_data, timeout=60)
    if r.status_code >= 400:
        print(f"  ERROR {r.status_code}: {r.text[:300]}")
    return r

# Translations for new locales
LOCALES = {
    "pt-BR": {
        "description": """NectarView é um visualizador rápido e leve de quadrinhos e imagens para macOS — agora com suporte direto a RAR, 7z, ZIP, TAR e mais de 30 formatos de arquivo, sem necessidade de extração. Inspirado na usabilidade do HoneyView para Windows, ele utiliza recursos nativos do macOS para oferecer uma experiência de leitura fluida.

Controles Intuitivos
\t•\tAbra arquivos facilmente com arrastar e soltar
\t•\tAbra arquivos pelo menu de contexto
\t•\tAlterne tela cheia com duplo clique
\t•\tArraste a área de visualização para mover a janela

Suporte Multi-Arquivo
\t•\tAbra RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt e mais
\t•\tSuporte a arquivos protegidos por senha
\t•\tDetecção automática de formato

Opções Flexíveis de Visualização
\t•\tAlterne entre página única e página dupla
\t•\tSuporte para leitura da esquerda para direita e vice-versa
\t•\tNavegue rapidamente com o controle deslizante
\t•\tAparência realista de livro na vista dupla

Alto Desempenho
\t•\tAbra arquivos diretamente sem extração
\t•\tExibição rápida com pré-carregamento
\t•\tProcessamento eficiente com APIs nativas do macOS

Interface Amigável
\t•\tUI simples e sem distrações
\t•\tCores personalizáveis de fundo e barra de controle
\t•\tJanela de configurações nativa do macOS
\t•\tOperações por atalhos de teclado

Recursos Avançados
\t•\tFunção de favoritos para salvar locais
\t•\tExibição em lote de imagens em uma pasta
\t•\tSuporte a PDF com renderização Retina
\t•\tVirada automática de página com intervalos ajustáveis
\t•\tRotação de imagem e efeitos de filtro""",
        "keywords": "rar,7z,cbr,cbz,arquivo,mangá,quadrinhos,leitor,visualizador,filtro,favorito",
        "whatsNew": """Novidades na versão 1.1.0:

• Suporte Multi-Arquivo: Abra RAR, 7z, TAR, LhA, CAB, StuffIt e mais de 30 formatos
• Arquivos Protegidos por Senha: Digite senhas para arquivos criptografados
• Configurações Nativas: Design redesenhado com visual nativo do macOS
• PDF Retina: Renderização nítida em telas de alta resolução
• Navegação Mais Rápida: Pré-carregamento de imagens
• Maior Estabilidade: Dependências removidas e APIs corrigidas"""
    },
    "th": {
        "description": """NectarView เป็นโปรแกรมดูมังงะและรูปภาพที่รวดเร็วสำหรับ macOS — รองรับ RAR, 7z, ZIP, TAR และไฟล์บีบอัดกว่า 30 รูปแบบโดยตรง ไม่ต้องแตกไฟล์

การควบคุมที่ง่ายดาย
\t•\tลากและวางไฟล์เพื่อเปิด
\t•\tเปิดจากเมนูคลิกขวา
\t•\tดับเบิลคลิกเพื่อเต็มจอ

รองรับหลายรูปแบบ
\t•\tเปิด RAR, 7z, ZIP, TAR, LhA, CAB และอื่นๆ
\t•\tรองรับไฟล์ที่มีรหัสผ่าน

ตัวเลือกการแสดงผลที่ยืดหยุ่น
\t•\tสลับระหว่างหน้าเดียวและสองหน้า
\t•\tรองรับการอ่านซ้ายไปขวาและขวาไปซ้าย
\t•\tเลื่อนภาพอย่างรวดเร็วด้วยสไลเดอร์

ประสิทธิภาพสูง
\t•\tเปิดไฟล์บีบอัดโดยตรง
\t•\tแสดงผลเร็วด้วยการโหลดล่วงหน้า

คุณสมบัติขั้นสูง
\t•\tบุ๊กมาร์กหน้าโปรด
\t•\tรองรับ PDF
\t•\tพลิกหน้าอัตโนมัติ
\t•\tฟิลเตอร์ภาพ 12 แบบ""",
        "keywords": "rar,7z,มังงะ,การ์ตูน,รูปภาพ,ดู,อ่าน,บีบอัด,zip,pdf",
        "whatsNew": """เวอร์ชัน 1.1.0:

• รองรับหลายรูปแบบ: RAR, 7z, TAR และกว่า 30 รูปแบบ
• ไฟล์ที่มีรหัสผ่าน
• การตั้งค่าแบบ macOS
• PDF คมชัดบน Retina
• เลื่อนภาพเร็วขึ้น"""
    },
    "vi": {
        "description": """NectarView là trình xem manga và ảnh nhanh cho macOS — hỗ trợ trực tiếp RAR, 7z, ZIP, TAR và hơn 30 định dạng nén mà không cần giải nén.

Điều khiển trực quan
\t•\tKéo thả tệp để mở
\t•\tMở từ menu chuột phải
\t•\tNhấp đúp để toàn màn hình

Hỗ trợ nhiều định dạng
\t•\tMở RAR, 7z, ZIP, TAR, LhA, CAB và nhiều hơn
\t•\tHỗ trợ tệp nén có mật khẩu

Tùy chọn hiển thị linh hoạt
\t•\tChuyển đổi giữa trang đơn và trang đôi
\t•\tHỗ trợ đọc trái-phải và phải-trái

Hiệu suất cao
\t•\tMở trực tiếp không cần giải nén
\t•\tHiển thị nhanh với tải trước

Tính năng nâng cao
\t•\tĐánh dấu trang yêu thích
\t•\tHỗ trợ PDF
\t•\tLật trang tự động
\t•\t12 bộ lọc ảnh""",
        "keywords": "rar,7z,manga,truyện tranh,xem ảnh,đọc,nén,zip,pdf,lọc",
        "whatsNew": """Phiên bản 1.1.0:

• Hỗ trợ đa định dạng: RAR, 7z, TAR và hơn 30 định dạng
• Tệp nén có mật khẩu
• Cài đặt macOS gốc
• PDF Retina
• Duyệt nhanh hơn"""
    },
    "id": {
        "description": """NectarView adalah penampil manga dan gambar yang cepat untuk macOS — mendukung RAR, 7z, ZIP, TAR dan 30+ format arsip secara langsung tanpa perlu ekstraksi.

Kontrol Intuitif
\t•\tSeret dan lepas file untuk membuka
\t•\tBuka dari menu klik kanan
\t•\tKlik ganda untuk layar penuh

Dukungan Multi-Arsip
\t•\tBuka RAR, 7z, ZIP, TAR, LhA, CAB dan lainnya
\t•\tDukungan arsip dilindungi kata sandi

Opsi Tampilan Fleksibel
\t•\tBeralih antara halaman tunggal dan ganda
\t•\tDukungan baca kiri-kanan dan kanan-kiri

Kinerja Tinggi
\t•\tBuka arsip langsung tanpa ekstraksi
\t•\tTampilan cepat dengan prefetching

Fitur Lanjutan
\t•\tBookmark halaman favorit
\t•\tDukungan PDF
\t•\tHalaman otomatis
\t•\t12 filter gambar""",
        "keywords": "rar,7z,manga,komik,gambar,penampil,pembaca,arsip,zip,pdf",
        "whatsNew": """Versi 1.1.0:

• Dukungan Multi-Arsip: RAR, 7z, TAR dan 30+ format
• Arsip dilindungi kata sandi
• Pengaturan macOS native
• PDF Retina
• Browsing lebih cepat"""
    },
    "it": {
        "description": """NectarView è un visualizzatore di fumetti e immagini veloce per macOS — supporta direttamente RAR, 7z, ZIP, TAR e oltre 30 formati di archivio senza estrazione.

Controlli Intuitivi
\t•\tTrascina e rilascia per aprire i file
\t•\tApri dal menu contestuale
\t•\tDoppio clic per schermo intero

Supporto Multi-Archivio
\t•\tApri RAR, 7z, ZIP, TAR, LhA, CAB e altri
\t•\tSupporto archivi protetti da password

Opzioni di Visualizzazione Flessibili
\t•\tAlterna tra pagina singola e doppia
\t•\tSupporto lettura sinistra-destra e destra-sinistra

Alte Prestazioni
\t•\tApri archivi direttamente
\t•\tVisualizzazione rapida con precaricamento

Funzionalità Avanzate
\t•\tSegnalibri per le pagine preferite
\t•\tSupporto PDF
\t•\tGiro pagina automatico
\t•\t12 filtri immagine in tempo reale""",
        "keywords": "rar,7z,fumetti,manga,immagini,visualizzatore,lettore,archivio,zip,pdf",
        "whatsNew": """Novità nella versione 1.1.0:

• Supporto Multi-Archivio: RAR, 7z, TAR e oltre 30 formati
• Archivi protetti da password
• Impostazioni native macOS
• PDF Retina
• Navigazione più veloce"""
    },
    "pl": {
        "description": """NectarView to szybka przeglądarka komiksów i obrazów dla macOS — obsługuje RAR, 7z, ZIP, TAR i ponad 30 formatów archiwów bez rozpakowywania.

Intuicyjne Sterowanie
\t•\tPrzeciągnij i upuść pliki
\t•\tOtwórz z menu kontekstowego
\t•\tPodwójne kliknięcie dla pełnego ekranu

Wsparcie Wielu Archiwów
\t•\tOtwórz RAR, 7z, ZIP, TAR, LhA, CAB i inne
\t•\tObsługa archiwów chronionych hasłem

Elastyczne Opcje Wyświetlania
\t•\tPrzełączaj między pojedynczą a podwójną stroną
\t•\tObsługa czytania lewo-prawo i prawo-lewo

Wysoka Wydajność
\t•\tOtwieraj archiwa bezpośrednio
\t•\tSzybkie wyświetlanie z pobieraniem w tle

Zaawansowane Funkcje
\t•\tZakładki ulubionych stron
\t•\tObsługa PDF
\t•\tAutomatyczne przewracanie stron
\t•\t12 filtrów obrazu""",
        "keywords": "rar,7z,komiks,manga,obrazy,przeglądarka,czytnik,archiwum,zip,pdf",
        "whatsNew": """Nowości w wersji 1.1.0:

• Wsparcie Wielu Archiwów: RAR, 7z, TAR i ponad 30 formatów
• Archiwa chronione hasłem
• Natywne ustawienia macOS
• PDF Retina
• Szybsze przeglądanie"""
    },
    "tr": {
        "description": """NectarView, macOS için hızlı bir manga ve resim görüntüleyicisidir — RAR, 7z, ZIP, TAR ve 30'dan fazla arşiv formatını doğrudan açar, çıkarmaya gerek yoktur.

Sezgisel Kontrol
\t•\tDosyaları sürükle-bırak ile açın
\t•\tSağ tık menüsünden açın
\t•\tÇift tıklama ile tam ekran

Çoklu Arşiv Desteği
\t•\tRAR, 7z, ZIP, TAR, LhA, CAB ve daha fazlasını açın
\t•\tParola korumalı arşiv desteği

Esnek Görüntüleme Seçenekleri
\t•\tTek sayfa ve çift sayfa arasında geçiş yapın
\t•\tSoldan sağa ve sağdan sola okuma desteği

Yüksek Performans
\t•\tArşivleri çıkarmadan doğrudan açın
\t•\tÖnyükleme ile hızlı görüntüleme

Gelişmiş Özellikler
\t•\tFavori sayfaları yer imlerine ekleyin
\t•\tPDF desteği
\t•\tOtomatik sayfa çevirme
\t•\t12 gerçek zamanlı filtre""",
        "keywords": "rar,7z,manga,çizgi roman,resim,görüntüleyici,okuyucu,arşiv,zip,pdf",
        "whatsNew": """Sürüm 1.1.0 yenilikleri:

• Çoklu Arşiv Desteği: RAR, 7z, TAR ve 30+ format
• Parola korumalı arşivler
• macOS yerel ayarlar
• Retina PDF
• Daha hızlı gezinme"""
    },
    "ru": {
        "description": """NectarView — быстрый просмотрщик манги и изображений для macOS с поддержкой RAR, 7z, ZIP, TAR и более 30 форматов архивов без распаковки.

Интуитивное управление
\t•\tПеретаскивайте файлы для открытия
\t•\tОткрывайте из контекстного меню
\t•\tДвойной клик для полного экрана

Поддержка архивов
\t•\tRAR, 7z, ZIP, TAR, LhA, CAB и другие
\t•\tАрхивы с паролем

Гибкие настройки отображения
\t•\tПереключение между одной страницей и разворотом
\t•\tЧтение слева направо и справа налево

Высокая производительность
\t•\tОткрытие архивов без распаковки
\t•\tБыстрое отображение с предзагрузкой

Расширенные функции
\t•\tЗакладки любимых страниц
\t•\tПоддержка PDF
\t•\tАвтоматическое перелистывание
\t•\t12 фильтров изображений""",
        "keywords": "rar,7z,манга,комиксы,просмотр,читалка,архив,zip,pdf,фильтр",
        "whatsNew": """Версия 1.1.0:

• Мульти-архивы: RAR, 7z, TAR и 30+ форматов
• Архивы с паролем
• Нативные настройки macOS
• Retina PDF
• Быстрая навигация"""
    },
    "ms": {
        "description": """NectarView ialah pemapar manga dan imej pantas untuk macOS — menyokong RAR, 7z, ZIP, TAR dan 30+ format arkib secara langsung tanpa pengekstrakan.

Kawalan Intuitif
\t•\tSeret dan lepas fail untuk buka
\t•\tBuka dari menu klik kanan
\t•\tKlik dua kali untuk skrin penuh

Sokongan Pelbagai Arkib
\t•\tBuka RAR, 7z, ZIP, TAR, LhA, CAB dan lain-lain
\t•\tSokongan arkib dilindungi kata laluan

Pilihan Paparan Fleksibel
\t•\tTukar antara halaman tunggal dan berganda
\t•\tSokongan bacaan kiri-kanan dan kanan-kiri

Prestasi Tinggi
\t•\tBuka arkib tanpa pengekstrakan
\t•\tPaparan pantas dengan pramuat

Ciri Lanjutan
\t•\tPenanda buku halaman kegemaran
\t•\tSokongan PDF
\t•\tHalaman automatik
\t•\t12 penapis imej""",
        "keywords": "rar,7z,manga,komik,imej,pemapar,pembaca,arkib,zip,pdf",
        "whatsNew": """Versi 1.1.0:

• Sokongan Pelbagai Arkib: RAR, 7z, TAR dan 30+ format
• Arkib dilindungi kata laluan
• Tetapan macOS asli
• PDF Retina
• Pelayaran lebih pantas"""
    },
    "nl-NL": {
        "description": """NectarView is een snelle manga- en afbeeldingsviewer voor macOS — ondersteunt RAR, 7z, ZIP, TAR en 30+ archiefformaten direct zonder uitpakken.

Intuïtieve bediening
\t•\tSleep bestanden om te openen
\t•\tOpen via het contextmenu
\t•\tDubbelklik voor volledig scherm

Multi-archiefondersteuning
\t•\tOpen RAR, 7z, ZIP, TAR, LhA, CAB en meer
\t•\tOndersteunt wachtwoordbeveiligde archieven

Flexibele weergaveopties
\t•\tWissel tussen enkele en dubbele pagina
\t•\tOndersteunt links-rechts en rechts-links lezen

Hoge prestaties
\t•\tOpen archieven direct
\t•\tSnelle weergave met vooraf laden

Geavanceerde functies
\t•\tBladwijzers voor favoriete pagina's
\t•\tPDF-ondersteuning
\t•\tAutomatisch bladeren
\t•\t12 beeldfilters""",
        "keywords": "rar,7z,manga,strip,afbeeldingen,viewer,lezer,archief,zip,pdf",
        "whatsNew": """Versie 1.1.0:

• Multi-archiefondersteuning: RAR, 7z, TAR en 30+ formaten
• Wachtwoordbeveiligde archieven
• macOS-native instellingen
• Retina PDF
• Sneller bladeren"""
    },
    "sv": {
        "description": """NectarView är en snabb manga- och bildvisare för macOS — stöder RAR, 7z, ZIP, TAR och 30+ arkivformat direkt utan uppackning.

Intuitiv styrning
\t•\tDra och släpp filer
\t•\tÖppna från högerklicksmeny
\t•\tDubbelklicka för helskärm

Stöd för flera arkiv
\t•\tÖppna RAR, 7z, ZIP, TAR, LhA, CAB med mera
\t•\tLösenordsskyddade arkiv

Flexibla visningsalternativ
\t•\tVäxla mellan enkel och dubbel sida
\t•\tStöd för vänster-höger och höger-vänster läsning

Hög prestanda
\t•\tÖppna arkiv direkt
\t•\tSnabb visning med förhämtning

Avancerade funktioner
\t•\tBokmärken för favoritsidor
\t•\tPDF-stöd
\t•\tAutomatisk bläddring
\t•\t12 bildfilter""",
        "keywords": "rar,7z,manga,serier,bilder,visare,läsare,arkiv,zip,pdf",
        "whatsNew": """Version 1.1.0:

• Stöd för flera arkiv: RAR, 7z, TAR och 30+ format
• Lösenordsskyddade arkiv
• macOS-native inställningar
• Retina PDF
• Snabbare bläddring"""
    },
    "da": {
        "description": """NectarView er en hurtig manga- og billedfremviser til macOS — understøtter RAR, 7z, ZIP, TAR og 30+ arkivformater direkte uden udpakning.

Intuitiv betjening
\t•\tTræk og slip filer
\t•\tÅbn fra højrekliksmenu
\t•\tDobbeltklik for fuld skærm

Understøttelse af flere arkiver
\t•\tÅbn RAR, 7z, ZIP, TAR, LhA, CAB og mere
\t•\tAdgangskodebeskyttede arkiver

Fleksible visningsmuligheder
\t•\tSkift mellem enkelt og dobbelt side
\t•\tUnderstøtter venstre-højre og højre-venstre læsning

Høj ydeevne
\t•\tÅbn arkiver direkte
\t•\tHurtig visning med forhåndshentning

Avancerede funktioner
\t•\tBogmærker til yndlingssider
\t•\tPDF-understøttelse
\t•\tAutomatisk bladring
\t•\t12 billedfiltre""",
        "keywords": "rar,7z,manga,tegneserier,billeder,fremviser,læser,arkiv,zip,pdf",
        "whatsNew": """Version 1.1.0:

• Understøttelse af flere arkiver: RAR, 7z, TAR og 30+ formater
• Adgangskodebeskyttede arkiver
• macOS-native indstillinger
• Retina PDF
• Hurtigere browsing"""
    },
    "fi": {
        "description": """NectarView on nopea manga- ja kuvankatseluohjelma macOS:lle — tukee RAR, 7z, ZIP, TAR ja yli 30 arkistomuotoa suoraan ilman purkamista.

Intuitiivinen ohjaus
\t•\tVedä ja pudota tiedostoja
\t•\tAvaa oikean klikkauksen valikosta
\t•\tKaksoisnapsautus koko näytölle

Usean arkiston tuki
\t•\tAvaa RAR, 7z, ZIP, TAR, LhA, CAB ja muita
\t•\tSalasanasuojatut arkistot

Joustavat näyttöasetukset
\t•\tVaihda yksittäisen ja kaksoissivu välillä
\t•\tTuki vasemmalta-oikealle ja oikealta-vasemmalle

Korkea suorituskyky
\t•\tAvaa arkistot suoraan
\t•\tNopea näyttö esihakulla

Edistyneet ominaisuudet
\t•\tKirjanmerkit suosikkisivuille
\t•\tPDF-tuki
\t•\tAutomaattinen sivunkääntö
\t•\t12 kuvasuodatinta""",
        "keywords": "rar,7z,manga,sarjakuva,kuvat,katseluohjelma,lukija,arkisto,zip,pdf",
        "whatsNew": """Versio 1.1.0:

• Usean arkiston tuki: RAR, 7z, TAR ja yli 30 muotoa
• Salasanasuojatut arkistot
• macOS-natiivit asetukset
• Retina PDF
• Nopeampi selaus"""
    },
}

def main():
    token = get_token()

    # Get existing localizations
    r = api("GET", f"appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations?limit=30", token)
    loc_map = {item["attributes"]["locale"]: item["id"] for item in r.json()["data"]}

    updated = 0
    errors = 0

    for locale, texts in LOCALES.items():
        loc_id = loc_map.get(locale)
        if not loc_id:
            print(f"  SKIP {locale}: no localization found")
            errors += 1
            continue

        body = {
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": loc_id,
                "attributes": {
                    "description": texts["description"],
                    "keywords": texts["keywords"],
                    "whatsNew": texts["whatsNew"],
                }
            }
        }
        r = api("PATCH", f"appStoreVersionLocalizations/{loc_id}", token, body)
        if r.status_code < 300:
            print(f"✓ {locale}")
            updated += 1
        else:
            errors += 1

        token = get_token()

    print(f"\nDone! Updated {updated} locales, {errors} errors.")

if __name__ == "__main__":
    main()

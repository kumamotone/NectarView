#!/usr/bin/env python3
"""Upload localized description/keywords/whatsNew for 18 new locales."""

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

def create_localization(token, locale):
    """Create a new localization for the given locale if it doesn't exist."""
    body = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "attributes": {"locale": locale},
            "relationships": {
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": VERSION_ID}
                }
            }
        }
    }
    r = api("POST", "appStoreVersionLocalizations", token, body)
    if r.status_code < 300:
        return r.json()["data"]["id"]
    return None

# ---------------------------------------------------------------------------
# Shared English text (used for en-AU, en-CA, en-GB)
# ---------------------------------------------------------------------------
EN_DESCRIPTION = """\
NectarView is a fast, lightweight manga and image viewer for macOS — now with native support for RAR, 7z, ZIP, TAR, and 30+ archive formats, no extraction needed.

Intuitive Controls
\t•\tOpen files with drag and drop
\t•\tOpen from context menu
\t•\tDouble-click for fullscreen
\t•\tDrag viewing area to move window

Multi-Archive Support
\t•\tOpen RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt and more
\t•\tPassword-protected archive support
\t•\tAuto format detection

Flexible Viewing Options
\t•\tToggle between single and spread page
\t•\tLTR and RTL reading support
\t•\tQuick navigation with slider
\t•\tRealistic book appearance in spread view

High Performance
\t•\tOpen archives directly without extraction
\t•\tFast display with prefetching
\t•\tEfficient processing with native macOS APIs

User-Friendly Interface
\t•\tSimple, distraction-free UI
\t•\tCustomizable background and control bar colors
\t•\tNative macOS settings window
\t•\tKeyboard shortcut operations

Advanced Features
\t•\tBookmark function to save locations
\t•\tBatch image display in folder
\t•\tPDF support with Retina rendering
\t•\tAuto page turn with adjustable intervals
\t•\tImage rotation and filter effects"""

EN_KEYWORDS = "rar,7z,cbr,cbz,manga,comic,image,viewer,reader,archive,pdf,filter,bookmark"

EN_WHATS_NEW = """\
What's New in Version 1.1.0:

• Multi-Archive Support: Open RAR, 7z, TAR, LhA, CAB, StuffIt and 30+ formats
• Password-Protected Archives: Enter passwords for encrypted archives
• Native Settings: Redesigned with native macOS look
• Retina PDF: Crisp rendering on high-resolution displays
• Faster Navigation: Image prefetching
• Greater Stability: Removed dependencies and fixed APIs"""

# ---------------------------------------------------------------------------
# Shared Spanish text (used for es-MX, copied from es-ES)
# ---------------------------------------------------------------------------
ES_DESCRIPTION = """\
NectarView es un visor rápido y ligero de manga e imágenes para macOS — ahora con soporte nativo para RAR, 7z, ZIP, TAR y más de 30 formatos de archivo, sin necesidad de extracción.

Controles Intuitivos
\t•\tAbra archivos arrastrando y soltando
\t•\tAbra desde el menú contextual
\t•\tDoble clic para pantalla completa
\t•\tArrastre el área de visualización para mover la ventana

Soporte Multi-Archivo
\t•\tAbra RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt y más
\t•\tSoporte para archivos protegidos por contraseña
\t•\tDetección automática de formato

Opciones de Visualización Flexibles
\t•\tAlterne entre página única y doble página
\t•\tSoporte de lectura de izquierda a derecha y viceversa
\t•\tNavegación rápida con control deslizante
\t•\tApariencia realista de libro en vista doble

Alto Rendimiento
\t•\tAbra archivos directamente sin extracción
\t•\tVisualización rápida con precarga
\t•\tProcesamiento eficiente con APIs nativas de macOS

Interfaz Amigable
\t•\tInterfaz simple y sin distracciones
\t•\tColores personalizables de fondo y barra de control
\t•\tVentana de configuración nativa de macOS
\t•\tOperaciones mediante atajos de teclado

Funciones Avanzadas
\t•\tFunción de marcadores para guardar ubicaciones
\t•\tVisualización de imágenes por lotes en carpeta
\t•\tSoporte PDF con renderizado Retina
\t•\tPaso automático de página con intervalos ajustables
\t•\tRotación de imagen y efectos de filtro"""

ES_KEYWORDS = "rar,7z,cbr,cbz,manga,cómic,imagen,visor,lector,archivo,pdf,filtro,marcador"

ES_WHATS_NEW = """\
Novedades en la versión 1.1.0:

• Soporte Multi-Archivo: Abra RAR, 7z, TAR, LhA, CAB, StuffIt y más de 30 formatos
• Archivos Protegidos por Contraseña: Introduzca contraseñas para archivos cifrados
• Configuración Nativa: Rediseñada con apariencia nativa de macOS
• PDF Retina: Renderizado nítido en pantallas de alta resolución
• Navegación Más Rápida: Precarga de imágenes
• Mayor Estabilidad: Dependencias eliminadas y APIs corregidas"""

# ---------------------------------------------------------------------------
# Shared French text (used for fr-CA, copied from fr-FR)
# ---------------------------------------------------------------------------
FR_DESCRIPTION = """\
NectarView est un lecteur rapide et léger de manga et d'images pour macOS — avec prise en charge native des formats RAR, 7z, ZIP, TAR et plus de 30 formats d'archives, sans extraction nécessaire.

Commandes Intuitives
\t•\tOuvrez des fichiers par glisser-déposer
\t•\tOuvrez depuis le menu contextuel
\t•\tDouble-cliquez pour le plein écran
\t•\tFaites glisser la zone d'affichage pour déplacer la fenêtre

Prise en Charge Multi-Archives
\t•\tOuvrez RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt et plus
\t•\tPrise en charge des archives protégées par mot de passe
\t•\tDétection automatique du format

Options d'Affichage Flexibles
\t•\tBasculez entre page simple et double page
\t•\tLecture de gauche à droite et de droite à gauche
\t•\tNavigation rapide avec le curseur
\t•\tApparence réaliste de livre en mode double page

Haute Performance
\t•\tOuvrez les archives directement sans extraction
\t•\tAffichage rapide avec préchargement
\t•\tTraitement efficace avec les API natives de macOS

Interface Conviviale
\t•\tInterface simple et sans distractions
\t•\tCouleurs personnalisables de fond et de barre de contrôle
\t•\tFenêtre de réglages native macOS
\t•\tRaccourcis clavier

Fonctionnalités Avancées
\t•\tSignets pour enregistrer les emplacements
\t•\tAffichage par lot d'images dans un dossier
\t•\tPrise en charge PDF avec rendu Retina
\t•\tTournage automatique des pages avec intervalles réglables
\t•\tRotation d'images et effets de filtres"""

FR_KEYWORDS = "rar,7z,cbr,cbz,manga,bande dessinée,image,lecteur,visionneuse,archive,pdf,filtre"

FR_WHATS_NEW = """\
Nouveautés de la version 1.1.0 :

• Prise en charge Multi-Archives : Ouvrez RAR, 7z, TAR, LhA, CAB, StuffIt et plus de 30 formats
• Archives Protégées par Mot de Passe : Saisissez le mot de passe pour les archives chiffrées
• Réglages Natifs : Interface redessinée avec l'apparence native de macOS
• PDF Retina : Rendu net sur les écrans haute résolution
• Navigation Plus Rapide : Préchargement des images
• Meilleure Stabilité : Dépendances supprimées et API corrigées"""

# ---------------------------------------------------------------------------
# Norwegian Bokmål text (used for "no", copied from nb/nb-NO)
# ---------------------------------------------------------------------------
NO_DESCRIPTION = """\
NectarView er en rask og lett manga- og bildevisning for macOS — nå med innebygd støtte for RAR, 7z, ZIP, TAR og over 30 arkivformater, uten behov for utpakking.

Intuitive Kontroller
\t•\tÅpne filer med dra og slipp
\t•\tÅpne fra kontekstmenyen
\t•\tDobbeltklikk for fullskjerm
\t•\tDra visningsområdet for å flytte vinduet

Støtte for Flere Arkiver
\t•\tÅpne RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt og mer
\t•\tStøtte for passordbeskyttede arkiver
\t•\tAutomatisk formatgjenkjenning

Fleksible Visningsmuligheter
\t•\tVeksle mellom enkeltside og oppslag
\t•\tStøtte for venstre-til-høyre og høyre-til-venstre lesing
\t•\tRask navigering med glidebryter
\t•\tRealistisk bokutseende i oppslagsvisning

Høy Ytelse
\t•\tÅpne arkiver direkte uten utpakking
\t•\tRask visning med forhåndslasting
\t•\tEffektiv behandling med native macOS-APIer

Brukervennlig Grensesnitt
\t•\tEnkelt, distraksjonsfritt brukergrensesnitt
\t•\tTilpassbare bakgrunns- og kontrolllinjefarger
\t•\tNativt macOS-innstillingsvindu
\t•\tHurtigtastoperasjoner

Avanserte Funksjoner
\t•\tBokmerkefunksjon for å lagre steder
\t•\tVis bilder samlet i mappe
\t•\tPDF-støtte med Retina-gjengivelse
\t•\tAutomatisk sideblaing med justerbare intervaller
\t•\tBilderotasjon og filtereffekter"""

NO_KEYWORDS = "rar,7z,cbr,cbz,manga,tegneserie,bilde,visning,leser,arkiv,zip,pdf,filter"

NO_WHATS_NEW = """\
Nyheter i versjon 1.1.0:

• Støtte for Flere Arkiver: Åpne RAR, 7z, TAR, LhA, CAB, StuffIt og over 30 formater
• Passordbeskyttede Arkiver: Skriv inn passord for krypterte arkiver
• Native Innstillinger: Redesignet med native macOS-utseende
• Retina PDF: Skarp gjengivelse på høyoppløselige skjermer
• Raskere Navigering: Forhåndslasting av bilder
• Bedre Stabilitet: Fjernet avhengigheter og fikset APIer"""

# ---------------------------------------------------------------------------
# European Portuguese (adjusted from pt-BR)
# ---------------------------------------------------------------------------
PT_PT_DESCRIPTION = """\
NectarView é um visualizador rápido e leve de banda desenhada e imagens para macOS — agora com suporte direto a RAR, 7z, ZIP, TAR e mais de 30 formatos de ficheiro, sem necessidade de extração.

Controlos Intuitivos
\t•\tAbra ficheiros facilmente com arrastar e largar
\t•\tAbra ficheiros pelo menu de contexto
\t•\tAlterne ecrã inteiro com duplo clique
\t•\tArraste a área de visualização para mover a janela

Suporte Multi-Ficheiro
\t•\tAbra RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt e mais
\t•\tSuporte a ficheiros protegidos por palavra-passe
\t•\tDeteção automática de formato

Opções Flexíveis de Visualização
\t•\tAlterne entre página única e página dupla
\t•\tSuporte para leitura da esquerda para a direita e vice-versa
\t•\tNavegue rapidamente com o controlo deslizante
\t•\tAparência realista de livro na vista dupla

Alto Desempenho
\t•\tAbra ficheiros diretamente sem extração
\t•\tExibição rápida com pré-carregamento
\t•\tProcessamento eficiente com APIs nativas do macOS

Interface Amigável
\t•\tInterface simples e sem distrações
\t•\tCores personalizáveis de fundo e barra de controlo
\t•\tJanela de definições nativa do macOS
\t•\tOperações por atalhos de teclado

Funcionalidades Avançadas
\t•\tFunção de marcadores para guardar localizações
\t•\tExibição em lote de imagens numa pasta
\t•\tSuporte a PDF com renderização Retina
\t•\tMudança automática de página com intervalos ajustáveis
\t•\tRotação de imagem e efeitos de filtro"""

PT_PT_KEYWORDS = "rar,7z,cbr,cbz,ficheiro,manga,banda desenhada,leitor,visualizador,filtro,marcador"

PT_PT_WHATS_NEW = """\
Novidades na versão 1.1.0:

• Suporte Multi-Ficheiro: Abra RAR, 7z, TAR, LhA, CAB, StuffIt e mais de 30 formatos
• Ficheiros Protegidos por Palavra-passe: Introduza palavras-passe para ficheiros encriptados
• Definições Nativas: Design renovado com visual nativo do macOS
• PDF Retina: Renderização nítida em ecrãs de alta resolução
• Navegação Mais Rápida: Pré-carregamento de imagens
• Maior Estabilidade: Dependências removidas e APIs corrigidas"""

# ---------------------------------------------------------------------------
# Translations for 18 new locales
# ---------------------------------------------------------------------------
LOCALES = {
    # ---- Regional English variants (copy from en-US) ----
    "en-AU": {
        "description": EN_DESCRIPTION,
        "keywords": EN_KEYWORDS,
        "whatsNew": EN_WHATS_NEW,
    },
    "en-CA": {
        "description": EN_DESCRIPTION,
        "keywords": EN_KEYWORDS,
        "whatsNew": EN_WHATS_NEW,
    },
    "en-GB": {
        "description": EN_DESCRIPTION,
        "keywords": EN_KEYWORDS,
        "whatsNew": EN_WHATS_NEW,
    },
    # ---- Spanish (Mexico) — copy from es-ES ----
    "es-MX": {
        "description": ES_DESCRIPTION,
        "keywords": ES_KEYWORDS,
        "whatsNew": ES_WHATS_NEW,
    },
    # ---- French (Canada) — copy from fr-FR ----
    "fr-CA": {
        "description": FR_DESCRIPTION,
        "keywords": FR_KEYWORDS,
        "whatsNew": FR_WHATS_NEW,
    },
    # ---- Norwegian — copy from nb (Bokmål) ----
    "no": {
        "description": NO_DESCRIPTION,
        "keywords": NO_KEYWORDS,
        "whatsNew": NO_WHATS_NEW,
    },
    # ---- European Portuguese (adjusted from pt-BR) ----
    "pt-PT": {
        "description": PT_PT_DESCRIPTION,
        "keywords": PT_PT_KEYWORDS,
        "whatsNew": PT_PT_WHATS_NEW,
    },
    # ---- Arabic (Saudi Arabia) ----
    "ar-SA": {
        "description": """\
NectarView هو عارض سريع وخفيف للمانجا والصور على macOS — يدعم الآن RAR و7z وZIP وTAR وأكثر من 30 صيغة أرشيف بشكل مباشر، دون الحاجة للاستخراج.

تحكم بديهي
\t•\tافتح الملفات بالسحب والإفلات
\t•\tافتح من قائمة السياق
\t•\tانقر مرتين للعرض بملء الشاشة
\t•\تاسحب منطقة العرض لتحريك النافذة

دعم أرشيفات متعددة
\t•\tافتح RAR و7z وZIP وTAR وLhA وCAB وStuffIt والمزيد
\t•\tدعم الأرشيفات المحمية بكلمة مرور
\t•\tاكتشاف تلقائي للصيغة

خيارات عرض مرنة
\t•\tالتبديل بين صفحة مفردة وصفحتين
\t•\tدعم القراءة من اليسار لليمين ومن اليمين لليسار
\t•\tتنقل سريع باستخدام شريط التمرير
\t•\tمظهر كتاب واقعي في عرض الصفحتين

أداء عالي
\t•\tافتح الأرشيفات مباشرة دون استخراج
\t•\tعرض سريع مع التحميل المسبق
\t•\tمعالجة فعّالة باستخدام واجهات macOS الأصلية

واجهة سهلة الاستخدام
\t•\tواجهة بسيطة وخالية من المشتتات
\t•\tألوان خلفية وشريط تحكم قابلة للتخصيص
\t•\tنافذة إعدادات macOS الأصلية
\t•\تعمليات اختصارات لوحة المفاتيح

ميزات متقدمة
\t•\tوظيفة الإشارات المرجعية لحفظ المواقع
\t•\تعرض مجموعة صور في مجلد
\t•\تدعم PDF مع عرض Retina
\t•\تقليب تلقائي للصفحات بفواصل زمنية قابلة للتعديل
\t•\تدوير الصور وتأثيرات الفلاتر""",
        "keywords": "rar,7z,cbr,cbz,مانجا,كوميكس,صور,عارض,قارئ,أرشيف,pdf,فلتر",
        "whatsNew": """\
الجديد في الإصدار 1.1.0:

• دعم أرشيفات متعددة: افتح RAR و7z وTAR وLhA وCAB وStuffIt وأكثر من 30 صيغة
• أرشيفات محمية بكلمة مرور: أدخل كلمات المرور للأرشيفات المشفرة
• إعدادات أصلية: تصميم جديد بمظهر macOS الأصلي
• PDF بدقة Retina: عرض واضح على الشاشات عالية الدقة
• تنقل أسرع: تحميل مسبق للصور
• استقرار أكبر: إزالة التبعيات وإصلاح واجهات البرمجة""",
    },
    # ---- Catalan ----
    "ca": {
        "description": """\
NectarView és un visualitzador ràpid i lleuger de manga i imatges per a macOS — ara amb suport natiu per a RAR, 7z, ZIP, TAR i més de 30 formats d'arxiu, sense necessitat d'extracció.

Controls Intuïtius
\t•\tObriu fitxers arrossegant i deixant anar
\t•\tObriu des del menú contextual
\t•\tDoble clic per a pantalla completa
\t•\tArrossegueu l'àrea de visualització per moure la finestra

Suport Multi-Arxiu
\t•\tObriu RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt i més
\t•\tSuport per a arxius protegits amb contrasenya
\t•\tDetecció automàtica de format

Opcions de Visualització Flexibles
\t•\tAlterneu entre pàgina única i pàgina doble
\t•\tSuport de lectura d'esquerra a dreta i de dreta a esquerra
\t•\tNavegació ràpida amb control lliscant
\t•\tAparença realista de llibre en vista doble

Alt Rendiment
\t•\tObriu arxius directament sense extracció
\t•\tVisualització ràpida amb precàrrega
\t•\tProcessament eficient amb APIs natives de macOS

Interfície Amigable
\t•\tInterfície simple i sense distraccions
\t•\tColors personalitzables de fons i barra de control
\t•\tFinestra de configuració nativa de macOS
\t•\tOperacions amb dreceres de teclat

Funcions Avançades
\t•\tFunció de marcadors per desar ubicacions
\t•\tVisualització d'imatges per lots en carpeta
\t•\tSuport PDF amb renderització Retina
\t•\tPassament automàtic de pàgina amb intervals ajustables
\t•\tRotació d'imatges i efectes de filtre""",
        "keywords": "rar,7z,cbr,cbz,manga,còmic,imatge,visualitzador,lector,arxiu,pdf,filtre",
        "whatsNew": """\
Novetats de la versió 1.1.0:

• Suport Multi-Arxiu: Obriu RAR, 7z, TAR, LhA, CAB, StuffIt i més de 30 formats
• Arxius Protegits amb Contrasenya: Introduïu contrasenyes per a arxius xifrats
• Configuració Nativa: Redissenyada amb aparença nativa de macOS
• PDF Retina: Renderització nítida en pantalles d'alta resolució
• Navegació Més Ràpida: Precàrrega d'imatges
• Major Estabilitat: Dependències eliminades i APIs corregides""",
    },
    # ---- Czech ----
    "cs": {
        "description": """\
NectarView je rychlý a lehký prohlížeč mangy a obrázků pro macOS — nyní s nativní podporou RAR, 7z, ZIP, TAR a více než 30 formátů archivů, bez nutnosti rozbalení.

Intuitivní Ovládání
\t•\tOtevírejte soubory přetažením
\t•\tOtevírejte z kontextového menu
\t•\tDvojklik pro celou obrazovku
\t•\tPřetáhněte zobrazovací oblast pro přesun okna

Podpora Více Archivů
\t•\tOtevřete RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt a další
\t•\tPodpora archivů chráněných heslem
\t•\tAutomatická detekce formátu

Flexibilní Možnosti Zobrazení
\t•\tPřepínání mezi jednotlivou a dvojstránkou
\t•\tPodpora čtení zleva doprava i zprava doleva
\t•\tRychlá navigace pomocí posuvníku
\t•\tRealistický vzhled knihy v režimu dvojstránky

Vysoký Výkon
\t•\tOtevírejte archivy přímo bez rozbalení
\t•\tRychlé zobrazení s přednačítáním
\t•\tEfektivní zpracování s nativními API macOS

Přívětivé Rozhraní
\t•\tJednoduché rozhraní bez rušivých prvků
\t•\tPřizpůsobitelné barvy pozadí a ovládacího panelu
\t•\tNativní okno nastavení macOS
\t•\tKlávesové zkratky

Pokročilé Funkce
\t•\tZáložky pro uložení pozic
\t•\tHromadné zobrazení obrázků ve složce
\t•\tPodpora PDF s vykreslováním Retina
\t•\tAutomatické otáčení stránek s nastavitelnými intervaly
\t•\tRotace obrázků a efekty filtrů""",
        "keywords": "rar,7z,cbr,cbz,manga,komiks,obrázky,prohlížeč,čtečka,archiv,pdf,filtr",
        "whatsNew": """\
Novinky ve verzi 1.1.0:

• Podpora Více Archivů: Otevřete RAR, 7z, TAR, LhA, CAB, StuffIt a více než 30 formátů
• Archivy Chráněné Heslem: Zadejte hesla pro šifrované archivy
• Nativní Nastavení: Přepracováno s nativním vzhledem macOS
• PDF Retina: Ostré vykreslování na displejích s vysokým rozlišením
• Rychlejší Navigace: Přednačítání obrázků
• Větší Stabilita: Odstraněny závislosti a opraveny API""",
    },
    # ---- Greek ----
    "el": {
        "description": """\
Το NectarView είναι ένα γρήγορο και ελαφρύ πρόγραμμα προβολής manga και εικόνων για macOS — τώρα με εγγενή υποστήριξη RAR, 7z, ZIP, TAR και πάνω από 30 μορφές αρχείων, χωρίς εξαγωγή.

Διαισθητικός Έλεγχος
\t•\tΑνοίξτε αρχεία με μεταφορά και απόθεση
\t•\tΑνοίξτε από το μενού περιβάλλοντος
\t•\tΔιπλό κλικ για πλήρη οθόνη
\t•\tΣύρετε την περιοχή προβολής για μετακίνηση του παραθύρου

Υποστήριξη Πολλαπλών Αρχείων
\t•\tΑνοίξτε RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt και άλλα
\t•\tΥποστήριξη αρχείων με κωδικό πρόσβασης
\t•\tΑυτόματη ανίχνευση μορφής

Ευέλικτες Επιλογές Προβολής
\t•\tΕναλλαγή μεταξύ μονής και διπλής σελίδας
\t•\tΥποστήριξη ανάγνωσης αριστερά-δεξιά και δεξιά-αριστερά
\t•\tΓρήγορη πλοήγηση με ρυθμιστικό
\t•\tΡεαλιστική εμφάνιση βιβλίου σε προβολή διπλής σελίδας

Υψηλή Απόδοση
\t•\tΑνοίξτε αρχεία απευθείας χωρίς εξαγωγή
\t•\tΓρήγορη εμφάνιση με προφόρτωση
\t•\tΑποδοτική επεξεργασία με εγγενή API του macOS

Φιλική Διεπαφή
\t•\tΑπλή διεπαφή χωρίς περισπασμούς
\t•\tΠροσαρμόσιμα χρώματα φόντου και γραμμής ελέγχου
\t•\tΕγγενές παράθυρο ρυθμίσεων macOS
\t•\tΛειτουργίες με πλήκτρα συντόμευσης

Προηγμένες Λειτουργίες
\t•\tΛειτουργία σελιδοδεικτών για αποθήκευση θέσεων
\t•\tΟμαδική προβολή εικόνων σε φάκελο
\t•\tΥποστήριξη PDF με απόδοση Retina
\t•\tΑυτόματη αλλαγή σελίδας με ρυθμιζόμενα διαστήματα
\t•\tΠεριστροφή εικόνας και εφέ φίλτρων""",
        "keywords": "rar,7z,cbr,cbz,manga,κόμικ,εικόνα,προβολέας,αναγνώστης,αρχείο,pdf,φίλτρο",
        "whatsNew": """\
Τι Νέο στην Έκδοση 1.1.0:

• Υποστήριξη Πολλαπλών Αρχείων: Ανοίξτε RAR, 7z, TAR, LhA, CAB, StuffIt και πάνω από 30 μορφές
• Αρχεία με Κωδικό Πρόσβασης: Εισαγάγετε κωδικούς για κρυπτογραφημένα αρχεία
• Εγγενείς Ρυθμίσεις: Επανασχεδιασμός με εγγενή εμφάνιση macOS
• PDF Retina: Καθαρή απόδοση σε οθόνες υψηλής ανάλυσης
• Ταχύτερη Πλοήγηση: Προφόρτωση εικόνων
• Μεγαλύτερη Σταθερότητα: Αφαίρεση εξαρτήσεων και διόρθωση API""",
    },
    # ---- Hebrew ----
    "he": {
        "description": """\
NectarView הוא מציג מנגה ותמונות מהיר וקל משקל עבור macOS — כעת עם תמיכה מובנית ב-RAR, 7z, ZIP, TAR ומעל 30 פורמטים של ארכיונים, ללא צורך בחילוץ.

בקרה אינטואיטיבית
\t•\tפתחו קבצים בגרירה ושחרור
\t•\tפתחו מתפריט ההקשר
\t•\tלחיצה כפולה למסך מלא
\t•\tגררו את אזור הצפייה להזזת החלון

תמיכה בארכיונים מרובים
\t•\tפתחו RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt ועוד
\t•\tתמיכה בארכיונים מוגני סיסמה
\t•\tזיהוי פורמט אוטומטי

אפשרויות צפייה גמישות
\t•\tמעבר בין עמוד בודד לזוגי
\t•\tתמיכה בקריאה משמאל לימין ומימין לשמאל
\t•\tניווט מהיר עם מחוון
\t•\tמראה ספר ריאליסטי בתצוגה זוגית

ביצועים גבוהים
\t•\tפתחו ארכיונים ישירות ללא חילוץ
\t•\tתצוגה מהירה עם טעינה מוקדמת
\t•\tעיבוד יעיל עם ממשקי macOS מקוריים

ממשק ידידותי
\t•\tממשק פשוט ונקי מהסחות
\t•\tצבעי רקע ופס בקרה הניתנים להתאמה
\t•\tחלון הגדרות macOS מקורי
\t•\tפעולות קיצורי מקלדת

תכונות מתקדמות
\t•\tסימניות לשמירת מיקומים
\t•\tתצוגת תמונות קבוצתית בתיקייה
\t•\tתמיכת PDF עם רינדור Retina
\t•\tהפיכת דף אוטומטית במרווחים מתכווננים
\t•\tסיבוב תמונה ואפקטי פילטרים""",
        "keywords": "rar,7z,cbr,cbz,מנגה,קומיקס,תמונות,מציג,קורא,ארכיון,pdf,פילטר",
        "whatsNew": """\
חדש בגרסה 1.1.0:

• תמיכה בארכיונים מרובים: פתחו RAR, 7z, TAR, LhA, CAB, StuffIt ומעל 30 פורמטים
• ארכיונים מוגני סיסמה: הזינו סיסמאות לארכיונים מוצפנים
• הגדרות מקוריות: עוצבו מחדש עם מראה macOS מקורי
• PDF Retina: רינדור חד במסכים ברזולוציה גבוהה
• ניווט מהיר יותר: טעינה מוקדמת של תמונות
• יציבות משופרת: הסרת תלויות ותיקון ממשקי API""",
    },
    # ---- Hindi ----
    "hi": {
        "description": """\
NectarView macOS के लिए एक तेज़ और हल्का मंगा और इमेज व्यूअर है — अब RAR, 7z, ZIP, TAR और 30+ आर्काइव फ़ॉर्मेट के लिए नेटिव सपोर्ट के साथ, बिना एक्सट्रैक्शन के।

सहज नियंत्रण
\t•\tड्रैग और ड्रॉप से फ़ाइलें खोलें
\t•\tकॉन्टेक्स्ट मेन्यू से खोलें
\t•\tफ़ुलस्क्रीन के लिए डबल-क्लिक करें
\t•\tव्यूइंग एरिया को ड्रैग करके विंडो मूव करें

मल्टी-आर्काइव सपोर्ट
\t•\tRAR, 7z, ZIP, TAR, LhA, CAB, StuffIt और अधिक खोलें
\t•\tपासवर्ड-प्रोटेक्टेड आर्काइव सपोर्ट
\t•\tऑटो फ़ॉर्मेट डिटेक्शन

लचीले व्यूइंग विकल्प
\t•\tसिंगल और स्प्रेड पेज के बीच टॉगल करें
\t•\tबाएं-से-दाएं और दाएं-से-बाएं रीडिंग सपोर्ट
\t•\tस्लाइडर से त्वरित नेविगेशन
\t•\tस्प्रेड व्यू में यथार्थवादी पुस्तक दिखावट

उच्च प्रदर्शन
\t•\tबिना एक्सट्रैक्शन के आर्काइव सीधे खोलें
\t•\tप्रीफ़ेचिंग के साथ तेज़ डिस्प्ले
\t•\tनेटिव macOS API के साथ कुशल प्रोसेसिंग

उपयोगकर्ता-अनुकूल इंटरफ़ेस
\t•\tसरल, विकर्षण-मुक्त UI
\t•\tकस्टमाइज़ करने योग्य बैकग्राउंड और कंट्रोल बार रंग
\t•\tनेटिव macOS सेटिंग्स विंडो
\t•\tकीबोर्ड शॉर्टकट ऑपरेशन

उन्नत सुविधाएँ
\t•\tस्थान सहेजने के लिए बुकमार्क फ़ंक्शन
\t•\tफ़ोल्डर में बैच इमेज डिस्प्ले
\t•\tRetina रेंडरिंग के साथ PDF सपोर्ट
\t•\tसमायोज्य अंतराल के साथ ऑटो पेज टर्न
\t•\tइमेज रोटेशन और फ़िल्टर इफ़ेक्ट""",
        "keywords": "rar,7z,cbr,cbz,मंगा,कॉमिक,इमेज,व्यूअर,रीडर,आर्काइव,pdf,फ़िल्टर",
        "whatsNew": """\
संस्करण 1.1.0 में नया:

• मल्टी-आर्काइव सपोर्ट: RAR, 7z, TAR, LhA, CAB, StuffIt और 30+ फ़ॉर्मेट खोलें
• पासवर्ड-प्रोटेक्टेड आर्काइव: एन्क्रिप्टेड आर्काइव के लिए पासवर्ड दर्ज करें
• नेटिव सेटिंग्स: macOS के नेटिव लुक के साथ फिर से डिज़ाइन किया गया
• Retina PDF: उच्च-रिज़ॉल्यूशन डिस्प्ले पर स्पष्ट रेंडरिंग
• तेज़ नेविगेशन: इमेज प्रीफ़ेचिंग
• बेहतर स्थिरता: डिपेंडेंसी हटाई गईं और API ठीक किए गए""",
    },
    # ---- Croatian ----
    "hr": {
        "description": """\
NectarView je brz i lagan preglednik mange i slika za macOS — sada s izvornom podrškom za RAR, 7z, ZIP, TAR i više od 30 formata arhiva, bez potrebe za raspakiranjem.

Intuitivne Kontrole
\t•\tOtvorite datoteke povlačenjem i ispuštanjem
\t•\tOtvorite iz kontekstnog izbornika
\t•\tDvostruki klik za puni zaslon
\t•\tPovucite područje prikaza za pomicanje prozora

Podrška za Više Arhiva
\t•\tOtvorite RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt i više
\t•\tPodrška za arhive zaštićene lozinkom
\t•\tAutomatsko prepoznavanje formata

Fleksibilne Opcije Prikaza
\t•\tPrebacivanje između jednostruke i dvostruke stranice
\t•\tPodrška za čitanje slijeva nadesno i zdesna nalijevo
\t•\tBrza navigacija klizačem
\t•\tRealistični izgled knjige u dvostrukom prikazu

Visoke Performanse
\t•\tOtvorite arhive izravno bez raspakiranja
\t•\tBrzi prikaz s unaprijed učitavanjem
\t•\tUčinkovita obrada s izvornim macOS API-jima

Korisnički Prilagođeno Sučelje
\t•\tJednostavno sučelje bez ometanja
\t•\tPrilagodljive boje pozadine i kontrolne trake
\t•\tIzvorni macOS prozor postavki
\t•\tTipkovnički prečaci

Napredne Značajke
\t•\tFunkcija oznaka za spremanje lokacija
\t•\tSkupni prikaz slika u mapi
\t•\tPDF podrška s Retina prikazom
\t•\tAutomatsko okretanje stranica s podesivim intervalima
\t•\tRotacija slike i efekti filtera""",
        "keywords": "rar,7z,cbr,cbz,manga,strip,slika,preglednik,čitač,arhiv,pdf,filtar",
        "whatsNew": """\
Novo u verziji 1.1.0:

• Podrška za Više Arhiva: Otvorite RAR, 7z, TAR, LhA, CAB, StuffIt i više od 30 formata
• Arhivi Zaštićeni Lozinkom: Unesite lozinke za šifrirane arhive
• Izvorne Postavke: Redizajnirano s izvornim macOS izgledom
• Retina PDF: Oštar prikaz na zaslonima visoke rezolucije
• Brža Navigacija: Unaprijed učitavanje slika
• Veća Stabilnost: Uklonjene ovisnosti i popravljeni API-ji""",
    },
    # ---- Hungarian ----
    "hu": {
        "description": """\
A NectarView egy gyors és könnyű manga- és képnézegető macOS-re — most már natív támogatással a RAR, 7z, ZIP, TAR és 30+ archívumformátumhoz, kicsomagolás nélkül.

Intuitív Vezérlés
\t•\tFájlok megnyitása húzással
\t•\tMegnyitás a helyi menüből
\t•\tDupla kattintás a teljes képernyőhöz
\t•\tHúzza a megjelenítési területet az ablak mozgatásához

Több Archívum Támogatása
\t•\tNyissa meg a RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt és más formátumokat
\t•\tJelszóval védett archívumok támogatása
\t•\tAutomatikus formátumfelismerés

Rugalmas Megjelenítési Lehetőségek
\t•\tVáltás egyoldalas és kétoldalas nézet között
\t•\tBalról jobbra és jobbról balra olvasás támogatása
\t•\tGyors navigáció csúszkával
\t•\tRealisztikus könyvmegjelenés kétoldalas nézetben

Magas Teljesítmény
\t•\tArchívumok közvetlen megnyitása kicsomagolás nélkül
\t•\tGyors megjelenítés előzetes betöltéssel
\t•\tHatékony feldolgozás natív macOS API-kkal

Felhasználóbarát Felület
\t•\tEgyszerű, zavarásmentes felület
\t•\tTestreszabható háttér- és vezérlősáv-színek
\t•\tNatív macOS beállítások ablak
\t•\tBillentyűparancsok

Haladó Funkciók
\t•\tKönyvjelző funkció helyek mentéséhez
\t•\tKötegelt képmegjelenítés mappában
\t•\tPDF támogatás Retina megjelenítéssel
\t•\tAutomatikus lapozás állítható időközökkel
\t•\tKépforgatás és szűrőeffektusok""",
        "keywords": "rar,7z,cbr,cbz,manga,képregény,kép,nézegető,olvasó,archívum,pdf,szűrő",
        "whatsNew": """\
Újdonságok az 1.1.0 verzióban:

• Több Archívum Támogatása: Nyissa meg a RAR, 7z, TAR, LhA, CAB, StuffIt és 30+ formátumot
• Jelszóval Védett Archívumok: Írja be a jelszót a titkosított archívumokhoz
• Natív Beállítások: Újratervezett natív macOS megjelenéssel
• Retina PDF: Éles megjelenítés nagy felbontású kijelzőkön
• Gyorsabb Navigáció: Képek előzetes betöltése
• Nagyobb Stabilitás: Függőségek eltávolítása és API-k javítása""",
    },
    # ---- Romanian ----
    "ro": {
        "description": """\
NectarView este un vizualizator rapid și ușor de manga și imagini pentru macOS — acum cu suport nativ pentru RAR, 7z, ZIP, TAR și peste 30 de formate de arhivă, fără extracție.

Comenzi Intuitive
\t•\tDeschideți fișiere prin glisare și plasare
\t•\tDeschideți din meniul contextual
\t•\tDublu clic pentru ecran complet
\t•\tTrageți zona de vizualizare pentru a muta fereastra

Suport Multi-Arhivă
\t•\tDeschideți RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt și altele
\t•\tSuport pentru arhive protejate cu parolă
\t•\tDetecție automată a formatului

Opțiuni Flexibile de Vizualizare
\t•\tComutare între pagină simplă și pagină dublă
\t•\tSuport citire stânga-dreapta și dreapta-stânga
\t•\tNavigare rapidă cu cursor
\t•\tAspect realist de carte în vizualizare dublă

Performanță Ridicată
\t•\tDeschideți arhive direct fără extracție
\t•\tAfișare rapidă cu preîncărcare
\t•\tProcesare eficientă cu API-uri native macOS

Interfață Prietenoasă
\t•\tInterfață simplă, fără distrageri
\t•\tCulori personalizabile pentru fundal și bară de control
\t•\tFereastră de setări nativă macOS
\t•\tOperații cu scurtături de tastatură

Funcții Avansate
\t•\tFuncție de marcaje pentru salvarea locațiilor
\t•\tAfișare în lot a imaginilor din folder
\t•\tSuport PDF cu randare Retina
\t•\tÎntoarcere automată a paginii cu intervale ajustabile
\t•\tRotire imagine și efecte de filtre""",
        "keywords": "rar,7z,cbr,cbz,manga,bandă desenată,imagine,vizualizator,cititor,arhivă,pdf",
        "whatsNew": """\
Noutăți în versiunea 1.1.0:

• Suport Multi-Arhivă: Deschideți RAR, 7z, TAR, LhA, CAB, StuffIt și peste 30 de formate
• Arhive Protejate cu Parolă: Introduceți parole pentru arhive criptate
• Setări Native: Redesign cu aspect nativ macOS
• PDF Retina: Randare clară pe ecrane cu rezoluție înaltă
• Navigare Mai Rapidă: Preîncărcare imagini
• Stabilitate Mai Mare: Dependențe eliminate și API-uri corectate""",
    },
    # ---- Slovak ----
    "sk": {
        "description": """\
NectarView je rýchly a ľahký prehliadač mangy a obrázkov pre macOS — teraz s natívnou podporou RAR, 7z, ZIP, TAR a viac ako 30 formátov archívov, bez potreby rozbalenia.

Intuitívne Ovládanie
\t•\tOtvárajte súbory potiahnutím
\t•\tOtvárajte z kontextového menu
\t•\tDvojklik pre celú obrazovku
\t•\tPotiahnite oblasť zobrazenia na presun okna

Podpora Viacerých Archívov
\t•\tOtvorte RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt a ďalšie
\t•\tPodpora archívov chránených heslom
\t•\tAutomatická detekcia formátu

Flexibilné Možnosti Zobrazenia
\t•\tPrepínanie medzi jednoduchou a dvojstranou
\t•\tPodpora čítania zľava doprava a zprava doľava
\t•\tRýchla navigácia pomocou posúvača
\t•\tRealistický vzhľad knihy v režime dvojstrany

Vysoký Výkon
\t•\tOtvárajte archívy priamo bez rozbalenia
\t•\tRýchle zobrazenie s prednačítaním
\t•\tEfektívne spracovanie s natívnymi API macOS

Používateľsky Prívetivé Rozhranie
\t•\tJednoduché rozhranie bez rušivých prvkov
\t•\tPrispôsobiteľné farby pozadia a ovládacieho panela
\t•\tNatívne okno nastavení macOS
\t•\tKlávesové skratky

Pokročilé Funkcie
\t•\tZáložky na ukladanie pozícií
\t•\tHromadné zobrazenie obrázkov v priečinku
\t•\tPodpora PDF s vykresľovaním Retina
\t•\tAutomatické otáčanie stránok s nastaviteľnými intervalmi
\t•\tRotácia obrázkov a efekty filtrov""",
        "keywords": "rar,7z,cbr,cbz,manga,komiks,obrázky,prehliadač,čítačka,archív,pdf,filter",
        "whatsNew": """\
Novinky vo verzii 1.1.0:

• Podpora Viacerých Archívov: Otvorte RAR, 7z, TAR, LhA, CAB, StuffIt a viac ako 30 formátov
• Archívy Chránené Heslom: Zadajte heslá pre šifrované archívy
• Natívne Nastavenia: Prepracované s natívnym vzhľadom macOS
• PDF Retina: Ostré vykresľovanie na displejoch s vysokým rozlíšením
• Rýchlejšia Navigácia: Prednačítanie obrázkov
• Väčšia Stabilita: Odstránené závislosti a opravené API""",
    },
    # ---- Ukrainian ----
    "uk": {
        "description": """\
NectarView — швидкий і легкий переглядач манґи та зображень для macOS — тепер з нативною підтримкою RAR, 7z, ZIP, TAR та понад 30 форматів архівів, без розпакування.

Інтуїтивне Керування
\t•\tВідкривайте файли перетягуванням
\t•\tВідкривайте з контекстного меню
\t•\tПодвійний клік для повного екрану
\t•\tПеретягуйте область перегляду для переміщення вікна

Підтримка Багатьох Архівів
\t•\tВідкривайте RAR, 7z, ZIP, TAR, LhA, CAB, StuffIt та інші
\t•\tПідтримка архівів, захищених паролем
\t•\tАвтоматичне визначення формату

Гнучкі Параметри Перегляду
\t•\tПеремикання між однією сторінкою та розворотом
\t•\tПідтримка читання зліва направо та справа наліво
\t•\tШвидка навігація повзунком
\t•\tРеалістичний вигляд книги у режимі розвороту

Висока Продуктивність
\t•\tВідкривайте архіви безпосередньо без розпакування
\t•\tШвидке відображення з попереднім завантаженням
\t•\tЕфективна обробка з нативними API macOS

Зручний Інтерфейс
\t•\tПростий інтерфейс без відволікань
\t•\tНалаштовувані кольори фону та панелі керування
\t•\tНативне вікно налаштувань macOS
\t•\tОперації гарячими клавішами

Розширені Функції
\t•\tЗакладки для збереження місць
\t•\tПакетне відображення зображень у папці
\t•\tПідтримка PDF з рендерингом Retina
\t•\tАвтоматичне гортання сторінок з налаштовуваними інтервалами
\t•\tОбертання зображень та ефекти фільтрів""",
        "keywords": "rar,7z,cbr,cbz,манґа,комікс,зображення,переглядач,читач,архів,pdf,фільтр",
        "whatsNew": """\
Що нового у версії 1.1.0:

• Підтримка Багатьох Архівів: Відкривайте RAR, 7z, TAR, LhA, CAB, StuffIt та понад 30 форматів
• Архіви Захищені Паролем: Введіть паролі для зашифрованих архівів
• Нативні Налаштування: Перероблено з нативним виглядом macOS
• Retina PDF: Чітке відображення на дисплеях високої роздільної здатності
• Швидша Навігація: Попереднє завантаження зображень
• Краща Стабільність: Видалено залежності та виправлено API""",
    },
}

def main():
    token = get_token()

    # Get existing localizations
    print("Fetching existing version localizations...")
    r = api("GET", f"appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations?limit=50", token)
    loc_map = {item["attributes"]["locale"]: item["id"] for item in r.json()["data"]}
    print(f"  Found {len(loc_map)} existing localizations: {', '.join(sorted(loc_map.keys()))}")

    updated = 0
    created = 0
    errors = 0

    for locale, texts in LOCALES.items():
        loc_id = loc_map.get(locale)

        # Create localization if it doesn't exist
        if not loc_id:
            print(f"  Creating localization for {locale}...")
            token = get_token()
            loc_id = create_localization(token, locale)
            if not loc_id:
                print(f"  FAILED to create localization for {locale}")
                errors += 1
                continue
            created += 1
            print(f"  Created localization for {locale}")

        # Update with text content
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
        token = get_token()
        r = api("PATCH", f"appStoreVersionLocalizations/{loc_id}", token, body)
        if r.status_code < 300:
            print(f"  ✓ {locale}")
            updated += 1
        else:
            errors += 1

    print(f"\nDone! Created {created}, updated {updated} locales, {errors} errors.")

if __name__ == "__main__":
    main()

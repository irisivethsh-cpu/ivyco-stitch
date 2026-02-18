import os
import re


VIEWPORT_META = '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
TAILWIND_CDN = '<script src="https://cdn.tailwindcss.com"></script>'
GOOGLE_FONTS = '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400&family=Playfair+Display:ital,wght@0,600;1,600&display=swap" rel="stylesheet">'
TAILWIND_CONFIG = '''<script id="ivyco-tailwind-config">
  tailwind.config = {
    theme: {
      extend: {
        colors: {
          ivory: '#faf7f2',
          gold: '#b08d57',
          dark: '#1a1a1a'
        }
      }
    }
  };
</script>'''

BODY_CLASS_TAG = '<body class="bg-ivory text-dark antialiased font-sans">'
BACK_BUTTON = '''<a id="ivyco-back-button" href="../index.html" class="fixed top-6 left-6 z-50 rounded-full border border-white/70 bg-white/60 px-4 py-2 text-sm font-medium text-dark shadow-sm backdrop-blur transition hover:bg-white/80">
  ← Volver
</a>'''


def ensure_in_head(html: str, snippet: str, exists_pattern: str) -> tuple[str, bool]:
    if re.search(exists_pattern, html, flags=re.IGNORECASE):
        return html, False

    closing_head = re.search(r'</head\s*>', html, flags=re.IGNORECASE)
    if not closing_head:
        return html, False

    insert_at = closing_head.start()
    updated = html[:insert_at] + snippet + '\n' + html[insert_at:]
    return updated, True


def replace_body_tag(html: str) -> tuple[str, bool]:
    match = re.search(r'<body\b[^>]*>', html, flags=re.IGNORECASE)
    if not match:
        return html, False

    current_tag = match.group(0)
    if current_tag == BODY_CLASS_TAG:
        return html, False

    updated = html[:match.start()] + BODY_CLASS_TAG + html[match.end():]
    return updated, True


def ensure_back_button(html: str) -> tuple[str, bool]:
    if re.search(r'id=["\']ivyco-back-button["\']', html, flags=re.IGNORECASE):
        return html, False

    body_open = re.search(r'<body\b[^>]*>', html, flags=re.IGNORECASE)
    if not body_open:
        return html, False

    insert_at = body_open.end()
    updated = html[:insert_at] + '\n' + BACK_BUTTON + '\n' + html[insert_at:]
    return updated, True


def process_file(file_path: str) -> bool:
    with open(file_path, 'r', encoding='utf-8') as file:
        html = file.read()

    original = html

    html, _ = ensure_in_head(
        html,
        VIEWPORT_META,
        r'<meta[^>]*name=["\']viewport["\'][^>]*>'
    )
    html, _ = ensure_in_head(
        html,
        TAILWIND_CDN,
        r'<script[^>]*src=["\']https://cdn\.tailwindcss\.com["\'][^>]*></script>'
    )
    html, _ = ensure_in_head(
        html,
        GOOGLE_FONTS,
        r'<link[^>]*href=["\']https://fonts\.googleapis\.com/css2\?family=Inter:wght@300;400&family=Playfair\+Display:ital,wght@0,600;1,600&display=swap["\'][^>]*>'
    )
    html, _ = ensure_in_head(
        html,
        TAILWIND_CONFIG,
        r'<script[^>]*id=["\']ivyco-tailwind-config["\'][^>]*>'
    )

    html, _ = replace_body_tag(html)
    html, _ = ensure_back_button(html)

    if html == original:
        return False

    with open(file_path, 'w', encoding='utf-8', newline='') as file:
        file.write(html)

    return True


def main() -> None:
    root_dir = os.path.dirname(os.path.abspath(__file__))

    visited = 0
    updated = 0

    for current_dir, _, files in os.walk(root_dir):
        if os.path.abspath(current_dir) == root_dir:
            continue

        for file_name in files:
            if file_name.lower() != 'index.html':
                continue

            visited += 1
            path = os.path.join(current_dir, file_name)
            if process_file(path):
                updated += 1
                print(f'[UPDATED] {path}')
            else:
                print(f'[SKIPPED] {path}')

    print(f'\nProcesados: {visited} | Actualizados: {updated} | Sin cambios: {visited - updated}')


if __name__ == '__main__':
    main()

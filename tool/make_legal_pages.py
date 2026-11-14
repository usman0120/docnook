"""Writes the privacy policy and terms as standalone HTML for the web.

The in-app pages (S31) and these web copies come from the same ARB strings
and lib/app/version.dart, so they never drift apart. Run after changing
either:
    python tool/make_legal_pages.py
Output: docs/release/privacy_policy.html and docs/release/terms.html.
Paste each page's text into a Google Sites page (BLUEPRINT 12.4).
"""
import html
import json
import os
import re
import sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
arb = json.load(open(os.path.join(root, 'lib/app/l10n/app_en.arb'), encoding='utf-8'))
version = open(os.path.join(root, 'lib/app/version.dart'), encoding='utf-8').read()


def const(name):
    return re.search(rf"const {name} = '([^']*)';", version).group(1)


publisher = const('publisherName')
email = const('supportEmail') or arb['legalContactPlaceholder']
updated = const('legalUpdated')
fill = {'publisher': publisher, 'email': email, 'date': updated}


def text(key):
    value = arb[key]
    for k, v in fill.items():
        value = value.replace('{' + k + '}', v)
    return value


def page(title, prefix, count, filename):
    parts = [
        '<!doctype html>',
        '<html lang="en"><head><meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width, initial-scale=1">',
        f'<title>DocNook – {html.escape(title)}</title>',
        '<style>body{font:16px/1.6 system-ui,sans-serif;max-width:680px;'
        'margin:2rem auto;padding:0 16px;color:#1b1b1b;background:#fff}'
        'h1{font-size:1.6rem}h2{font-size:1.15rem;margin-top:1.6rem}'
        '.muted{color:#5f5f5f}</style></head><body>',
        f'<h1>DocNook – {html.escape(title)}</h1>',
        f'<p class="muted">{html.escape(text("legalUpdated"))}</p>',
    ]
    for i in range(1, count + 1):
        parts.append(f'<h2>{html.escape(text(f"{prefix}H{i}"))}</h2>')
        parts.append(f'<p>{html.escape(text(f"{prefix}B{i}"))}</p>')
    parts.append('</body></html>\n')
    out = os.path.join(root, 'docs/release', filename)
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(parts))
    print('wrote', os.path.relpath(out, root))


def count(prefix):
    n = 0
    while f'{prefix}H{n + 1}' in arb:
        n += 1
    return n


page(arb['settingsPrivacyPolicy'], 'privacy', count('privacy'), 'privacy_policy.html')
page(arb['settingsTerms'], 'terms', count('terms'), 'terms.html')
if publisher.startswith('[') or not const('supportEmail'):
    print('note: publisher name or support email is still a placeholder', file=sys.stderr)
